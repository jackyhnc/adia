// Tiny licensing store. Defaults to SQLite on local disk; if DATABASE_URL is a
// Postgres URL (e.g. on Vercel + Neon), swap by setting LICENSE_BACKEND=postgres
// and adding @vercel/postgres queries. For v1 SQLite is enough — Resend webhook
// volume is low.

import Database from 'better-sqlite3';
import path from 'node:path';
import fs from 'node:fs';

const dbPath = process.env.LICENSE_DB_PATH
  ?? path.join(process.cwd(), '.data', 'adia.db');
fs.mkdirSync(path.dirname(dbPath), { recursive: true });

let _db: Database.Database | null = null;
let _resolvedPath = dbPath;

export function resetDbForTesting(newPath?: string) {
  if (_db) { _db.close(); _db = null; }
  _resolvedPath = newPath ?? dbPath;
  if (newPath) fs.mkdirSync(path.dirname(newPath), { recursive: true });
}

function db(): Database.Database {
  if (_db) return _db;
  _db = new Database(_resolvedPath);
  _db.pragma('journal_mode = WAL');
  _db.exec(`
    CREATE TABLE IF NOT EXISTS licenses (
      key            TEXT PRIMARY KEY,
      email          TEXT NOT NULL,
      plan           TEXT NOT NULL,
      stripe_session TEXT UNIQUE,
      stripe_sub     TEXT,
      status         TEXT NOT NULL DEFAULT 'active',
      issued_at      TEXT NOT NULL,
      expires_at     TEXT,
      machine_count  INTEGER NOT NULL DEFAULT 0,
      note           TEXT
    );
    CREATE INDEX IF NOT EXISTS idx_licenses_email ON licenses(email);
    CREATE TABLE IF NOT EXISTS activations (
      license_key   TEXT NOT NULL,
      machine_hash  TEXT NOT NULL,
      first_seen    TEXT NOT NULL,
      last_seen     TEXT NOT NULL,
      PRIMARY KEY (license_key, machine_hash),
      FOREIGN KEY (license_key) REFERENCES licenses(key)
    );
    CREATE TABLE IF NOT EXISTS waitlist (
      email      TEXT PRIMARY KEY,
      created_at TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS audit_log (
      id           INTEGER PRIMARY KEY AUTOINCREMENT,
      license_key  TEXT,
      action       TEXT NOT NULL,
      detail       TEXT,
      created_at   TEXT NOT NULL
    );
    CREATE INDEX IF NOT EXISTS idx_audit_log_license_key ON audit_log(license_key);
  `);
  // Migration: add note column to existing DBs that predate this column.
  try { _db.exec('ALTER TABLE licenses ADD COLUMN note TEXT'); }
  catch (e: any) { if (!e.message?.includes('duplicate column name')) throw e; }
  return _db;
}

export type License = {
  key: string;
  email: string;
  plan: 'monthly' | 'yearly' | 'lifetime';
  status: 'active' | 'canceled' | 'expired' | 'past_due';
  issuedAt: string;
  expiresAt: string | null;
  note?: string | null;
  machineCount?: number;
  lastAction?: string | null;
  lastActionAt?: string | null;
};

export type AuditEntry = {
  id: number;
  licenseKey: string | null;
  action: string;
  detail: string | null;
  createdAt: string;
};

export type Activation = {
  machineHash: string;
  firstSeen: string;
  lastSeen: string;
};

/// Returns the license key written, or the EXISTING key when a row with the same
/// stripe_session already exists (idempotency: re-delivered webhooks must not
/// double-issue licenses).
export function insertLicense(row: {
  key: string;
  email: string;
  plan: License['plan'];
  stripeSession?: string;
  stripeSub?: string;
  expiresAt: string | null;
}): string {
  if (row.stripeSession) {
    const existing = db()
      .prepare('SELECT key FROM licenses WHERE stripe_session = ?')
      .get(row.stripeSession) as { key: string } | undefined;
    if (existing) return existing.key;
  }
  db().prepare(`
    INSERT INTO licenses (key, email, plan, stripe_session, stripe_sub, issued_at, expires_at)
    VALUES (?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(key) DO UPDATE SET email=excluded.email
  `).run(
    row.key,
    row.email.toLowerCase(),
    row.plan,
    row.stripeSession ?? null,
    row.stripeSub ?? null,
    new Date().toISOString(),
    row.expiresAt,
  );
  return row.key;
}

export function findLicense(key: string, email?: string): License | null {
  const cleanKey = key.trim().toUpperCase();
  const row = email
    ? db().prepare('SELECT * FROM licenses WHERE key = ? AND email = ?')
        .get(cleanKey, email.trim().toLowerCase())
    : db().prepare('SELECT * FROM licenses WHERE key = ?').get(cleanKey);
  if (!row) return null;
  const r = row as any;
  return {
    key: r.key,
    email: r.email,
    plan: r.plan,
    status: r.status,
    issuedAt: r.issued_at,
    expiresAt: r.expires_at,
    note: r.note ?? null,
  };
}

