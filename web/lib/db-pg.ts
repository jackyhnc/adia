// Postgres adapter — mirror of lib/db.ts using @vercel/postgres.
// Selected at runtime by lib/store.ts when DATABASE_URL is set to a postgres:// URL.
//
// Schema is created on first call. On Vercel + Neon this happens at cold-start.
// Idempotent — IF NOT EXISTS everywhere.

import { sql } from '@vercel/postgres';
import type { License, Activation, AuditEntry } from './db';

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

import type { LicenseStats } from './db';

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

export async function countAuditLogPg(opts?: { licenseKey?: string; action?: string; since?: string }): Promise<number> {
  await ensureSchema();
  const keyVal = opts?.licenseKey ? opts.licenseKey.trim().toUpperCase() : null;
  const actionVal = opts?.action ? opts.action.trim() : null;
  const sinceVal = opts?.since ? opts.since.trim() : null;
  const result = await sql<any>`
    SELECT COUNT(*) AS n FROM audit_log
    WHERE (${keyVal}::text IS NULL OR license_key = ${keyVal}::text)
      AND (${actionVal}::text IS NULL OR action = ${actionVal}::text)
      AND (${sinceVal}::text IS NULL OR created_at >= ${sinceVal}::text)
  `;
  return Number(result.rows[0].n);
}

