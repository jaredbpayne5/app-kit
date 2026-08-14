/**
 * Unit tests for the storage seam.
 *
 * Native expo-sqlite is mocked: kv-store as an in-memory map; openDatabaseAsync
 * as a tiny SQL subset (PRAGMA user_version, CREATE, INSERT, SELECT) so
 * migration + row round-trip can be asserted without a device.
 */
/* eslint-disable import/first -- mocks must run before the storage import */

type Store = Record<string, string>;

const mockKvStore: Store = {};

jest.mock('expo-sqlite/kv-store', () => ({
  __esModule: true,
  default: {
    getItem: jest.fn(async (key: string) => mockKvStore[key] ?? null),
    setItem: jest.fn(async (key: string, value: string) => {
      mockKvStore[key] = value;
    }),
    removeItem: jest.fn(async (key: string) => {
      delete mockKvStore[key];
    }),
  },
}));

type FakeRow = { id: number; payload: string; created_at: string };

function createMockSqlite(options: { failSqlOnce?: RegExp } = {}) {
  let failSqlOnce = options.failSqlOnce;
  let userVersion = 0;
  let nextId = 1;
  let closed = false;
  let txDepth = 0;
  const execOutsideTx: string[] = [];
  const execInsideTx: string[] = [];
  const records: FakeRow[] = [];

  const db = {
    withTransactionAsync: jest.fn(async (fn: () => Promise<void>) => {
      txDepth += 1;
      try {
        await fn();
      } finally {
        txDepth -= 1;
      }
    }),
    closeAsync: jest.fn(async () => {
      closed = true;
    }),
    execAsync: jest.fn(async (sql: string) => {
      const trimmed = sql.trim();
      if (failSqlOnce?.test(trimmed)) {
        failSqlOnce = undefined;
        throw new Error(`simulated SQL failure: ${trimmed}`);
      }
      // Mirror SQLite: journal_mode cannot change inside a transaction.
      if (txDepth > 0 && /PRAGMA\s+journal_mode/i.test(trimmed)) {
        throw new Error('cannot change into wal mode from within a transaction');
      }
      if (txDepth === 0) execOutsideTx.push(trimmed);
      else execInsideTx.push(trimmed);
      const versionMatch = /^PRAGMA user_version\s*=\s*(\d+)\s*;?\s*$/i.exec(trimmed);
      if (versionMatch) {
        userVersion = Number(versionMatch[1]);
        return;
      }
      // Schema DDL and connection-level PRAGMAs (outside tx) — accepted.
      void sql;
    }),
    runAsync: jest.fn(async (sql: string, ...params: unknown[]) => {
      if (/INSERT INTO records\s*\(\s*payload\s*\)/i.test(sql)) {
        const payload = String(params[0]);
        const row: FakeRow = {
          id: nextId++,
          payload,
          created_at: new Date().toISOString(),
        };
        records.push(row);
        return { lastInsertRowId: row.id, changes: 1 };
      }
      return { lastInsertRowId: 0, changes: 0 };
    }),
    getFirstAsync: jest.fn(async (sql: string, ...params: unknown[]) => {
      if (/PRAGMA user_version/i.test(sql.trim())) {
        return { user_version: userVersion };
      }
      if (/SELECT .* FROM records WHERE id\s*=\s*\?/i.test(sql)) {
        const id = Number(params[0]);
        return records.find((r) => r.id === id) ?? null;
      }
      return null;
    }),
    getAllAsync: jest.fn(async (sql: string) => {
      if (/SELECT .* FROM records/i.test(sql)) {
        return [...records];
      }
      return [];
    }),
  };

  return {
    openDatabaseAsync: jest.fn(async (_name?: string) => db),
    getUserVersion: () => userVersion,
    getRecords: () => records,
    isClosed: () => closed,
    getExecOutsideTx: () => [...execOutsideTx],
    getExecInsideTx: () => [...execInsideTx],
  };
}

const mockSqlite = createMockSqlite();

jest.mock('expo-sqlite', () => ({
  __esModule: true,
  openDatabaseAsync: (name: string) => mockSqlite.openDatabaseAsync(name),
}));

