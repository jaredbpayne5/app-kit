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

function createMockSqlite() {
  let userVersion = 0;
  let nextId = 1;
  const records: FakeRow[] = [];

  const db = {
    execAsync: jest.fn(async (sql: string) => {
      const trimmed = sql.trim();
      const versionMatch = /^PRAGMA user_version\s*=\s*(\d+)\s*;?\s*$/i.exec(trimmed);
      if (versionMatch) {
        userVersion = Number(versionMatch[1]);
        return;
      }
      // Multi-statement migration batches (CREATE / journal_mode) — accepted.
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
  beforeEach(() => {
    (APP_CONFIG as { STORAGE: 'kv' | 'sql' }).STORAGE = 'sql';
    __resetSqlCacheForTests();
    const fresh = createMockSqlite();
    mockSqlite.openDatabaseAsync.mockReset();
    mockSqlite.openDatabaseAsync.mockImplementation(fresh.openDatabaseAsync);
    // Expose fresh state accessors on the shared mock for assertions.
    (mockSqlite as { getUserVersion: () => number }).getUserVersion = fresh.getUserVersion;
    (mockSqlite as { getRecords: () => FakeRow[] }).getRecords = fresh.getRecords;
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
    __resetSqlCacheForTests();
    await expect(withSql(async () => null)).rejects.toThrow(/STORAGE === "sql"/);
  });
});