export function recordActivation(key: string, machineHash: string): number {
  const now = new Date().toISOString();
  db().prepare(`
    INSERT INTO activations (license_key, machine_hash, first_seen, last_seen)
    VALUES (?, ?, ?, ?)
    ON CONFLICT(license_key, machine_hash) DO UPDATE SET last_seen=excluded.last_seen
  `).run(key, machineHash, now, now);
  const row = db()
    .prepare('SELECT COUNT(*) as c FROM activations WHERE license_key = ?')
    .get(key) as { c: number };
  return row.c;
}

export function hasActivation(key: string, machineHash: string): boolean {
  const row = db()
    .prepare('SELECT 1 FROM activations WHERE license_key = ? AND machine_hash = ?')
    .get(key, machineHash);
  return !!row;
}

export function countActivations(key: string): number {
  const row = db()
    .prepare('SELECT COUNT(*) as c FROM activations WHERE license_key = ?')
    .get(key) as { c: number };
  return row.c;
}

export function findLicensesByEmail(email: string): License[] {
  const rows = db()
    .prepare(`
      SELECT l.*,
             COUNT(a.machine_hash) AS machine_count_live,
             (SELECT action FROM audit_log WHERE license_key = l.key ORDER BY id DESC LIMIT 1) AS last_action,
             (SELECT created_at FROM audit_log WHERE license_key = l.key ORDER BY id DESC LIMIT 1) AS last_action_at
      FROM licenses l
      LEFT JOIN activations a ON a.license_key = l.key
      WHERE l.email = ?
      GROUP BY l.key
      ORDER BY l.issued_at DESC, l.rowid DESC
    `)
    .all(email.trim().toLowerCase()) as any[];
  return rows.map(r => ({
    key: r.key,
    email: r.email,
    plan: r.plan,
    status: r.status,
    issuedAt: r.issued_at,
    expiresAt: r.expires_at,
    note: r.note ?? null,
    machineCount: r.machine_count_live as number,
    lastAction: r.last_action ?? null,
    lastActionAt: r.last_action_at ?? null,
  }));
}

export function setStatus(key: string, status: License['status']) {
  db().prepare('UPDATE licenses SET status = ? WHERE key = ?').run(status, key);
}

export function setPlan(key: string, plan: License['plan']) {
  db().prepare('UPDATE licenses SET plan = ? WHERE key = ?').run(plan, key);
}

export function findLicenseBySub(stripeSub: string): License | null {
  const row = db()
    .prepare('SELECT * FROM licenses WHERE stripe_sub = ?')
    .get(stripeSub) as any;
  if (!row) return null;
  return {
    key: row.key,
    email: row.email,
    plan: row.plan,
    status: row.status,
    issuedAt: row.issued_at,
    expiresAt: row.expires_at,
  };
}

export function setStatusBySub(stripeSub: string, status: License['status']) {
  db().prepare('UPDATE licenses SET status = ? WHERE stripe_sub = ?').run(status, stripeSub);
}

export function setExpiryBySub(stripeSub: string, expiresAt: string | null) {
  db().prepare('UPDATE licenses SET expires_at = ? WHERE stripe_sub = ?').run(expiresAt, stripeSub);
}

export function setExpiry(key: string, expiresAt: string | null) {
  db().prepare('UPDATE licenses SET expires_at = ? WHERE key = ?').run(expiresAt, key);
}

export function listActivations(key: string): Activation[] {
  const rows = db()
    .prepare(
      'SELECT machine_hash, first_seen, last_seen FROM activations WHERE license_key = ? ORDER BY last_seen DESC',
    )
    .all(key) as any[];
  return rows.map(r => ({
    machineHash: r.machine_hash,
    firstSeen: r.first_seen,
    lastSeen: r.last_seen,
  }));
}

export function removeActivation(key: string, machineHash: string): void {
  db()
    .prepare('DELETE FROM activations WHERE license_key = ? AND machine_hash = ?')
    .run(key, machineHash);
}

export function removeAllActivations(key: string): number {
  const result = db()
    .prepare('DELETE FROM activations WHERE license_key = ?')
    .run(key);
  return result.changes;
}

export function transferLicense(key: string, newEmail: string): void {
  db()
    .prepare('UPDATE licenses SET email = ? WHERE key = ?')
    .run(newEmail.toLowerCase().trim(), key);
}

