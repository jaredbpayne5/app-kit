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

const APP_DB_NAME = 'tiny-app.db';

/** Versioned migrations — bump `version` and append; never edit applied versions. */
export type SqlMigration = {
  version: number;
  /** Raw SQL batch for this version (no user input). */
  sql: string;
};

/**
 * Built-in starter migrations. Product apps append via `registerMigrations`
 * before the first `withSql` call, or replace this list when you design your schema.
 */
const BUILTIN_MIGRATIONS: SqlMigration[] = [
  {
    version: 1,
    sql: `
      PRAGMA journal_mode = WAL;
      CREATE TABLE IF NOT EXISTS records (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      );
    `,
  },
];

let extraMigrations: SqlMigration[] = [];
let dbPromise: Promise<SQLite.SQLiteDatabase> | null = null;

/** Register additional migrations (must be called before first `withSql`). */
export function registerMigrations(migrations: SqlMigration[]): void {
  extraMigrations = migrations;
  dbPromise = null;
}

/** Reset cached DB handle (tests only). */
export function __resetSqlCacheForTests(): void {
  dbPromise = null;
  extraMigrations = [];
}

function allMigrations(): SqlMigration[] {
  return [...BUILTIN_MIGRATIONS, ...extraMigrations].sort((a, b) => a.version - b.version);
}

async function runMigrations(db: SQLite.SQLiteDatabase): Promise<void> {
  const row = await db.getFirstAsync<{ user_version: number }>('PRAGMA user_version');
  let current = row?.user_version ?? 0;
  const migrations = allMigrations();
  const target = migrations.reduce((max, m) => Math.max(max, m.version), 0);
  if (current >= target) return;

  for (const migration of migrations) {
    if (migration.version <= current) continue;
    await db.execAsync(migration.sql);
    await db.execAsync(`PRAGMA user_version = ${migration.version}`);
    current = migration.version;
  }
}

async function openAppDatabase(): Promise<SQLite.SQLiteDatabase> {
  if (APP_CONFIG.STORAGE !== 'sql') {
    throw new Error('openAppDatabase requires APP_CONFIG.STORAGE === "sql"');
  }
  if (!dbPromise) {
    dbPromise = (async () => {
      const db = await SQLite.openDatabaseAsync(APP_DB_NAME);
      await runMigrations(db);
      return db;
    })();
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