export async function listAuditLogPg(opts?: {
  licenseKey?: string;
  limit?: number;
  offset?: number;
  action?: string;
  since?: string;
}): Promise<AuditEntry[]> {
  await ensureSchema();
  const limit = Math.min(opts?.limit ?? 100, 500);
  const offset = opts?.offset ?? 0;
  const keyVal = opts?.licenseKey ? opts.licenseKey.trim().toUpperCase() : null;
  const actionVal = opts?.action ? opts.action.trim() : null;
  const sinceVal = opts?.since ? opts.since.trim() : null;
  const result = await sql<any>`
    SELECT id, license_key,
           action, detail,
           to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SSZ') AS created_at
    FROM audit_log
    WHERE (${keyVal}::text IS NULL OR license_key = ${keyVal}::text)
      AND (${actionVal}::text IS NULL OR action = ${actionVal}::text)
      AND (${sinceVal}::text IS NULL OR created_at >= ${sinceVal}::text)
    ORDER BY id DESC
    LIMIT ${limit} OFFSET ${offset}
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

  const [totalRes, statusRes, planRes, week7Res, week30Res, activationRes, expiring30Res] = await Promise.all([
    sql<{ total: number }>`SELECT COUNT(*)::int AS total FROM licenses`,
    sql<{ status: string; c: number }>`SELECT status, COUNT(*)::int AS c FROM licenses GROUP BY status`,
    sql<{ plan: string; c: number }>`SELECT plan, COUNT(*)::int AS c FROM licenses GROUP BY plan`,
    sql<{ c: number }>`SELECT COUNT(*)::int AS c FROM licenses WHERE issued_at >= NOW() - INTERVAL '7 days'`,
    sql<{ c: number }>`SELECT COUNT(*)::int AS c FROM licenses WHERE issued_at >= NOW() - INTERVAL '30 days'`,
    sql<{ c: number }>`SELECT COUNT(*)::int AS c FROM activations`,
    sql<{ c: number }>`SELECT COUNT(*)::int AS c FROM licenses WHERE expires_at IS NOT NULL AND expires_at >= NOW() AND expires_at <= NOW() + INTERVAL '30 days' AND status = 'active'`,
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
    expiringIn30Days: expiring30Res.rows[0]?.c ?? 0,
  };
}

export async function countNotifyHistoryPg(email: string): Promise<number> {
  await ensureSchema();
  const norm = email.trim().toLowerCase();
  const result = await sql<any>`
    SELECT COUNT(*) AS n FROM audit_log al
    JOIN licenses l ON l.key = al.license_key
    WHERE LOWER(l.email) = ${norm} AND al.action = 'notify'
  `;
  return Number(result.rows[0].n);
}

export async function listNotifyHistoryPg(email: string, limit = 20, offset = 0): Promise<AuditEntry[]> {
  await ensureSchema();
  const norm = email.trim().toLowerCase();
  const cap = Math.min(limit, 100);
  const result = await sql<any>`
    SELECT al.id, al.license_key,
           al.action, al.detail,
           to_char(al.created_at, 'YYYY-MM-DD"T"HH24:MI:SSZ') AS created_at
    FROM audit_log al
    JOIN licenses l ON l.key = al.license_key
    WHERE LOWER(l.email) = ${norm} AND al.action = 'notify'
    ORDER BY al.id DESC
    LIMIT ${cap} OFFSET ${offset}
  `;
  return result.rows.map((r: any) => ({
    id: r.id,
    licenseKey: r.license_key,
    action: r.action,
    detail: r.detail,
    createdAt: r.created_at,
  }));
}

export async function listAllAuditLogPg(since?: string, action?: string, licenseKey?: string): Promise<AuditEntry[]> {
  await ensureSchema();
  const sinceVal = since ?? null;
  const actionVal = action?.trim() ?? null;
  const keyVal = licenseKey ? licenseKey.trim().toUpperCase() : null;
  const result = await sql<any>`
    SELECT id, license_key,
           action, detail,
           to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SSZ') AS created_at
    FROM audit_log
    WHERE (${sinceVal}::text IS NULL OR created_at >= ${sinceVal}::text)
      AND (${actionVal}::text IS NULL OR action = ${actionVal}::text)
      AND (${keyVal}::text IS NULL OR license_key = ${keyVal}::text)
    ORDER BY id DESC
  `;
  return result.rows.map((r: any) => ({
    id: r.id,
    licenseKey: r.license_key,
    action: r.action,
    detail: r.detail,
    createdAt: r.created_at,
  }));
}

export async function listExpiringLicensesPg(days: number, plan?: string): Promise<License[]> {
  await ensureSchema();
  const now = new Date().toISOString();
  const cutoff = new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString();
  const planVal = plan ?? null;
  const result = await sql<any>`
    SELECT l.key, l.email, l.plan, l.status, l.note,
           to_char(l.issued_at,  'YYYY-MM-DD"T"HH24:MI:SSZ') AS "issuedAt",
           to_char(l.expires_at, 'YYYY-MM-DD"T"HH24:MI:SSZ') AS "expiresAt",
           COUNT(a.machine_hash)::int AS "machineCount"
    FROM licenses l
    LEFT JOIN activations a ON a.license_key = l.key
    WHERE l.expires_at IS NOT NULL
      AND l.expires_at >= ${now}
      AND l.expires_at <= ${cutoff}
      AND l.status = 'active'
      AND (${planVal}::text IS NULL OR l.plan = ${planVal}::text)
    GROUP BY l.key, l.email, l.plan, l.status, l.note, l.issued_at, l.expires_at
    ORDER BY l.expires_at ASC
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

export async function listNeverActivatedLicensesPg(plan?: string, since?: string, status?: string): Promise<License[]> {
  await ensureSchema();
  const planVal = plan ?? null;
  const sinceVal = since ?? null;
  const statusVal = status ?? null;
  const result = await sql<any>`
    SELECT l.key, l.email, l.plan, l.status, l.note,
           to_char(l.issued_at,  'YYYY-MM-DD"T"HH24:MI:SSZ') AS "issuedAt",
           to_char(l.expires_at, 'YYYY-MM-DD"T"HH24:MI:SSZ') AS "expiresAt",
           COUNT(a.machine_hash)::int AS "machineCount"
    FROM licenses l
    LEFT JOIN activations a ON a.license_key = l.key
    WHERE (${planVal}::text IS NULL OR l.plan = ${planVal}::text)
      AND (${sinceVal}::text IS NULL OR l.issued_at >= ${sinceVal}::text)
      AND (${statusVal}::text IS NULL OR l.status = ${statusVal}::text)
    GROUP BY l.key, l.email, l.plan, l.status, l.note, l.issued_at, l.expires_at
    HAVING COUNT(a.machine_hash) = 0
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

export async function listDormantLicensesPg(days: number, plan?: string, status?: string): Promise<License[]> {
  await ensureSchema();
  const planVal = plan ?? null;
  const statusVal = status ?? null;
  const result = await sql<any>`
    SELECT l.key, l.email, l.plan, l.status, l.note,
           to_char(l.issued_at,  'YYYY-MM-DD"T"HH24:MI:SSZ') AS "issuedAt",
           to_char(l.expires_at, 'YYYY-MM-DD"T"HH24:MI:SSZ') AS "expiresAt",
           COUNT(a.machine_hash)::int AS "machineCount",
           to_char(MAX(a.last_seen), 'YYYY-MM-DD"T"HH24:MI:SSZ') AS "lastSeen"
    FROM licenses l
    INNER JOIN activations a ON a.license_key = l.key
    WHERE (${planVal}::text IS NULL OR l.plan = ${planVal}::text)
      AND (${statusVal}::text IS NULL OR l.status = ${statusVal}::text)
    GROUP BY l.key, l.email, l.plan, l.status, l.note, l.issued_at, l.expires_at
    HAVING MAX(a.last_seen) < NOW() - (${days} * INTERVAL '1 day')
    ORDER BY MAX(a.last_seen) DESC
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
    lastSeen: r.lastSeen ?? null,
  }));
}