export function joinWaitlist(email: string) {
  db().prepare(`
    INSERT INTO waitlist (email, created_at) VALUES (?, ?)
    ON CONFLICT(email) DO NOTHING
  `).run(email.toLowerCase(), new Date().toISOString());
}

export type LicenseStats = {
  total: number;
  byStatus: Record<string, number>;
  byPlan: Record<string, number>;
  newLast7Days: number;
  newLast30Days: number;
  activatedMachines: number;
};

export function setNote(key: string, note: string | null): void {
  db().prepare('UPDATE licenses SET note = ? WHERE key = ?').run(note, key.trim().toUpperCase());
}

export function getNote(key: string): string | null {
  const row = db()
    .prepare('SELECT note FROM licenses WHERE key = ?')
    .get(key.trim().toUpperCase()) as { note: string | null } | undefined;
  return row?.note ?? null;
}

export function insertAuditLog(entry: {
  licenseKey: string | null;
  action: string;
  detail?: Record<string, unknown>;
}): void {
  const now = new Date().toISOString();
  db().prepare(
    'INSERT INTO audit_log (license_key, action, detail, created_at) VALUES (?, ?, ?, ?)',
  ).run(
    entry.licenseKey,
    entry.action,
    entry.detail ? JSON.stringify(entry.detail) : null,
    now,
  );
}

export function listAuditLog(opts?: { licenseKey?: string; limit?: number }): AuditEntry[] {
  const limit = Math.min(opts?.limit ?? 100, 500);
  const rows = opts?.licenseKey
    ? db()
        .prepare('SELECT * FROM audit_log WHERE license_key = ? ORDER BY id DESC LIMIT ?')
        .all(opts.licenseKey.trim().toUpperCase(), limit)
    : db()
        .prepare('SELECT * FROM audit_log ORDER BY id DESC LIMIT ?')
        .all(limit);
  return (rows as any[]).map(r => ({
    id: r.id,
    licenseKey: r.license_key,
    action: r.action,
    detail: r.detail,
    createdAt: r.created_at,
  }));
}

export function searchLicenses(query: string, limit = 20, offset = 0): License[] {
  const q = `%${query.trim()}%`;
  const lq = `%${query.trim().toLowerCase()}%`;
  const rows = db()
    .prepare(`
      SELECT l.*, COUNT(a.machine_hash) AS machine_count_live
      FROM licenses l
      LEFT JOIN activations a ON a.license_key = l.key
      WHERE l.key LIKE ? OR l.email LIKE ? OR l.note LIKE ?
      GROUP BY l.key
      ORDER BY l.issued_at DESC
      LIMIT ? OFFSET ?
    `)
    .all(q.toUpperCase(), lq, q, Math.min(limit, 100), offset) as any[];
  return rows.map(r => ({
    key: r.key,
    email: r.email,
    plan: r.plan,
    status: r.status,
    issuedAt: r.issued_at,
    expiresAt: r.expires_at,
    note: r.note ?? null,
    machineCount: r.machine_count_live as number,
  }));
}

export function countSearchLicenses(query: string): number {
  const q = `%${query.trim()}%`;
  const lq = `%${query.trim().toLowerCase()}%`;
  const row = db()
    .prepare(`
      SELECT COUNT(DISTINCT l.key) AS total
      FROM licenses l
      WHERE l.key LIKE ? OR l.email LIKE ? OR l.note LIKE ?
    `)
    .get(q.toUpperCase(), lq, q) as { total: number };
  return row.total;
}

export function getStats(): LicenseStats {
  const now = new Date();
  const day7 = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString();
  const day30 = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString();

  const total = (db().prepare('SELECT COUNT(*) as c FROM licenses').get() as { c: number }).c;

  const statusRows = db()
    .prepare('SELECT status, COUNT(*) as c FROM licenses GROUP BY status')
    .all() as { status: string; c: number }[];
  const byStatus: Record<string, number> = {};
  for (const r of statusRows) byStatus[r.status] = r.c;

  const planRows = db()
    .prepare('SELECT plan, COUNT(*) as c FROM licenses GROUP BY plan')
    .all() as { plan: string; c: number }[];
  const byPlan: Record<string, number> = {};
  for (const r of planRows) byPlan[r.plan] = r.c;

  const newLast7Days = (
    db().prepare('SELECT COUNT(*) as c FROM licenses WHERE issued_at >= ?').get(day7) as { c: number }
  ).c;
  const newLast30Days = (
    db().prepare('SELECT COUNT(*) as c FROM licenses WHERE issued_at >= ?').get(day30) as { c: number }
  ).c;
  const activatedMachines = (
    db().prepare('SELECT COUNT(*) as c FROM activations').get() as { c: number }
  ).c;

  return { total, byStatus, byPlan, newLast7Days, newLast30Days, activatedMachines };
}
