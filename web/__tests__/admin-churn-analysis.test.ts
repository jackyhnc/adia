// Tests for GET /api/admin/churn-analysis
// Returns daily churn event counts, total churned, per-plan breakdown, and churn rate.
// Churn events: action='revoke', OR action='set_status' with status in {canceled,expired,past_due}.
// Supports ?days= (default 30, max 365) and ?plan= filters.

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import Database from 'better-sqlite3';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, insertAuditLog } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

function openDb(p: string) { return new Database(p); }

// Insert a churn audit_log entry backdated by `daysAgo` days.
function insertChurnEvent(
  db: Database.Database,
  licenseKey: string,
  action: 'revoke' | 'set_status',
  status: string | null,
  daysAgo: number,
) {
  const d = new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000);
  d.setUTCHours(12, 0, 0, 0);
  const detail = action === 'set_status' && status
    ? JSON.stringify({ status, previousStatus: 'active' })
    : action === 'revoke'
    ? JSON.stringify({ previousStatus: 'active' })
    : null;
  db.prepare(
    'INSERT INTO audit_log (license_key, action, detail, created_at) VALUES (?, ?, ?, ?)',
  ).run(licenseKey, action, detail, d.toISOString());
}

function lic(key: string, email: string, plan: 'monthly' | 'yearly' | 'lifetime' = 'monthly') {
  insertLicense({ key, email, plan, expiresAt: null });
}

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(
    os.tmpdir(),
    `adia-churn-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
  );
  resetDbForTesting(dbPath);
  process.env.ADMIN_TOKEN = 'test-admin-token';
});

afterEach(() => {
  resetDbForTesting();
  delete process.env.ADMIN_TOKEN;
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

function authHeader(token = 'test-admin-token') {
  return { Authorization: `Bearer ${token}` };
}

async function callGet(params: Record<string, string> = {}, token = 'test-admin-token') {
  const { GET } = await import('@/app/api/admin/churn-analysis/route');
  const sp = new URLSearchParams(params);
  const req = new NextRequest(`http://localhost/api/admin/churn-analysis?${sp}`, {
    method: 'GET',
    headers: authHeader(token),
  });
  return GET(req);
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('GET /api/admin/churn-analysis — auth', () => {
  it('returns 401 with no authorization header', async () => {
    const { GET } = await import('@/app/api/admin/churn-analysis/route');
    const req = new NextRequest('http://localhost/api/admin/churn-analysis');
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callGet({}, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query-param auth', async () => {
    const { GET } = await import('@/app/api/admin/churn-analysis/route');
    const req = new NextRequest('http://localhost/api/admin/churn-analysis?token=test-admin-token');
    const res = await GET(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ───────────────────────────────────────────────────────────────

describe('GET /api/admin/churn-analysis — validation', () => {
  it('rejects days=0', async () => {
    const res = await callGet({ days: '0' });
    expect(res.status).toBe(400);
    const json = await res.json();
    expect(json.error).toMatch(/invalid days/);
  });

  it('rejects days=366', async () => {
    const res = await callGet({ days: '366' });
    expect(res.status).toBe(400);
  });

  it('rejects non-integer days', async () => {
    const res = await callGet({ days: 'abc' });
    expect(res.status).toBe(400);
  });

  it('rejects fractional days', async () => {
    const res = await callGet({ days: '7.5' });
    expect(res.status).toBe(400);
  });

  it('rejects invalid plan', async () => {
    const res = await callGet({ plan: 'enterprise' });
    expect(res.status).toBe(400);
    const json = await res.json();
    expect(json.error).toMatch(/invalid plan/);
  });
});

// ─── Response shape ───────────────────────────────────────────────────────────

describe('GET /api/admin/churn-analysis — response shape', () => {
  it('returns 200 on empty DB', async () => {
    const res = await callGet();
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json).toMatchObject({
      buckets: expect.any(Array),
      totalChurned: 0,
      byPlan: { monthly: 0, yearly: 0, lifetime: 0 },
      churnRate: 0,
      windowDays: 30,
    });
  });

  it('buckets length equals days param', async () => {
    const res = await callGet({ days: '14' });
    const json = await res.json();
    expect(json.buckets).toHaveLength(14);
  });

  it('default days is 30', async () => {
    const res = await callGet();
    const json = await res.json();
    expect(json.buckets).toHaveLength(30);
    expect(json.windowDays).toBe(30);
  });

  it('accepts days=1', async () => {
    const res = await callGet({ days: '1' });
    const json = await res.json();
    expect(json.buckets).toHaveLength(1);
  });

  it('accepts days=365', async () => {
    const res = await callGet({ days: '365' });
    const json = await res.json();
    expect(json.buckets).toHaveLength(365);
  });

  it('bucket shape has date and churned', async () => {
    const res = await callGet({ days: '3' });
    const json = await res.json();
    for (const b of json.buckets) {
      expect(b).toHaveProperty('date');
      expect(b).toHaveProperty('churned');
      expect(typeof b.date).toBe('string');
      expect(typeof b.churned).toBe('number');
    }
  });

  it('buckets are in ascending date order', async () => {
    const res = await callGet({ days: '7' });
    const json = await res.json();
    const dates = json.buckets.map((b: any) => b.date);
    expect(dates).toEqual([...dates].sort());
  });

  it('plan field present when plan filter used', async () => {
    const res = await callGet({ plan: 'monthly' });
    const json = await res.json();
    expect(json.plan).toBe('monthly');
  });

  it('plan field absent when no plan filter', async () => {
    const res = await callGet();
    const json = await res.json();
    expect(json.plan).toBeUndefined();
  });
});

// ─── Core behavior ────────────────────────────────────────────────────────────

describe('GET /api/admin/churn-analysis — core behavior', () => {
  it('counts revoke action as churn event', async () => {
    const db = openDb(dbPath);
    lic('K1', 'a@x.com', 'monthly');
    insertChurnEvent(db, 'K1', 'revoke', null, 2);
    db.close();

    const res = await callGet({ days: '7' });
    const json = await res.json();
    expect(json.totalChurned).toBe(1);
  });

  it('counts set_status to canceled as churn event', async () => {
    const db = openDb(dbPath);
    lic('K2', 'b@x.com', 'yearly');
    insertChurnEvent(db, 'K2', 'set_status', 'canceled', 1);
    db.close();

    const res = await callGet({ days: '7' });
    const json = await res.json();
    expect(json.totalChurned).toBe(1);
  });

  it('counts set_status to expired as churn event', async () => {
    const db = openDb(dbPath);
    lic('K3', 'c@x.com', 'monthly');
    insertChurnEvent(db, 'K3', 'set_status', 'expired', 1);
    db.close();

    const res = await callGet({ days: '7' });
    const json = await res.json();
    expect(json.totalChurned).toBe(1);
  });

  it('counts set_status to past_due as churn event', async () => {
    const db = openDb(dbPath);
    lic('K4', 'd@x.com', 'lifetime');
    insertChurnEvent(db, 'K4', 'set_status', 'past_due', 1);
    db.close();

    const res = await callGet({ days: '7' });
    const json = await res.json();
    expect(json.totalChurned).toBe(1);
  });

  it('does NOT count set_status to active as churn', async () => {
    const db = openDb(dbPath);
    lic('K5', 'e@x.com', 'monthly');
    insertChurnEvent(db, 'K5', 'set_status', 'active', 1);
    db.close();

    const res = await callGet({ days: '7' });
    const json = await res.json();
    expect(json.totalChurned).toBe(0);
  });

  it('does NOT count events outside the window', async () => {
    const db = openDb(dbPath);
    lic('K6', 'f@x.com', 'monthly');
    insertChurnEvent(db, 'K6', 'revoke', null, 35);
    db.close();

    const res = await callGet({ days: '30' });
    const json = await res.json();
    expect(json.totalChurned).toBe(0);
  });

  it('counts events on the boundary day', async () => {
    const db = openDb(dbPath);
    lic('K7', 'g@x.com', 'monthly');
    insertChurnEvent(db, 'K7', 'revoke', null, 29);
    db.close();

    const res = await callGet({ days: '30' });
    const json = await res.json();
    expect(json.totalChurned).toBe(1);
  });

  it('event lands in the correct daily bucket', async () => {
    const db = openDb(dbPath);
    lic('K8', 'h@x.com', 'monthly');
    insertChurnEvent(db, 'K8', 'revoke', null, 3);
    db.close();

    const res = await callGet({ days: '7' });
    const json = await res.json();
    const expectedDate = new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
    const bucket = json.buckets.find((b: any) => b.date === expectedDate);
    expect(bucket).toBeDefined();
    expect(bucket.churned).toBe(1);
  });

  it('zero-fills days with no churn events', async () => {
    const db = openDb(dbPath);
    lic('K9', 'i@x.com', 'monthly');
    insertChurnEvent(db, 'K9', 'revoke', null, 1);
    db.close();

    const res = await callGet({ days: '7' });
    const json = await res.json();
    const zeros = json.buckets.filter((b: any) => b.churned === 0);
    expect(zeros.length).toBe(6);
  });

  it('byPlan counts per plan correctly', async () => {
    const db = openDb(dbPath);
    lic('M1', 'j@x.com', 'monthly');
    lic('Y1', 'k@x.com', 'yearly');
    lic('Y2', 'l@x.com', 'yearly');
    insertChurnEvent(db, 'M1', 'revoke', null, 1);
    insertChurnEvent(db, 'Y1', 'set_status', 'canceled', 1);
    insertChurnEvent(db, 'Y2', 'revoke', null, 2);
    db.close();

    const res = await callGet({ days: '7' });
    const json = await res.json();
    expect(json.byPlan.monthly).toBe(1);
    expect(json.byPlan.yearly).toBe(2);
    expect(json.byPlan.lifetime).toBe(0);
    expect(json.totalChurned).toBe(3);
  });

  it('churnRate = totalChurned / (totalChurned + activeNow) * 100', async () => {
    const db = openDb(dbPath);
    // 1 active license, 1 churned → rate = 1/(1+1)*100 = 50%
    lic('A1', 'm@x.com', 'monthly');      // stays active
    lic('C1', 'n@x.com', 'monthly');      // will churn
    // Mirror real revoke flow: update status AND write audit event.
    db.prepare("UPDATE licenses SET status = 'canceled' WHERE key = ?").run('C1');
    insertChurnEvent(db, 'C1', 'revoke', null, 1);
    db.close();

    const res = await callGet({ days: '7' });
    const json = await res.json();
    expect(json.churnRate).toBe(50);
  });

  it('churnRate is 0 when no churn events', async () => {
    lic('A2', 'o@x.com', 'monthly');

    const res = await callGet({ days: '7' });
    const json = await res.json();
    expect(json.churnRate).toBe(0);
  });
});

// ─── Plan filter ──────────────────────────────────────────────────────────────

describe('GET /api/admin/churn-analysis — plan filter', () => {
  it('monthly filter excludes yearly churn events', async () => {
    const db = openDb(dbPath);
    lic('M2', 'p@x.com', 'monthly');
    lic('Y3', 'q@x.com', 'yearly');
    insertChurnEvent(db, 'M2', 'revoke', null, 1);
    insertChurnEvent(db, 'Y3', 'revoke', null, 1);
    db.close();

    const res = await callGet({ days: '7', plan: 'monthly' });
    const json = await res.json();
    expect(json.totalChurned).toBe(1);
    expect(json.byPlan.monthly).toBe(1);
    expect(json.byPlan.yearly).toBe(0);
  });

  it('yearly filter returns only yearly churn', async () => {
    const db = openDb(dbPath);
    lic('M3', 'r@x.com', 'monthly');
    lic('Y4', 's@x.com', 'yearly');
    insertChurnEvent(db, 'M3', 'revoke', null, 1);
    insertChurnEvent(db, 'Y4', 'set_status', 'canceled', 1);
    db.close();

    const res = await callGet({ days: '7', plan: 'yearly' });
    const json = await res.json();
    expect(json.totalChurned).toBe(1);
    expect(json.byPlan.yearly).toBe(1);
    expect(json.byPlan.monthly).toBe(0);
  });

  it('lifetime filter returns 0 when only monthly/yearly churn', async () => {
    const db = openDb(dbPath);
    lic('M4', 't@x.com', 'monthly');
    insertChurnEvent(db, 'M4', 'revoke', null, 1);
    db.close();

    const res = await callGet({ days: '7', plan: 'lifetime' });
    const json = await res.json();
    expect(json.totalChurned).toBe(0);
  });

  it('no filter returns all plans combined', async () => {
    const db = openDb(dbPath);
    lic('M5', 'u@x.com', 'monthly');
    lic('Y5', 'v@x.com', 'yearly');
    lic('L1', 'w@x.com', 'lifetime');
    insertChurnEvent(db, 'M5', 'revoke', null, 1);
    insertChurnEvent(db, 'Y5', 'revoke', null, 1);
    insertChurnEvent(db, 'L1', 'set_status', 'expired', 1);
    db.close();

    const res = await callGet({ days: '7' });
    const json = await res.json();
    expect(json.totalChurned).toBe(3);
  });
});