jest.mock('@/lib/app-config', () => ({
  APP_CONFIG: {
    STORAGE: 'kv' as 'kv' | 'sql',
    MONETIZATION: 'free',
  },
}));

const mockReportError = jest.fn();
jest.mock('@/lib/report-error', () => ({
  reportError: (...args: unknown[]) => mockReportError(...args),
}));

import { APP_CONFIG } from '@/lib/app-config';
import {
  __resetSqlCacheForTests,
  getJSON,
  registerMigrations,
  remove,
  setJSON,
  withSql,
} from '@/lib/storage';

describe('lib/storage (kv)', () => {
  beforeEach(async () => {
    (APP_CONFIG as { STORAGE: 'kv' | 'sql' }).STORAGE = 'kv';
    for (const key of Object.keys(mockKvStore)) delete mockKvStore[key];
    mockReportError.mockClear();
    await remove('test-key');
  });

  it('round-trips JSON values', async () => {
    await setJSON('test-key', { hello: 'world', n: 1 });
    await expect(getJSON<{ hello: string; n: number }>('test-key')).resolves.toEqual({
      hello: 'world',
      n: 1,
    });
  });

  it('returns null for missing keys', async () => {
    await expect(getJSON('missing')).resolves.toBeNull();
  });

  it('removes keys', async () => {
    await setJSON('test-key', true);
    await remove('test-key');
    await expect(getJSON('test-key')).resolves.toBeNull();
  });

  it('quarantines a corrupt value: returns null, removes the key, reports once', async () => {
    mockKvStore['test-key'] = '{not valid json';

    await expect(getJSON('test-key')).resolves.toBeNull();
    expect(mockReportError).toHaveBeenCalledTimes(1);
    expect(mockReportError).toHaveBeenCalledWith(
      expect.any(Error),
      expect.objectContaining({ scope: 'storage.getJSON', key: 'test-key' })
    );
    // Key was removed, so a second read is a clean miss (no repeat report).
    await expect(getJSON('test-key')).resolves.toBeNull();
    expect(mockReportError).toHaveBeenCalledTimes(1);
  });
});

