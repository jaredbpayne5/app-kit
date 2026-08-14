import { APP_CONFIG } from '@/lib/app-config';
import { reportError } from '@/lib/report-error';
import * as SQLite from 'expo-sqlite';
import KvStore from 'expo-sqlite/kv-store';

/**
 * On-device storage seam.
 *
 * - `STORAGE: 'kv'` (default) — AsyncStorage-shaped helpers via `expo-sqlite/kv-store`
 *   (Expo Go OK).
 * - `STORAGE: 'sql'` — same KV helpers, plus a SQL client + versioned migrations for
 *   relational data. Screens never receive a raw DB handle; use `withSql`.
 */

// --- Key/value (always available; primary path when STORAGE is 'kv') -------------

export async function getJSON<T>(key: string): Promise<T | null> {
  const raw = await KvStore.getItem(key);
  if (raw == null) return null;
  try {
    return JSON.parse(raw) as T;
  } catch (error) {
    // Corrupt value would otherwise throw on every read and can wedge a screen.
    // Report, quarantine the bad key so it self-heals, and treat as absent.
    reportError(error, { scope: 'storage.getJSON', key });
    await KvStore.removeItem(key);
    return null;
  }
}

export async function setJSON<T>(key: string, value: T): Promise<void> {
  await KvStore.setItem(key, JSON.stringify(value));
}

export async function remove(key: string): Promise<void> {
  await KvStore.removeItem(key);
}

// --- SQL (STORAGE: 'sql') -------------------------------------------------------

const APP_DB_NAME = 'app.db';

/** Versioned migrations — bump `version` and append; never edit applied versions. */
export type SqlMigration = {
  version: number;
  /** Raw SQL batch for this version (no user input). */
  sql: string;
};

/**
 * Built-in starter migration (version 1).
 *
 * Product apps **append** via `registerMigrations` starting at version 2, or
 * pass `{ replaceBuiltins: true }` to drop this demo table and own version 1.
 *
 * Registering your own version 1 without `replaceBuiltins` is an error rather
 * than a silent no-op: `PRAGMA user_version` would already be 1 after the
 * builtin ran, so your migration would be skipped, your tables would never be
 * created, and every query would fail at runtime with nothing pointing at the
 * cause.
 */
const BUILTIN_MIGRATIONS: SqlMigration[] = [
  {
    version: 1,
    sql: `
      CREATE TABLE IF NOT EXISTS records (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      );
    `,
  },
];

let extraMigrations: SqlMigration[] = [];
let useBuiltinMigrations = true;
let dbPromise: Promise<SQLite.SQLiteDatabase> | null = null;

export type RegisterMigrationsOptions = {
  /** Drop the builtin starter migration so this product owns version 1. */
  replaceBuiltins?: boolean;
};

/**
 * Register product migrations. Additive — call it more than once and the sets
 * merge, rather than the last call silently discarding earlier ones.
 *
 * Must be called before the first `withSql`.
 */
export function registerMigrations(
  migrations: SqlMigration[],
  options: RegisterMigrationsOptions = {}
): void {
  if (dbPromise) {
    throw new Error(
      'registerMigrations must be called before the first withSql() — the database is already open ' +
        'and its migrations have run. Move this call to module init.'
    );
  }
  if (options.replaceBuiltins) useBuiltinMigrations = false;
  const merged = [...extraMigrations, ...migrations];
  assertUniqueVersions(useBuiltinMigrations ? [...BUILTIN_MIGRATIONS, ...merged] : merged);
  extraMigrations = merged;
}

/** Reset cached DB handle and registrations (tests only). */
export async function __resetSqlCacheForTests(): Promise<void> {
  const pending = dbPromise;
  dbPromise = null;
  extraMigrations = [];
  useBuiltinMigrations = true;
  if (!pending) return;
  // Close the handle rather than orphaning it — an open SQLite connection
  // survives the cleared promise and leaks across tests.
  try {
    const db = await pending;
    await db.closeAsync();
  } catch {
    // Handle already closed or never opened — nothing to release.
  }
}

function assertUniqueVersions(migrations: SqlMigration[]): void {
  const seen = new Set<number>();
  for (const migration of migrations) {
    if (seen.has(migration.version)) {
      throw new Error(
        `Duplicate SQL migration version ${migration.version}. Versions must be unique — ` +
          'append starting at version 2, or call registerMigrations(..., { replaceBuiltins: true }) ' +
          'to own version 1. A duplicate would be skipped and its tables never created.'
      );
    }
    seen.add(migration.version);
  }
}

function allMigrations(): SqlMigration[] {
  const base = useBuiltinMigrations ? BUILTIN_MIGRATIONS : [];
  const merged = [...base, ...extraMigrations];
  assertUniqueVersions(merged);
  return merged.sort((a, b) => a.version - b.version);
}