export type HeatmapBucket = { hour: number; count: number };

export async function activationHeatmapPg(days: number, plan?: string): Promise<HeatmapBucket[]> {
  await ensureSchema();
  const planVal = plan ?? null;
  const result = await sql<any>`
    SELECT EXTRACT(HOUR FROM first_seen::timestamptz)::int AS hour, COUNT(*)::int AS count
    FROM activations a
    INNER JOIN licenses l ON l.key = a.license_key
    WHERE a.first_seen >= NOW() - (${days} * INTERVAL '1 day')
      AND (${planVal}::text IS NULL OR l.plan = ${planVal}::text)
    GROUP BY hour
    ORDER BY hour
  `;
  const map = new Map<number, number>(result.rows.map((r: any) => [r.hour as number, r.count as number]));
  return Array.from({ length: 24 }, (_, h) => ({ hour: h, count: map.get(h) ?? 0 }));
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

// Pricing constants (USD)
const PG_PRICE_MONTHLY = 7.00;
const PG_PRICE_YEARLY_MONTHLY = 59.00 / 12;
const PG_PRICE_LIFETIME = 149.00;

function pg_round2(n: number): number {
  return Math.round(n * 100) / 100;
}

import type { RevenueMetrics } from './db';

export async function revenueMetricsPg(): Promise<RevenueMetrics> {
  await ensureSchema();
  const counts = await sql<any>`
    SELECT plan, status, COUNT(*)::int AS c
    FROM licenses
    WHERE plan IN ('monthly','yearly','lifetime')
      AND status IN ('active','past_due')
    GROUP BY plan, status
  `;
  const newCounts = await sql<any>`
    SELECT plan, COUNT(*)::int AS c
    FROM licenses
    WHERE plan IN ('monthly','yearly','lifetime')
      AND status = 'active'
      AND issued_at >= NOW() - INTERVAL '30 days'
    GROUP BY plan
  `;

  function get(plan: string, status: string): number {
    return counts.rows.find((r: any) => r.plan === plan && r.status === status)?.c ?? 0;
  }
  function getNew(plan: string): number {
    return newCounts.rows.find((r: any) => r.plan === plan)?.c ?? 0;
  }

  const mActive = get('monthly', 'active');
  const mPastDue = get('monthly', 'past_due');
  const mNew = getNew('monthly');

  const yActive = get('yearly', 'active');
  const yPastDue = get('yearly', 'past_due');
  const yNew = getNew('yearly');

  const lActive = get('lifetime', 'active');
  const lPastDue = get('lifetime', 'past_due');
  const lNew = getNew('lifetime');

  const mrr = pg_round2(mActive * PG_PRICE_MONTHLY + yActive * PG_PRICE_YEARLY_MONTHLY);
  const arr = pg_round2(mrr * 12);
  const lifetimeRevenue = pg_round2(lActive * PG_PRICE_LIFETIME);
  const pastDueMrr = pg_round2(mPastDue * PG_PRICE_MONTHLY + yPastDue * PG_PRICE_YEARLY_MONTHLY);
  const newMrr30d = pg_round2(mNew * PG_PRICE_MONTHLY + yNew * PG_PRICE_YEARLY_MONTHLY);

  return {
    mrr,
    arr,
    lifetimeRevenue,
    pastDueMrr,
    newMrr30d,
    byPlan: {
      monthly:  { active: mActive, pastDue: mPastDue, new30d: mNew, mrr: pg_round2(mActive * PG_PRICE_MONTHLY) },
      yearly:   { active: yActive, pastDue: yPastDue, new30d: yNew, mrr: pg_round2(yActive * PG_PRICE_YEARLY_MONTHLY) },
      lifetime: { active: lActive, pastDue: lPastDue, new30d: lNew, revenue: pg_round2(lActive * PG_PRICE_LIFETIME) },
    },
  };
}

import type { TimelineDay } from './db';

export async function activationTimelinePg(days: number, plan?: string): Promise<TimelineDay[]> {
  await ensureSchema();
  const planVal = plan ?? null;
  const result = await sql<any>`
    SELECT to_char(a.first_seen::date, 'YYYY-MM-DD') AS date, COUNT(*)::int AS count
    FROM activations a
    INNER JOIN licenses l ON l.key = a.license_key
    WHERE a.first_seen >= NOW() - (${days} * INTERVAL '1 day')
      AND (${planVal}::text IS NULL OR l.plan = ${planVal}::text)
    GROUP BY a.first_seen::date
    ORDER BY a.first_seen::date
  `;
  const map = new Map<string, number>(result.rows.map((r: any) => [r.date as string, r.count as number]));
  const output: TimelineDay[] = [];
  const now = Date.now();
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(now - i * 24 * 60 * 60 * 1000);
    const dateStr = d.toISOString().slice(0, 10);
    output.push({ date: dateStr, count: map.get(dateStr) ?? 0 });
  }
  return output;
}

