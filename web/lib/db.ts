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
function db(): Database.Database {
  if (_db) return _db;
  _db = new Database(dbPath);
  _db.pragma('journal_mode = WAL');
  _db.exec(`
    CREATE TABLE IF NOT EXISTS licenses (
      key            TEXT PRIMARY KEY,
      email          TEXT NOT NULL,
      plan           TEXT NOT NULL,
      stripe_session TEXT,
      stripe_sub     TEXT,
      status         TEXT NOT NULL DEFAULT 'active',
      issued_at      TEXT NOT NULL,
      expires_at     TEXT,
      machine_count  INTEGER NOT NULL DEFAULT 0
    );
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
  status: 'active' | 'canceled' | 'expired';
  issuedAt: string;
  expiresAt: string | null;
};

export function insertLicense(row: {
  key: string;
  email: string;
  plan: License['plan'];
  stripeSession?: string;
  stripeSub?: string;
  expiresAt: string | null;
}) {
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
}

export function findLicense(key: string, email?: string): License | null {
  const row = email
    ? db().prepare('SELECT * FROM licenses WHERE key = ? AND email = ?')
        .get(key, email.toLowerCase())
    : db().prepare('SELECT * FROM licenses WHERE key = ?').get(key);
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

export function setStatus(key: string, status: License['status']) {
  db().prepare('UPDATE licenses SET status = ? WHERE key = ?').run(status, key);
}

export function joinWaitlist(email: string) {
  db().prepare(`
    INSERT INTO waitlist (email, created_at) VALUES (?, ?)
    ON CONFLICT(email) DO NOTHING
  `).run(email.toLowerCase(), new Date().toISOString());
}
