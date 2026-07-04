// Postgres adapter — mirror of lib/db.ts using @vercel/postgres.
// Selected at runtime by lib/store.ts when DATABASE_URL is set to a postgres:// URL.
//
// Schema is created on first call. On Vercel + Neon this happens at cold-start.
// Idempotent — IF NOT EXISTS everywhere.

import { sql } from '@vercel/postgres';
import type { License, Activation } from './db';

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
  // Migration: add note column to existing deployments.
  await sql`ALTER TABLE licenses ADD COLUMN IF NOT EXISTS note TEXT`;
  await sql`
    CREATE TABLE IF NOT EXISTS audit_log (
      id           SERIAL PRIMARY KEY,
      license_key  TEXT,
      action       TEXT NOT NULL,
      detail       TEXT,
      created_at   TIMESTAMPTZ NOT NULL
    )
  `;
  await sql`CREATE INDEX IF NOT EXISTS idx_audit_log_license_key ON audit_log(license_key)`;
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
        SELECT key, email, plan, status, note,
               to_char(issued_at, 'YYYY-MM-DD"T"HH24:MI:SSZ')  AS "issuedAt",
               to_char(expires_at, 'YYYY-MM-DD"T"HH24:MI:SSZ') AS "expiresAt"
        FROM licenses
        WHERE key = ${cleanKey} AND email = ${email.trim().toLowerCase()}
      `
    : await sql<License & { issued_at: string; expires_at: string | null }>`
        SELECT key, email, plan, status, note,
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
    note: (row as any).note ?? null,
  };
}

export async function countLicensesByEmailPg(email: string, since?: string, status?: string, plan?: string): Promise<number> {
  await ensureSchema();
  const sinceVal = since ?? null;
  const statusVal = status ?? null;
  const planVal = plan ?? null;
  const result = await sql<{ c: number }>`
    SELECT COUNT(*)::int AS c FROM licenses l
    WHERE l.email = ${email.trim().toLowerCase()}
      AND (${sinceVal}::text IS NULL OR l.issued_at >= ${sinceVal}::text)
      AND (${statusVal}::text IS NULL OR l.status = ${statusVal}::text)
      AND (${planVal}::text IS NULL OR l.plan = ${planVal}::text)
  `;
  return result.rows[0]?.c ?? 0;
}

