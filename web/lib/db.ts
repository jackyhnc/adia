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
      machine_count  INTEGER NOT NULL DEFAULT 0
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
  `);
  return _db;
}

export type License = {
  key: string;
  email: string;
  plan: 'monthly' | 'yearly' | 'lifetime';
  status: 'active' | 'canceled' | 'expired' | 'past_due';
  issuedAt: string;
  expiresAt: string | null;
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
    .prepare('SELECT * FROM licenses WHERE email = ? ORDER BY issued_at ASC, rowid ASC')
    .all(email.trim().toLowerCase()) as any[];
  return rows.map(r => ({
    key: r.key,
    email: r.email,
    plan: r.plan,
    status: r.status,
    issuedAt: r.issued_at,
    expiresAt: r.expires_at,
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