import type { CohortRetentionResult } from './db';

export async function cohortRetentionPg(days: number, plan?: string): Promise<CohortRetentionResult> {
  await ensureSchema();
  const planVal = plan ?? null;
  const result = await sql<any>`
    SELECT
      to_char(l.issued_at::date, 'YYYY-MM-DD') AS cohort_date,
      COUNT(*)::int AS total,
      SUM(CASE WHEN l.status = 'active' THEN 1 ELSE 0 END)::int AS active_now,
      EXTRACT(day FROM NOW() - l.issued_at::date)::int AS age_days
    FROM licenses l
    WHERE l.issued_at >= NOW() - (${days} * INTERVAL '1 day')
      AND (${planVal}::text IS NULL OR l.plan = ${planVal}::text)
    GROUP BY l.issued_at::date
    ORDER BY l.issued_at::date ASC
  `;

  const cohorts = result.rows.map((r: any) => ({
    date: r.cohort_date as string,
    total: r.total as number,
    activeNow: r.active_now as number,
    ageDays: r.age_days as number,
    retentionRate: r.total > 0 ? Math.round((r.active_now / r.total) * 1000) / 10 : 0,
  }));

  function summary(minAge: number) {
    const eligible = cohorts.filter((c: any) => c.ageDays >= minAge);
    if (eligible.length === 0) return null;
    const totalLicenses = eligible.reduce((s: number, c: any) => s + c.total, 0);
    const activeCount = eligible.reduce((s: number, c: any) => s + c.activeNow, 0);
    return {
      cohortCount: eligible.length,
      totalLicenses,
      activeCount,
      rate: totalLicenses > 0 ? Math.round((activeCount / totalLicenses) * 1000) / 10 : 0,
    };
  }

  return {
    cohorts,
    summary30d: summary(30),
    summary60d: summary(60),
    summary90d: summary(90),
    windowDays: days,
    ...(plan ? { plan } : {}),
  };
}

import type { ChurnAnalysisResult, ChurnBucket, ChurnByPlan } from './db';