export async function findLicensesByEmailPg(email: string, limit?: number, offset?: number, since?: string, status?: string, plan?: string): Promise<License[]> {
  await ensureSchema();
  const norm = email.trim().toLowerCase();
  const pgOffset = offset ?? 0;
  const sinceVal = since ?? null;
  const statusVal = status ?? null;
  const planVal = plan ?? null;

  const result = limit != null
    ? await sql<any>`
        SELECT l.key, l.email, l.plan, l.status, l.note,
               to_char(l.issued_at,  'YYYY-MM-DD"T"HH24:MI:SSZ') AS "issuedAt",
               to_char(l.expires_at, 'YYYY-MM-DD"T"HH24:MI:SSZ') AS "expiresAt",
               COUNT(a.machine_hash)::int AS "machineCount",
               (SELECT action FROM audit_log WHERE license_key = l.key ORDER BY id DESC LIMIT 1) AS "lastAction",
               to_char((SELECT created_at FROM audit_log WHERE license_key = l.key ORDER BY id DESC LIMIT 1), 'YYYY-MM-DD"T"HH24:MI:SSZ') AS "lastActionAt"
        FROM licenses l
        LEFT JOIN activations a ON a.license_key = l.key
        WHERE l.email = ${norm}
          AND (${sinceVal}::text IS NULL OR l.issued_at >= ${sinceVal}::text)
          AND (${statusVal}::text IS NULL OR l.status = ${statusVal}::text)
          AND (${planVal}::text IS NULL OR l.plan = ${planVal}::text)
        GROUP BY l.key, l.email, l.plan, l.status, l.note, l.issued_at, l.expires_at
        ORDER BY l.issued_at DESC
        LIMIT ${limit} OFFSET ${pgOffset}
      `
    : await sql<any>`
        SELECT l.key, l.email, l.plan, l.status, l.note,
               to_char(l.issued_at,  'YYYY-MM-DD"T"HH24:MI:SSZ') AS "issuedAt",
               to_char(l.expires_at, 'YYYY-MM-DD"T"HH24:MI:SSZ') AS "expiresAt",
               COUNT(a.machine_hash)::int AS "machineCount",
               (SELECT action FROM audit_log WHERE license_key = l.key ORDER BY id DESC LIMIT 1) AS "lastAction",
               to_char((SELECT created_at FROM audit_log WHERE license_key = l.key ORDER BY id DESC LIMIT 1), 'YYYY-MM-DD"T"HH24:MI:SSZ') AS "lastActionAt"
        FROM licenses l
        LEFT JOIN activations a ON a.license_key = l.key
        WHERE l.email = ${norm}
          AND (${sinceVal}::text IS NULL OR l.issued_at >= ${sinceVal}::text)
          AND (${statusVal}::text IS NULL OR l.status = ${statusVal}::text)
          AND (${planVal}::text IS NULL OR l.plan = ${planVal}::text)
        GROUP BY l.key, l.email, l.plan, l.status, l.note, l.issued_at, l.expires_at
        ORDER BY l.issued_at DESC
      `;

  return result.rows.map((r: any) => ({
    key: r.key,
    email: r.email,
    plan: r.plan,
    status: r.status,
    issuedAt: r.issuedAt,
    expiresAt: r.expiresAt,
    note: r.note ?? null,
    machineCount: r.machineCount,
    lastAction: r.lastAction ?? null,
    lastActionAt: r.lastActionAt ?? null,
  }));
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

export async function listActivationsPg(key: string): Promise<Activation[]> {
  await ensureSchema();
  const result = await sql<any>`
    SELECT machine_hash,
           to_char(first_seen, 'YYYY-MM-DD"T"HH24:MI:SSZ') AS first_seen,
           to_char(last_seen,  'YYYY-MM-DD"T"HH24:MI:SSZ') AS last_seen
    FROM activations
    WHERE license_key = ${key}
    ORDER BY last_seen DESC
  `;
  return result.rows.map((r: any) => ({
    machineHash: r.machine_hash,
    firstSeen: r.first_seen,
    lastSeen: r.last_seen,
  }));
}

export async function removeActivationPg(key: string, machineHash: string): Promise<void> {
  await ensureSchema();
  await sql`DELETE FROM activations WHERE license_key = ${key} AND machine_hash = ${machineHash}`;
}

export async function setStatusPg(key: string, status: License['status']): Promise<void> {
  await ensureSchema();
  await sql`UPDATE licenses SET status = ${status} WHERE key = ${key}`;
}

export async function setPlanPg(key: string, plan: License['plan']): Promise<void> {
  await ensureSchema();
  await sql`UPDATE licenses SET plan = ${plan} WHERE key = ${key}`;
}

export async function findLicenseBySubPg(stripeSub: string): Promise<License | null> {
  await ensureSchema();
  const result = await sql<any>`
    SELECT key, email, plan, status,
           to_char(issued_at,  'YYYY-MM-DD"T"HH24:MI:SSZ') AS "issuedAt",
           to_char(expires_at, 'YYYY-MM-DD"T"HH24:MI:SSZ') AS "expiresAt"
    FROM licenses
    WHERE stripe_sub = ${stripeSub}
  `;
  const row = result.rows[0];
  if (!row) return null;
  return {
    key: row.key,
    email: row.email,
    plan: row.plan,
    status: row.status,
    issuedAt: row.issuedAt,
    expiresAt: row.expiresAt,
  };
}

export async function setStatusBySubPg(stripeSub: string, status: License['status']): Promise<void> {
  await ensureSchema();
  await sql`UPDATE licenses SET status = ${status} WHERE stripe_sub = ${stripeSub}`;
}

export async function setExpiryBySubPg(stripeSub: string, expiresAt: string | null): Promise<void> {
  await ensureSchema();
  await sql`UPDATE licenses SET expires_at = ${expiresAt} WHERE stripe_sub = ${stripeSub}`;
}

export async function setExpiryPg(key: string, expiresAt: string | null): Promise<void> {
  await ensureSchema();
  await sql`UPDATE licenses SET expires_at = ${expiresAt} WHERE key = ${key}`;
}

export async function removeAllActivationsPg(key: string): Promise<number> {
  await ensureSchema();
  const result = await sql`DELETE FROM activations WHERE license_key = ${key}`;
  return result.rowCount ?? 0;
}

export async function transferLicensePg(key: string, newEmail: string): Promise<void> {
  await ensureSchema();
  await sql`UPDATE licenses SET email = ${newEmail.toLowerCase().trim()} WHERE key = ${key}`;
}

export async function joinWaitlistPg(email: string): Promise<void> {
  await ensureSchema();
  await sql`
    INSERT INTO waitlist (email, created_at)
    VALUES (${email.toLowerCase()}, NOW())
    ON CONFLICT (email) DO NOTHING
  `;
}

export async function setNotePg(key: string, note: string | null): Promise<void> {
  await ensureSchema();
  await sql`UPDATE licenses SET note = ${note} WHERE key = ${key.trim().toUpperCase()}`;
}

export async function getNotePg(key: string): Promise<string | null> {
  await ensureSchema();
  const result = await sql<{ note: string | null }>`
    SELECT note FROM licenses WHERE key = ${key.trim().toUpperCase()}
  `;
  return result.rows[0]?.note ?? null;
}

import type { LicenseStats, AuditEntry } from './db';

export async function insertAuditLogPg(entry: {
  licenseKey: string | null;
  action: string;
  detail?: Record<string, unknown>;
}): Promise<void> {
  await ensureSchema();
  const detail = entry.detail ? JSON.stringify(entry.detail) : null;
  await sql`
    INSERT INTO audit_log (license_key, action, detail, created_at)
    VALUES (${entry.licenseKey}, ${entry.action}, ${detail}, NOW())
  `;
}

export async function listAuditLogPg(opts?: {
  licenseKey?: string;
  limit?: number;
}): Promise<AuditEntry[]> {
  await ensureSchema();
  const limit = Math.min(opts?.limit ?? 100, 500);
  const result = opts?.licenseKey
    ? await sql<any>`
        SELECT id, license_key,
               action, detail,
               to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SSZ') AS created_at
        FROM audit_log
        WHERE license_key = ${opts.licenseKey.trim().toUpperCase()}
        ORDER BY id DESC
        LIMIT ${limit}
      `
    : await sql<any>`
        SELECT id, license_key,
               action, detail,
               to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SSZ') AS created_at
        FROM audit_log
        ORDER BY id DESC
        LIMIT ${limit}
      `;
  return result.rows.map((r: any) => ({
    id: r.id,
    licenseKey: r.license_key,
    action: r.action,
    detail: r.detail,
    createdAt: r.created_at,
  }));
}

export async function searchLicensesPg(query: string, limit = 20, offset = 0, since?: string, status?: string, plan?: string): Promise<License[]> {
  await ensureSchema();
  const q = `%${query.trim()}%`;
  const lq = `%${query.trim().toLowerCase()}%`;
  const cap = Math.min(limit, 100);
  const sinceVal = since ?? null;
  const statusVal = status ?? null;
  const planVal = plan ?? null;
  const result = await sql<any>`
    SELECT l.key, l.email, l.plan, l.status, l.note,
           to_char(l.issued_at,  'YYYY-MM-DD"T"HH24:MI:SSZ') AS "issuedAt",
           to_char(l.expires_at, 'YYYY-MM-DD"T"HH24:MI:SSZ') AS "expiresAt",
           COUNT(a.machine_hash)::int AS "machineCount"
    FROM licenses l
    LEFT JOIN activations a ON a.license_key = l.key
    WHERE (l.key ILIKE ${q} OR l.email ILIKE ${lq} OR l.note ILIKE ${q})
      AND (${sinceVal}::text IS NULL OR l.issued_at >= ${sinceVal}::text)
      AND (${statusVal}::text IS NULL OR l.status = ${statusVal}::text)
      AND (${planVal}::text IS NULL OR l.plan = ${planVal}::text)
    GROUP BY l.key, l.email, l.plan, l.status, l.note, l.issued_at, l.expires_at
    ORDER BY l.issued_at DESC
    LIMIT ${cap} OFFSET ${offset}
  `;
  return result.rows.map((r: any) => ({
    key: r.key,
    email: r.email,
    plan: r.plan,
    status: r.status,
    issuedAt: r.issuedAt,
    expiresAt: r.expiresAt,
    note: r.note ?? null,
    machineCount: r.machineCount,
  }));
}

export async function countSearchLicensesPg(query: string, since?: string, status?: string, plan?: string): Promise<number> {
  await ensureSchema();
  const q = `%${query.trim()}%`;
  const lq = `%${query.trim().toLowerCase()}%`;
  const sinceVal = since ?? null;
  const statusVal = status ?? null;
  const planVal = plan ?? null;
  const result = await sql<any>`
    SELECT COUNT(DISTINCT l.key)::int AS total
    FROM licenses l
    WHERE (l.key ILIKE ${q} OR l.email ILIKE ${lq} OR l.note ILIKE ${q})
      AND (${sinceVal}::text IS NULL OR l.issued_at >= ${sinceVal}::text)
      AND (${statusVal}::text IS NULL OR l.status = ${statusVal}::text)
      AND (${planVal}::text IS NULL OR l.plan = ${planVal}::text)
  `;
  return result.rows[0]?.total ?? 0;
}

export async function searchLicensesAllPg(query: string, since?: string, status?: string, plan?: string): Promise<License[]> {
  await ensureSchema();
  const q = `%${query.trim()}%`;
  const lq = `%${query.trim().toLowerCase()}%`;
  const sinceVal = since ?? null;
  const statusVal = status ?? null;
  const planVal = plan ?? null;
  const result = await sql<any>`
    SELECT l.key, l.email, l.plan, l.status, l.note,
           to_char(l.issued_at,  'YYYY-MM-DD"T"HH24:MI:SSZ') AS "issuedAt",
           to_char(l.expires_at, 'YYYY-MM-DD"T"HH24:MI:SSZ') AS "expiresAt",
           COUNT(a.machine_hash)::int AS "machineCount"
    FROM licenses l
    LEFT JOIN activations a ON a.license_key = l.key
    WHERE (l.key ILIKE ${q} OR l.email ILIKE ${lq} OR l.note ILIKE ${q})
      AND (${sinceVal}::text IS NULL OR l.issued_at >= ${sinceVal}::text)
      AND (${statusVal}::text IS NULL OR l.status = ${statusVal}::text)
      AND (${planVal}::text IS NULL OR l.plan = ${planVal}::text)
    GROUP BY l.key, l.email, l.plan, l.status, l.note, l.issued_at, l.expires_at
    ORDER BY l.issued_at DESC
  `;
  return result.rows.map((r: any) => ({
    key: r.key,
    email: r.email,
    plan: r.plan,
    status: r.status,
    issuedAt: r.issuedAt,
    expiresAt: r.expiresAt,
    note: r.note ?? null,
    machineCount: r.machineCount,
  }));
}

export async function getStatsPg(): Promise<LicenseStats> {
  await ensureSchema();

  const [totalRes, statusRes, planRes, week7Res, week30Res, activationRes] = await Promise.all([
    sql<{ total: number }>`SELECT COUNT(*)::int AS total FROM licenses`,
    sql<{ status: string; c: number }>`SELECT status, COUNT(*)::int AS c FROM licenses GROUP BY status`,
    sql<{ plan: string; c: number }>`SELECT plan, COUNT(*)::int AS c FROM licenses GROUP BY plan`,
    sql<{ c: number }>`SELECT COUNT(*)::int AS c FROM licenses WHERE issued_at >= NOW() - INTERVAL '7 days'`,
    sql<{ c: number }>`SELECT COUNT(*)::int AS c FROM licenses WHERE issued_at >= NOW() - INTERVAL '30 days'`,
    sql<{ c: number }>`SELECT COUNT(*)::int AS c FROM activations`,
  ]);

  const byStatus: Record<string, number> = {};
  for (const r of statusRes.rows) byStatus[r.status] = r.c;

  const byPlan: Record<string, number> = {};
  for (const r of planRes.rows) byPlan[r.plan] = r.c;

  return {
    total: totalRes.rows[0]?.total ?? 0,
    byStatus,
    byPlan,
    newLast7Days: week7Res.rows[0]?.c ?? 0,
    newLast30Days: week30Res.rows[0]?.c ?? 0,
    activatedMachines: activationRes.rows[0]?.c ?? 0,
  };
}

export async function listAllLicensesPg(since?: string, status?: string, plan?: string): Promise<License[]> {
  await ensureSchema();
  const sinceVal = since ?? null;
  const statusVal = status ?? null;
  const planVal = plan ?? null;
  const result = await sql<any>`
    SELECT l.key, l.email, l.plan, l.status, l.note,
           to_char(l.issued_at,  'YYYY-MM-DD"T"HH24:MI:SSZ') AS "issuedAt",
           to_char(l.expires_at, 'YYYY-MM-DD"T"HH24:MI:SSZ') AS "expiresAt",
           COUNT(a.machine_hash)::int AS "machineCount"
    FROM licenses l
    LEFT JOIN activations a ON a.license_key = l.key
    WHERE (${sinceVal}::text IS NULL OR l.issued_at >= ${sinceVal}::text)
      AND (${statusVal}::text IS NULL OR l.status = ${statusVal}::text)
      AND (${planVal}::text IS NULL OR l.plan = ${planVal}::text)
    GROUP BY l.key, l.email, l.plan, l.status, l.note, l.issued_at, l.expires_at
    ORDER BY l.issued_at DESC
  `;
  return result.rows.map((r: any) => ({
    key: r.key,
    email: r.email,
    plan: r.plan,
    status: r.status,
    issuedAt: r.issuedAt,
    expiresAt: r.expiresAt ?? null,
    note: r.note ?? null,
    machineCount: r.machineCount,
  }));
}