describe('lib/storage (sql)', () => {
  beforeEach(async () => {
    (APP_CONFIG as { STORAGE: 'kv' | 'sql' }).STORAGE = 'sql';
    await __resetSqlCacheForTests();
    const fresh = createMockSqlite();
    mockSqlite.openDatabaseAsync.mockReset();
    mockSqlite.openDatabaseAsync.mockImplementation(fresh.openDatabaseAsync);
    // Expose fresh state accessors on the shared mock for assertions.
    (mockSqlite as { getUserVersion: () => number }).getUserVersion = fresh.getUserVersion;
    (mockSqlite as { getRecords: () => FakeRow[] }).getRecords = fresh.getRecords;
    (mockSqlite as { isClosed: () => boolean }).isClosed = fresh.isClosed;
    (mockSqlite as { getExecOutsideTx: () => string[] }).getExecOutsideTx = fresh.getExecOutsideTx;
    (mockSqlite as { getExecInsideTx: () => string[] }).getExecInsideTx = fresh.getExecInsideTx;
  });

  it('applies migration and round-trips a row', async () => {
    const inserted = await withSql(async (sql) => {
      const result = await sql.run('INSERT INTO records (payload) VALUES (?)', '{"x":1}');
      return sql.getFirst<{ id: number; payload: string; created_at: string }>(
        'SELECT id, payload, created_at FROM records WHERE id = ?',
        result.lastInsertRowId
      );
    });

    expect(mockSqlite.getUserVersion()).toBe(1);
    expect(inserted).toEqual({
      id: 1,
      payload: '{"x":1}',
      created_at: expect.any(String),
    });
  });

  it('returns all rows via getAll', async () => {
    const rows = await withSql(async (sql) => {
      await sql.run('INSERT INTO records (payload) VALUES (?)', '{"a":1}');
      await sql.run('INSERT INTO records (payload) VALUES (?)', '{"b":2}');
      return sql.getAll<FakeRow>('SELECT id, payload, created_at FROM records');
    });

    expect(rows).toHaveLength(2);
    expect(rows.map((r) => r.payload)).toEqual(['{"a":1}', '{"b":2}']);
  });

  it('opens the database once and reuses the cached handle', async () => {
    await withSql(async (sql) => sql.run('INSERT INTO records (payload) VALUES (?)', '{"n":1}'));
    await withSql(async (sql) => sql.getAll('SELECT id FROM records'));

    expect(mockSqlite.openDatabaseAsync).toHaveBeenCalledTimes(1);
  });

  it('applies a newly registered migration and bumps user_version', async () => {
    // Built-in migration is v1; register a v2 before the first withSql call.
    registerMigrations([
      {
        version: 2,
        sql: `ALTER TABLE records ADD COLUMN archived INTEGER NOT NULL DEFAULT 0;`,
      },
    ]);

    await withSql(async (sql) => sql.run('INSERT INTO records (payload) VALUES (?)', '{"x":1}'));

    expect(mockSqlite.getUserVersion()).toBe(2);
  });

  it('rejects withSql when STORAGE is kv', async () => {
    (APP_CONFIG as { STORAGE: 'kv' | 'sql' }).STORAGE = 'kv';
    await __resetSqlCacheForTests();
    await expect(withSql(async () => null)).rejects.toThrow(/STORAGE === "sql"/);
  });

  // --- Migration footguns -------------------------------------------------
  //
  // A product that follows the in-file guidance and registers its own schema
  // as version 1 used to collide silently with the builtin: user_version was
  // already 1, so the product migration was skipped, its tables were never
  // created, and every query failed at runtime with nothing naming the cause.

  it('throws when a registered migration collides with the builtin version', () => {
    expect(() =>
      registerMigrations([{ version: 1, sql: 'CREATE TABLE items (id INTEGER PRIMARY KEY);' }])
    ).toThrow(/Duplicate SQL migration version 1/);
  });

  it('throws when two registered migrations share a version', () => {
    expect(() =>
      registerMigrations([
        { version: 2, sql: 'CREATE TABLE a (id INTEGER PRIMARY KEY);' },
        { version: 2, sql: 'CREATE TABLE b (id INTEGER PRIMARY KEY);' },
      ])
    ).toThrow(/Duplicate SQL migration version 2/);
  });

  it('lets a product own version 1 via replaceBuiltins', async () => {
    registerMigrations([{ version: 1, sql: 'CREATE TABLE items (id INTEGER PRIMARY KEY);' }], {
      replaceBuiltins: true,
    });

    await withSql(async (sql) => sql.getAll('SELECT id FROM items'));

    expect(mockSqlite.getUserVersion()).toBe(1);
  });

  it('merges successive registrations instead of replacing them', async () => {
    registerMigrations([{ version: 2, sql: 'ALTER TABLE records ADD COLUMN a INTEGER;' }]);
    registerMigrations([{ version: 3, sql: 'ALTER TABLE records ADD COLUMN b INTEGER;' }]);

    await withSql(async (sql) => sql.getAll('SELECT id FROM records'));

    // If the second call had replaced the first, target would be 3 but v2 would
    // never have run. Reaching 3 through a sequential runner proves both applied.
    expect(mockSqlite.getUserVersion()).toBe(3);
  });

  it('throws when registering after the database is already open', async () => {
    await withSql(async (sql) => sql.getAll('SELECT id FROM records'));

    expect(() =>
      registerMigrations([{ version: 2, sql: 'ALTER TABLE records ADD COLUMN c;' }])
    ).toThrow(/must be called before the first withSql/);
  });

  it('runs each migration inside a transaction', async () => {
    registerMigrations([{ version: 2, sql: 'ALTER TABLE records ADD COLUMN archived INTEGER;' }]);

    await withSql(async (sql) => sql.getAll('SELECT id FROM records'));

    // Migration DDL + user_version bump must be atomic (inside a transaction).
    // Connection-level PRAGMAs are the only execs allowed outside one.
    const inside = mockSqlite.getExecInsideTx();
    expect(inside.some((sql) => /CREATE TABLE IF NOT EXISTS records/i.test(sql))).toBe(true);
    expect(inside.some((sql) => /ALTER TABLE records ADD COLUMN archived/i.test(sql))).toBe(true);
    expect(inside.filter((sql) => /^PRAGMA user_version\s*=\s*\d+/i.test(sql))).toEqual([
      'PRAGMA user_version = 1',
      'PRAGMA user_version = 2',
    ]);
    const outside = mockSqlite.getExecOutsideTx();
    expect(outside.every((sql) => /PRAGMA\s+journal_mode/i.test(sql))).toBe(true);
    expect(outside.some((sql) => /CREATE TABLE|ALTER TABLE|PRAGMA user_version/i.test(sql))).toBe(
      false
    );
  });

  it('sets WAL once on open, outside any transaction', async () => {
    await withSql(async (sql) => sql.getAll('SELECT id FROM records'));

    const outside = mockSqlite.getExecOutsideTx();
    const wal = outside.filter((sql) => /PRAGMA\s+journal_mode\s*=\s*WAL/i.test(sql));
    expect(wal).toHaveLength(1);
    expect(mockSqlite.getExecInsideTx().some((sql) => /PRAGMA\s+journal_mode/i.test(sql))).toBe(
      false
    );
  });

  it('closes the open handle when the cache is reset', async () => {
    await withSql(async (sql) => sql.getAll('SELECT id FROM records'));
    expect(mockSqlite.isClosed()).toBe(false);

    await __resetSqlCacheForTests();

    expect(mockSqlite.isClosed()).toBe(true);
  });

  it('does not memoize a transient open failure', async () => {
    const failing = createMockSqlite();
    failing.openDatabaseAsync.mockRejectedValueOnce(new Error('transient open failure'));
    const succeeding = createMockSqlite();

    mockSqlite.openDatabaseAsync.mockReset();
    mockSqlite.openDatabaseAsync
      .mockImplementationOnce(failing.openDatabaseAsync)
      .mockImplementationOnce(succeeding.openDatabaseAsync);

    await expect(withSql(async (sql) => sql.getAll('SELECT id FROM records'))).rejects.toThrow(
      /transient open failure/
    );
    await expect(withSql(async (sql) => sql.getAll('SELECT id FROM records'))).resolves.toEqual([]);

    expect(mockSqlite.openDatabaseAsync).toHaveBeenCalledTimes(2);
  });

  it('closes the half-open handle after a migration failure and retries clean', async () => {
    const failing = createMockSqlite({
      failSqlOnce: /ALTER TABLE records ADD COLUMN archived/,
    });
    const succeeding = createMockSqlite();

    mockSqlite.openDatabaseAsync.mockReset();
    mockSqlite.openDatabaseAsync
      .mockImplementationOnce(failing.openDatabaseAsync)
      .mockImplementationOnce(succeeding.openDatabaseAsync);

    registerMigrations([
      {
        version: 2,
        sql: 'ALTER TABLE records ADD COLUMN archived INTEGER NOT NULL DEFAULT 0;',
      },
    ]);

    await expect(withSql(async (sql) => sql.getAll('SELECT id FROM records'))).rejects.toThrow(
      /simulated SQL failure/
    );
    expect(failing.isClosed()).toBe(true);
    expect(failing.getUserVersion()).toBe(1);

    await expect(withSql(async (sql) => sql.getAll('SELECT id FROM records'))).resolves.toEqual([]);
    expect(succeeding.getUserVersion()).toBe(2);
    expect(succeeding.isClosed()).toBe(false);
  });

  it('shares one failed open among concurrent callers', async () => {
    const failing = createMockSqlite();
    failing.openDatabaseAsync.mockRejectedValueOnce(new Error('shared open failure'));

    mockSqlite.openDatabaseAsync.mockReset();
    mockSqlite.openDatabaseAsync.mockImplementationOnce(failing.openDatabaseAsync);

    const first = withSql(async (sql) => sql.getAll('SELECT id FROM records'));
    const second = withSql(async (sql) => sql.getAll('SELECT id FROM records'));

    await expect(first).rejects.toThrow(/shared open failure/);
    await expect(second).rejects.toThrow(/shared open failure/);
    expect(mockSqlite.openDatabaseAsync).toHaveBeenCalledTimes(1);
  });
});
