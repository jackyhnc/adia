// Postgres adapter — mirror of lib/db.ts using @vercel/postgres.
// Selected at runtime by lib/store.ts when DATABASE_URL is set to a postgres:// URL.
//
// Schema is created on first call. On Vercel + Neon this happens at cold-start.
// Idempotent — IF NOT EXISTS everywhere.

import { sql } from '@vercel/postgres';
import type { License } from './db';

let _schemaReady = false;

async function ensureSchema(): Promise<void> {
  if (_schemaReady) return;
  await sql`
    CREATE TABLE IF NOT EXISTS licenses (
      key            TEXT PRIMARY KEY,
      email          TEXT NOT NULL,
      plan           TEXT NOT NULL,
      stripe_session TEXT UNIQUE,
      stripe_sub     TEXT,
      status         TEXT NOT NULL DEFAULT 'active',
      issued_at      TIMESTAMPTZ NOT NULL,
      expires_at     TIMESTAMPTZ,
      machine_count  INTEGER NOT NULL DEFAULT 0
    )
  `;
  await sql`CREATE INDEX IF NOT EXISTS idx_licenses_email ON licenses(email)`;
  await sql`
    CREATE TABLE IF NOT EXISTS activations (
      license_key   TEXT NOT NULL REFERENCES licenses(key),
      machine_hash  TEXT NOT NULL,
      first_seen    TIMESTAMPTZ NOT NULL,
      last_seen     TIMESTAMPTZ NOT NULL,
      PRIMARY KEY (license_key, machine_hash)
    )
  `;
  await sql`
    CREATE TABLE IF NOT EXISTS waitlist (
      email      TEXT PRIMARY KEY,
      created_at TIMESTAMPTZ NOT NULL
    )
  `;
  _schemaReady = true;
}

export async function insertLicensePg(row: {
  key: string;
  email: string;
  plan: License['plan'];
  stripeSession?: string;
  stripeSub?: string;
  expiresAt: string | null;
}): Promise<string> {
  await ensureSchema();
  if (row.stripeSession) {
    const existing = await sql<{ key: string }>`
      SELECT key FROM licenses WHERE stripe_session = ${row.stripeSession}
    `;
    if (existing.rows[0]) return existing.rows[0].key;
  }
  await sql`
    INSERT INTO licenses (key, email, plan, stripe_session, stripe_sub, issued_at, expires_at)
    VALUES (
      ${row.key},
      ${row.email.toLowerCase()},
      ${row.plan},
      ${row.stripeSession ?? null},
      ${row.stripeSub ?? null},
      NOW(),
      ${row.expiresAt}
    )
    ON CONFLICT (key) DO UPDATE SET email = EXCLUDED.email
  `;
  return row.key;
}

export async function findLicensePg(key: string, email?: string): Promise<License | null> {
  await ensureSchema();
  const cleanKey = key.trim().toUpperCase();
  const result = email
    ? await sql<License & { issued_at: string; expires_at: string | null }>`
        SELECT key, email, plan, status,
               to_char(issued_at, 'YYYY-MM-DD"T"HH24:MI:SSZ')  AS "issuedAt",
               to_char(expires_at, 'YYYY-MM-DD"T"HH24:MI:SSZ') AS "expiresAt"
        FROM licenses
        WHERE key = ${cleanKey} AND email = ${email.trim().toLowerCase()}
      `
    : await sql<License & { issued_at: string; expires_at: string | null }>`
        SELECT key, email, plan, status,
               to_char(issued_at, 'YYYY-MM-DD"T"HH24:MI:SSZ')  AS "issuedAt",
               to_char(expires_at, 'YYYY-MM-DD"T"HH24:MI:SSZ') AS "expiresAt"
        FROM licenses
        WHERE key = ${cleanKey}
      `;
  const row = result.rows[0];
  if (!row) return null;
  return {
    key: row.key,
    email: row.email,
    plan: row.plan,
    status: row.status,
    issuedAt: (row as any).issuedAt,
    expiresAt: (row as any).expiresAt,
  };
}

export async function recordActivationPg(key: string, machineHash: string): Promise<number> {
  await ensureSchema();
  await sql`
    INSERT INTO activations (license_key, machine_hash, first_seen, last_seen)
    VALUES (${key}, ${machineHash}, NOW(), NOW())
    ON CONFLICT (license_key, machine_hash) DO UPDATE SET last_seen = EXCLUDED.last_seen
  `;
  const result = await sql<{ c: number }>`
    SELECT COUNT(*)::int AS c FROM activations WHERE license_key = ${key}
  `;
  return result.rows[0]?.c ?? 0;
}

export async function hasActivationPg(key: string, machineHash: string): Promise<boolean> {
  await ensureSchema();
  const result = await sql<{ exists: boolean }>`
    SELECT EXISTS(
      SELECT 1 FROM activations WHERE license_key = ${key} AND machine_hash = ${machineHash}
    ) AS exists
  `;
  return result.rows[0]?.exists ?? false;
}

export async function countActivationsPg(key: string): Promise<number> {
  await ensureSchema();
  const result = await sql<{ c: number }>`
    SELECT COUNT(*)::int AS c FROM activations WHERE license_key = ${key}
  `;
  return result.rows[0]?.c ?? 0;
}

export async function setStatusPg(key: string, status: License['status']): Promise<void> {
  await ensureSchema();
  await sql`UPDATE licenses SET status = ${status} WHERE key = ${key}`;
}

export async function setStatusBySubPg(stripeSub: string, status: License['status']): Promise<void> {
  await ensureSchema();
  await sql`UPDATE licenses SET status = ${status} WHERE stripe_sub = ${stripeSub}`;
}

export async function setExpiryBySubPg(stripeSub: string, expiresAt: string | null): Promise<void> {
  await ensureSchema();
  await sql`UPDATE licenses SET expires_at = ${expiresAt} WHERE stripe_sub = ${stripeSub}`;
}

export async function joinWaitlistPg(email: string): Promise<void> {
  await ensureSchema();
  await sql`
    INSERT INTO waitlist (email, created_at)
    VALUES (${email.toLowerCase()}, NOW())
    ON CONFLICT (email) DO NOTHING
  `;
}