async function runMigrations(db: SQLite.SQLiteDatabase): Promise<void> {
  const row = await db.getFirstAsync<{ user_version: number }>('PRAGMA user_version');
  let current = row?.user_version ?? 0;
  const migrations = allMigrations();
  const target = migrations.reduce((max, m) => Math.max(max, m.version), 0);
  if (current >= target) return;

  for (const migration of migrations) {
    if (migration.version <= current) continue;
    // One transaction per migration: applying the SQL and recording the new
    // user_version must be atomic, or a crash between them re-runs the
    // migration on next launch. That is only survivable when every statement
    // is idempotent — an ALTER TABLE or UPDATE would corrupt or hard-fail.
    await db.withTransactionAsync(async () => {
      await db.execAsync(migration.sql);
      await db.execAsync(`PRAGMA user_version = ${migration.version}`);
    });
    current = migration.version;
  }
}

/**
 * Open + configure one connection.
 *
 * `openDatabaseAsync` stays outside the try: if it fails there is no handle to
 * release. Everything after it is guarded, because once it resolves the native
 * connection is live even when WAL or the migrations then throw. Orphaning that
 * handle leaks it for the app's lifetime, and its WAL lock can make the retry
 * fail with SQLITE_BUSY — turning a transient error into a permanent one. Same
 * reason `__resetSqlCacheForTests` closes rather than drops.
 */
async function setUpAppDatabase(): Promise<SQLite.SQLiteDatabase> {
  const db = await SQLite.openDatabaseAsync(APP_DB_NAME);
  try {
    // Connection-level PRAGMAs (journal_mode, foreign_keys) cannot run inside a
    // transaction — SQLite errors or silently no-ops. Never put them in migration
    // SQL; migrations run inside withTransactionAsync.
    await db.execAsync('PRAGMA journal_mode = WAL;');
    await runMigrations(db);
    return db;
  } catch (error) {
    try {
      await db.closeAsync();
    } catch {
      // Close failure must not mask the original setup error.
    }
    throw error;
  }
}

async function openAppDatabase(): Promise<SQLite.SQLiteDatabase> {
  if (APP_CONFIG.STORAGE !== 'sql') {
    throw new Error('openAppDatabase requires APP_CONFIG.STORAGE === "sql"');
  }
  if (!dbPromise) {
    // Un-cache on failure. A rejected promise is truthy, so caching one made the
    // guard above see a "live" handle forever: every later withSql replayed the
    // same error with no way back short of a reinstall. One transient open — or
    // one bad migration — wedged all SQL storage.
    //
    // Migrations retry too, deliberately. Each runs in its own transaction (see
    // runMigrations), so a rejection rolls back to the last applied version and
    // re-running from there is safe. Classifying failures as transient vs
    // permanent would just re-create the wedge for a disk-full migration. Retries
    // are caller-driven — one attempt per withSql, never a self-driven loop.
    const pending: Promise<SQLite.SQLiteDatabase> = setUpAppDatabase().catch((error) => {
      // Not a tautology, and not safe to simplify away: a reset + reopen can race
      // ahead of a slow failure, so `pending` may no longer be the cached attempt.
      // Clearing unconditionally would orphan that newer, healthy handle.
      if (dbPromise === pending) dbPromise = null;
      throw error;
    });
    dbPromise = pending;
  }
  return dbPromise;
}

/** Bound SQL ops — no raw `SQLiteDatabase` leaves this module. */
export type SqlClient = {
  exec: (sql: string) => Promise<void>;
  run: (sql: string, ...params: SQLite.SQLiteBindValue[]) => Promise<SQLite.SQLiteRunResult>;
  getFirst: <T>(sql: string, ...params: SQLite.SQLiteBindValue[]) => Promise<T | null>;
  getAll: <T>(sql: string, ...params: SQLite.SQLiteBindValue[]) => Promise<T[]>;
};

function toClient(db: SQLite.SQLiteDatabase): SqlClient {
  return {
    exec: (sql) => db.execAsync(sql),
    run: (sql, ...params) => db.runAsync(sql, ...params),
    getFirst: <T>(sql: string, ...params: SQLite.SQLiteBindValue[]) =>
      db.getFirstAsync<T>(sql, ...params),
    getAll: <T>(sql: string, ...params: SQLite.SQLiteBindValue[]) =>
      db.getAllAsync<T>(sql, ...params),
  };
}

/**
 * Run work against the app SQL database (migrations applied first).
 * Only when `APP_CONFIG.STORAGE === 'sql'`.
 */
export async function withSql<T>(fn: (sql: SqlClient) => Promise<T>): Promise<T> {
  const db = await openAppDatabase();
  return fn(toClient(db));
}