export async function churnAnalysisPg(days: number, plan?: string): Promise<ChurnAnalysisResult> {
  const planVal = plan ?? null;

  const bucketsResult = await sql<any>`
    SELECT
      to_char(a.created_at::date, 'YYYY-MM-DD') AS event_date,
      COUNT(*)::int AS churned
    FROM audit_log a
    INNER JOIN licenses l ON a.license_key = l.key
    WHERE a.created_at >= NOW() - (${days} * INTERVAL '1 day')
      AND (
        a.action = 'revoke'
        OR (a.action = 'set_status' AND (a.detail::jsonb)->>'status' IN ('canceled', 'expired', 'past_due'))
      )
      AND (${planVal}::text IS NULL OR l.plan = ${planVal}::text)
    GROUP BY a.created_at::date
    ORDER BY event_date ASC
  `;

  const bucketMap = new Map<string, number>(bucketsResult.rows.map((r: any) => [r.event_date as string, r.churned as number]));
  const now = Date.now();
  const buckets: ChurnBucket[] = [];
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(now - i * 24 * 60 * 60 * 1000);
    const dateStr = d.toISOString().slice(0, 10);
    buckets.push({ date: dateStr, churned: bucketMap.get(dateStr) ?? 0 });
  }
  const totalChurned = buckets.reduce((s, b) => s + b.churned, 0);

  const byPlanResult = await sql<any>`
    SELECT l.plan, COUNT(*)::int AS churned
    FROM audit_log a
    INNER JOIN licenses l ON a.license_key = l.key
    WHERE a.created_at >= NOW() - (${days} * INTERVAL '1 day')
      AND (
        a.action = 'revoke'
        OR (a.action = 'set_status' AND (a.detail::jsonb)->>'status' IN ('canceled', 'expired', 'past_due'))
      )
      AND (${planVal}::text IS NULL OR l.plan = ${planVal}::text)
    GROUP BY l.plan
  `;

  const byPlan: ChurnByPlan = { monthly: 0, yearly: 0, lifetime: 0 };
  for (const r of byPlanResult.rows) {
    if (r.plan === 'monthly' || r.plan === 'yearly' || r.plan === 'lifetime') {
      byPlan[r.plan as keyof ChurnByPlan] = r.churned as number;
    }
  }

  const activeResult = await sql<any>`
    SELECT COUNT(*)::int AS cnt FROM licenses
    WHERE status = 'active'
      AND (${planVal}::text IS NULL OR plan = ${planVal}::text)
  `;
  const currentActive = (activeResult.rows[0]?.cnt as number) ?? 0;
  const denominator = totalChurned + currentActive;
  const churnRate = denominator > 0 ? Math.round((totalChurned / denominator) * 1000) / 10 : 0;

  return {
    buckets,
    totalChurned,
    byPlan,
    churnRate,
    windowDays: days,
    ...(plan ? { plan } : {}),
  };
}

import type { ChurnCohortResult, ChurnCohortRow, ChurnCohortSummary } from './db';

export async function churnCohortPg(days: number, plan?: string): Promise<ChurnCohortResult> {
  const planVal = plan ?? null;

  const rows = await sql<any>`
    SELECT
      to_char(l.issued_at::date, 'YYYY-MM-DD') AS cohort_date,
      COUNT(*)::int AS total,
      COUNT(fc.license_key)::int AS churned,
      COUNT(CASE WHEN EXTRACT(day FROM fc.event_date::date - l.issued_at::date) <= 30 THEN 1 END)::int AS churned_30d,
      COUNT(CASE WHEN EXTRACT(day FROM fc.event_date::date - l.issued_at::date) <= 60 THEN 1 END)::int AS churned_60d,
      COUNT(CASE WHEN EXTRACT(day FROM fc.event_date::date - l.issued_at::date) <= 90 THEN 1 END)::int AS churned_90d,
      EXTRACT(day FROM NOW() - l.issued_at::date)::int AS age_days
    FROM licenses l
    LEFT JOIN (
      SELECT license_key, MIN(created_at::date) AS event_date
      FROM audit_log
      WHERE action = 'revoke'
        OR (action = 'set_status' AND (detail::jsonb)->>'status' IN ('canceled', 'expired', 'past_due'))
      GROUP BY license_key
    ) fc ON fc.license_key = l.key
    WHERE l.issued_at >= NOW() - (${days} * INTERVAL '1 day')
      AND (${planVal}::text IS NULL OR l.plan = ${planVal}::text)
    GROUP BY l.issued_at::date
    ORDER BY cohort_date ASC
  `;

  const cohorts: ChurnCohortRow[] = rows.rows.map((r: any) => ({
    date: r.cohort_date as string,
    total: r.total as number,
    churned: r.churned as number,
    churnedWithin30d: r.churned_30d as number,
    churnedWithin60d: r.churned_60d as number,
    churnedWithin90d: r.churned_90d as number,
    churnRate: r.total > 0 ? Math.round((r.churned / r.total) * 1000) / 10 : 0,
    ageDays: r.age_days as number,
  }));

  function summary(minAge: number): ChurnCohortSummary | null {
    const eligible = cohorts.filter(c => c.ageDays >= minAge);
    if (eligible.length === 0) return null;
    const totalLicenses = eligible.reduce((s, c) => s + c.total, 0);
    const totalChurned = eligible.reduce((s, c) => s + c.churned, 0);
    return {
      cohortCount: eligible.length,
      totalLicenses,
      totalChurned,
      avgChurnRate: totalLicenses > 0 ? Math.round((totalChurned / totalLicenses) * 1000) / 10 : 0,
    };
  }

  return {
    cohorts,
    summary30d: summary(30),
    summary60d: summary(60),
    summary90d: summary(90),
    windowDays: days,
    ...(plan ? { plan } : {}),
  };
}

import type { TimeToChurnResult } from './db';

const TTCBuckets = [
  { label: '0-7d',   minDays: 0,  maxDays: 7    as number | null },
  { label: '8-30d',  minDays: 8,  maxDays: 30   as number | null },
  { label: '31-90d', minDays: 31, maxDays: 90   as number | null },
  { label: '91d+',   minDays: 91, maxDays: null as number | null },
];

export async function timeToChurnPg(days: number, plan?: string): Promise<TimeToChurnResult> {
  const planVal = plan ?? null;

  const result = await sql<any>`
    SELECT
      EXTRACT(day FROM fc.event_date::date - l.issued_at::date)::int AS days_to_churn
    FROM licenses l
    INNER JOIN (
      SELECT license_key, MIN(created_at::date) AS event_date
      FROM audit_log
      WHERE action = 'revoke'
        OR (action = 'set_status' AND (detail::jsonb)->>'status' IN ('canceled', 'expired', 'past_due'))
      GROUP BY license_key
    ) fc ON fc.license_key = l.key
    WHERE l.issued_at >= NOW() - (${days} * INTERVAL '1 day')
      AND (${planVal}::text IS NULL OR l.plan = ${planVal}::text)
  `;

  const allDays: number[] = result.rows
    .map((r: any) => r.days_to_churn as number)
    .filter((d: number) => d >= 0);
  const totalChurned = allDays.length;

  const counts = new Array<number>(TTCBuckets.length).fill(0);
  for (const d of allDays) {
    for (let i = 0; i < TTCBuckets.length; i++) {
      const b = TTCBuckets[i]!;
      if (d >= b.minDays && (b.maxDays === null || d <= b.maxDays)) {
        counts[i]!++;
        break;
      }
    }
  }

  const buckets = TTCBuckets.map((b, i) => ({
    label: b.label,
    minDays: b.minDays,
    maxDays: b.maxDays,
    count: counts[i]!,
    pct: totalChurned > 0 ? Math.round((counts[i]! / totalChurned) * 1000) / 10 : 0,
  }));

  let medianDays: number | null = null;
  let meanDays: number | null = null;
  if (totalChurned > 0) {
    const sorted = [...allDays].sort((a, b) => a - b);
    const mid = Math.floor(sorted.length / 2);
    medianDays = sorted.length % 2 === 0
      ? Math.round(((sorted[mid - 1]! + sorted[mid]!) / 2) * 10) / 10
      : sorted[mid]!;
    meanDays = Math.round((allDays.reduce((s, d) => s + d, 0) / totalChurned) * 10) / 10;
  }

  return {
    buckets,
    totalChurned,
    medianDays,
    meanDays,
    windowDays: days,
    ...(plan ? { plan } : {}),
  };
}
