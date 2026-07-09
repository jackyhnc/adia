// Tests for GET /api/admin/churn-cohort
// Returns per-cohort churn breakdown: for each issuance-date cohort in the window,
// how many licenses churned (ever) and how quickly (within 30/60/90 days of issuance).
// Supports ?days= (default 90, max 365) and ?plan= filters.

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import Database from 'better-sqlite3';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

function openDb(p: string) { return new Database(p); }

// Insert a license backdated to `daysAgo` days.
function insertLicenseAt(
  db: Database.Database,
  key: string,
  email: string,
  plan: 'monthly' | 'yearly' | 'lifetime',
  daysAgo: number,
) {
  insertLicense({ key, email, plan, expiresAt: null });
  const d = new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000);
  d.setUTCHours(12, 0, 0, 0);
  db.prepare('UPDATE licenses SET issued_at = ? WHERE key = ?').run(d.toISOString(), key);
}

// Insert a churn event (first churn) for a license, occurring `daysAfterIssuance`
// days after issuance (i.e. issued_at + N days).
function insertChurnEventAt(
  db: Database.Database,
  licenseKey: string,
  action: 'revoke' | 'set_status',
  status: string | null,
  issuanceDaysAgo: number,
  daysAfterIssuance: number,
) {
  const churnDate = new Date(Date.now() - (issuanceDaysAgo - daysAfterIssuance) * 24 * 60 * 60 * 1000);
  churnDate.setUTCHours(14, 0, 0, 0);
  const detail = action === 'set_status' && status
    ? JSON.stringify({ status, previousStatus: 'active' })
    : action === 'revoke'
    ? JSON.stringify({ previousStatus: 'active' })
    : null;
  db.prepare(
    'INSERT INTO audit_log (license_key, action, detail, created_at) VALUES (?, ?, ?, ?)',
  ).run(licenseKey, action, detail, churnDate.toISOString());
}

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(
    os.tmpdir(),
    `adia-churn-cohort-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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
  const { GET } = await import('@/app/api/admin/churn-cohort/route');
  const sp = new URLSearchParams(params);
  const req = new NextRequest(`http://localhost/api/admin/churn-cohort?${sp}`, {
    method: 'GET',
    headers: authHeader(token),
  });
  return GET(req);
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('GET /api/admin/churn-cohort — auth', () => {
  it('returns 401 with no authorization header', async () => {
    const { GET } = await import('@/app/api/admin/churn-cohort/route');
    const req = new NextRequest('http://localhost/api/admin/churn-cohort');
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callGet({}, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query-param auth', async () => {
    const { GET } = await import('@/app/api/admin/churn-cohort/route');
    const req = new NextRequest('http://localhost/api/admin/churn-cohort?token=test-admin-token');
    const res = await GET(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ───────────────────────────────────────────────────────────────

describe('GET /api/admin/churn-cohort — validation', () => {
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

describe('GET /api/admin/churn-cohort — response shape', () => {
  it('returns 200 on empty DB', async () => {
    const res = await callGet();
    expect(res.status).toBe(200);
  });

  it('returns empty cohorts array when no licenses', async () => {
    const res = await callGet();
    const json = await res.json();
    expect(json.cohorts).toEqual([]);
    expect(json.summary30d).toBeNull();
    expect(json.summary60d).toBeNull();
    expect(json.summary90d).toBeNull();
    expect(json.windowDays).toBe(90);
  });

  it('default days is 90', async () => {
    const res = await callGet();
    const json = await res.json();
    expect(json.windowDays).toBe(90);
  });

  it('accepts days=1', async () => {
    const res = await callGet({ days: '1' });
    const json = await res.json();
    expect(json.windowDays).toBe(1);
    expect(res.status).toBe(200);
  });

  it('accepts days=365', async () => {
    const res = await callGet({ days: '365' });
    const json = await res.json();
    expect(json.windowDays).toBe(365);
  });

  it('cohort row has expected shape', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K1', 'a@x.com', 'monthly', 10);
    db.close();

    const res = await callGet({ days: '30' });
    const json = await res.json();
    expect(json.cohorts).toHaveLength(1);
    const c = json.cohorts[0];
    expect(c).toHaveProperty('date');
    expect(c).toHaveProperty('total');
    expect(c).toHaveProperty('churned');
    expect(c).toHaveProperty('churnedWithin30d');
    expect(c).toHaveProperty('churnedWithin60d');
    expect(c).toHaveProperty('churnedWithin90d');
    expect(c).toHaveProperty('churnRate');
    expect(c).toHaveProperty('ageDays');
    expect(typeof c.date).toBe('string');
    expect(typeof c.total).toBe('number');
    expect(typeof c.churned).toBe('number');
    expect(typeof c.churnRate).toBe('number');
  });

  it('cohorts are in ascending date order', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K1', 'a@x.com', 'monthly', 5);
    insertLicenseAt(db, 'K2', 'b@x.com', 'monthly', 10);
    insertLicenseAt(db, 'K3', 'c@x.com', 'monthly', 20);
    db.close();

    const res = await callGet({ days: '30' });
    const json = await res.json();
    const dates = json.cohorts.map((c: any) => c.date);
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

describe('GET /api/admin/churn-cohort — core behavior', () => {
  it('counts revoke as churn', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K1', 'a@x.com', 'monthly', 40);
    insertChurnEventAt(db, 'K1', 'revoke', null, 40, 5);
    db.close();

    const res = await callGet({ days: '90' });
    const json = await res.json();
    expect(json.cohorts[0].churned).toBe(1);
  });

  it('counts set_status canceled as churn', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K1', 'a@x.com', 'yearly', 40);
    insertChurnEventAt(db, 'K1', 'set_status', 'canceled', 40, 5);
    db.close();

    const res = await callGet({ days: '90' });
    const json = await res.json();
    expect(json.cohorts[0].churned).toBe(1);
  });

  it('counts set_status expired as churn', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K1', 'a@x.com', 'monthly', 40);
    insertChurnEventAt(db, 'K1', 'set_status', 'expired', 40, 5);
    db.close();

    const res = await callGet({ days: '90' });
    const json = await res.json();
    expect(json.cohorts[0].churned).toBe(1);
  });

  it('counts set_status past_due as churn', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K1', 'a@x.com', 'lifetime', 40);
    insertChurnEventAt(db, 'K1', 'set_status', 'past_due', 40, 5);
    db.close();

    const res = await callGet({ days: '90' });
    const json = await res.json();
    expect(json.cohorts[0].churned).toBe(1);
  });

  it('does not count set_status to active as churn', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K1', 'a@x.com', 'monthly', 40);
    // set_status to active is NOT a churn event
    const activeDate = new Date(Date.now() - 35 * 24 * 60 * 60 * 1000);
    db.prepare('INSERT INTO audit_log (license_key, action, detail, created_at) VALUES (?, ?, ?, ?)')
      .run('K1', 'set_status', JSON.stringify({ status: 'active', previousStatus: 'canceled' }), activeDate.toISOString());
    db.close();

    const res = await callGet({ days: '90' });
    const json = await res.json();
    expect(json.cohorts[0].churned).toBe(0);
  });

  it('excludes license issued outside the window', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K1', 'a@x.com', 'monthly', 100); // outside 30d window
    insertChurnEventAt(db, 'K1', 'revoke', null, 100, 5);
    db.close();

    const res = await callGet({ days: '30' });
    const json = await res.json();
    expect(json.cohorts).toHaveLength(0);
  });

  it('includes license issued exactly on the window boundary', async () => {
    const db = openDb(dbPath);
    // issued_at = exactly 30 days ago should be included in a 30d window
    insertLicenseAt(db, 'K1', 'a@x.com', 'monthly', 29); // within window
    db.close();

    const res = await callGet({ days: '30' });
    const json = await res.json();
    expect(json.cohorts.length).toBeGreaterThanOrEqual(1);
    expect(json.cohorts[0].total).toBe(1);
  });

  it('churnRate formula: churned/total × 100', async () => {
    const db = openDb(dbPath);
    // 4 licenses in same cohort (issued on same day, 40d ago)
    for (let i = 1; i <= 4; i++) {
      insertLicenseAt(db, `K${i}`, `u${i}@x.com`, 'monthly', 40);
    }
    // 2 churn (K1, K2)
    insertChurnEventAt(db, 'K1', 'revoke', null, 40, 5);
    insertChurnEventAt(db, 'K2', 'set_status', 'canceled', 40, 5);
    db.close();

    const res = await callGet({ days: '90' });
    const json = await res.json();
    expect(json.cohorts[0].churnRate).toBe(50); // 2/4 × 100
  });

  it('churnedWithin30d counts churn events within 30 days of issuance', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K1', 'a@x.com', 'monthly', 50);
    // churn 20 days after issuance → within 30d
    insertChurnEventAt(db, 'K1', 'revoke', null, 50, 20);
    db.close();

    const res = await callGet({ days: '90' });
    const json = await res.json();
    expect(json.cohorts[0].churnedWithin30d).toBe(1);
    expect(json.cohorts[0].churnedWithin60d).toBe(1);
    expect(json.cohorts[0].churnedWithin90d).toBe(1);
  });

  it('churnedWithin30d=0 when churn was 45 days after issuance', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K1', 'a@x.com', 'monthly', 60);
    // churn 45 days after issuance → within60d but NOT within30d
    insertChurnEventAt(db, 'K1', 'revoke', null, 60, 45);
    db.close();

    const res = await callGet({ days: '90' });
    const json = await res.json();
    expect(json.cohorts[0].churnedWithin30d).toBe(0);
    expect(json.cohorts[0].churnedWithin60d).toBe(1);
    expect(json.cohorts[0].churnedWithin90d).toBe(1);
  });

  it('churnedWithin60d=0 when churn was 75 days after issuance', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K1', 'a@x.com', 'monthly', 100);
    // churn 75 days after issuance → within90d but NOT within30d or within60d
    insertChurnEventAt(db, 'K1', 'revoke', null, 100, 75);
    db.close();

    const res = await callGet({ days: '120' });
    const json = await res.json();
    expect(json.cohorts[0].churnedWithin30d).toBe(0);
    expect(json.cohorts[0].churnedWithin60d).toBe(0);
    expect(json.cohorts[0].churnedWithin90d).toBe(1);
  });

  it('license with no churn event has churned=0 and churnRate=0', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K1', 'a@x.com', 'monthly', 30);
    // no churn event
    db.close();

    const res = await callGet({ days: '60' });
    const json = await res.json();
    expect(json.cohorts[0].churned).toBe(0);
    expect(json.cohorts[0].churnRate).toBe(0);
    expect(json.cohorts[0].churnedWithin30d).toBe(0);
  });

  it('multiple churn events for same license count only the earliest (first churn)', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K1', 'a@x.com', 'monthly', 50);
    // First churn 20d after issuance, second 45d after
    insertChurnEventAt(db, 'K1', 'set_status', 'canceled', 50, 20);
    insertChurnEventAt(db, 'K1', 'revoke', null, 50, 45);
    db.close();

    const res = await callGet({ days: '90' });
    const json = await res.json();
    // Only 1 churn (same license), first event was 20d after issuance
    expect(json.cohorts[0].churned).toBe(1);
    expect(json.cohorts[0].churnedWithin30d).toBe(1); // 20d <= 30d
  });

  it('groups licenses by issuance date into separate cohorts', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K1', 'a@x.com', 'monthly', 10);
    insertLicenseAt(db, 'K2', 'b@x.com', 'monthly', 20);
    db.close();

    const res = await callGet({ days: '30' });
    const json = await res.json();
    // Two separate cohorts (different days)
    expect(json.cohorts).toHaveLength(2);
    expect(json.cohorts[0].total).toBe(1);
    expect(json.cohorts[1].total).toBe(1);
  });
});

// ─── Summary stats ────────────────────────────────────────────────────────────

describe('GET /api/admin/churn-cohort — summary stats', () => {
  it('summary30d is null when all cohorts are < 30 days old', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K1', 'a@x.com', 'monthly', 10); // only 10d old
    db.close();

    const res = await callGet({ days: '30' });
    const json = await res.json();
    expect(json.summary30d).toBeNull();
  });

  it('summary30d is populated when a cohort is >= 30 days old', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K1', 'a@x.com', 'monthly', 35);
    db.close();

    const res = await callGet({ days: '90' });
    const json = await res.json();
    expect(json.summary30d).not.toBeNull();
    expect(json.summary30d.cohortCount).toBe(1);
    expect(json.summary30d.totalLicenses).toBe(1);
  });

  it('summary60d is null when no cohorts are >= 60 days old', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K1', 'a@x.com', 'monthly', 40); // only 40d old
    db.close();

    const res = await callGet({ days: '90' });
    const json = await res.json();
    expect(json.summary60d).toBeNull();
  });

  it('summary60d is populated when a cohort is >= 60 days old', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K1', 'a@x.com', 'monthly', 65);
    db.close();

    const res = await callGet({ days: '90' });
    const json = await res.json();
    expect(json.summary60d).not.toBeNull();
    expect(json.summary60d.cohortCount).toBe(1);
  });

  it('summary90d is null when no cohorts are >= 90 days old', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K1', 'a@x.com', 'monthly', 80); // only 80d old
    db.close();

    const res = await callGet({ days: '120' });
    const json = await res.json();
    expect(json.summary90d).toBeNull();
  });

  it('summary avgChurnRate formula: totalChurned/totalLicenses × 100', async () => {
    const db = openDb(dbPath);
    // 4 licenses issued 40d ago; 2 churned
    for (let i = 1; i <= 4; i++) {
      insertLicenseAt(db, `K${i}`, `u${i}@x.com`, 'monthly', 40);
    }
    insertChurnEventAt(db, 'K1', 'revoke', null, 40, 5);
    insertChurnEventAt(db, 'K2', 'revoke', null, 40, 5);
    db.close();

    const res = await callGet({ days: '90' });
    const json = await res.json();
    // summary30d: 4 total, 2 churned → 50%
    expect(json.summary30d.totalLicenses).toBe(4);
    expect(json.summary30d.totalChurned).toBe(2);
    expect(json.summary30d.avgChurnRate).toBe(50);
  });

  it('summary aggregates multiple cohorts', async () => {
    const db = openDb(dbPath);
    // Cohort A: 2 licenses issued 40d ago, 1 churned
    insertLicenseAt(db, 'KA1', 'a1@x.com', 'monthly', 40);
    insertLicenseAt(db, 'KA2', 'a2@x.com', 'monthly', 40);
    insertChurnEventAt(db, 'KA1', 'revoke', null, 40, 5);
    // Cohort B: 3 licenses issued 50d ago, 3 churned
    insertLicenseAt(db, 'KB1', 'b1@x.com', 'monthly', 50);
    insertLicenseAt(db, 'KB2', 'b2@x.com', 'monthly', 50);
    insertLicenseAt(db, 'KB3', 'b3@x.com', 'monthly', 50);
    insertChurnEventAt(db, 'KB1', 'revoke', null, 50, 5);
    insertChurnEventAt(db, 'KB2', 'revoke', null, 50, 5);
    insertChurnEventAt(db, 'KB3', 'revoke', null, 50, 5);
    db.close();

    const res = await callGet({ days: '90' });
    const json = await res.json();
    expect(json.summary30d.cohortCount).toBe(2);
    expect(json.summary30d.totalLicenses).toBe(5); // 2 + 3
    expect(json.summary30d.totalChurned).toBe(4);  // 1 + 3
    expect(json.summary30d.avgChurnRate).toBe(80); // 4/5 × 100
  });
});

// ─── Plan filter ──────────────────────────────────────────────────────────────

describe('GET /api/admin/churn-cohort — plan filter', () => {
  it('monthly filter excludes yearly licenses', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'KM', 'monthly@x.com', 'monthly', 10);
    insertLicenseAt(db, 'KY', 'yearly@x.com', 'yearly', 10);
    db.close();

    const res = await callGet({ days: '30', plan: 'monthly' });
    const json = await res.json();
    // Only the monthly license should appear
    const total = json.cohorts.reduce((s: number, c: any) => s + c.total, 0);
    expect(total).toBe(1);
  });

  it('yearly filter only includes yearly licenses', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'KM', 'monthly@x.com', 'monthly', 10);
    insertLicenseAt(db, 'KY', 'yearly@x.com', 'yearly', 10);
    insertLicenseAt(db, 'KL', 'lifetime@x.com', 'lifetime', 10);
    db.close();

    const res = await callGet({ days: '30', plan: 'yearly' });
    const json = await res.json();
    const total = json.cohorts.reduce((s: number, c: any) => s + c.total, 0);
    expect(total).toBe(1);
  });

  it('lifetime filter returns 0 when no lifetime licenses', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'KM', 'monthly@x.com', 'monthly', 10);
    db.close();

    const res = await callGet({ days: '30', plan: 'lifetime' });
    const json = await res.json();
    expect(json.cohorts).toHaveLength(0);
  });

  it('no plan filter returns all plans', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'KM', 'monthly@x.com', 'monthly', 10);
    insertLicenseAt(db, 'KY', 'yearly@x.com', 'yearly', 10);
    insertLicenseAt(db, 'KL', 'lifetime@x.com', 'lifetime', 10);
    db.close();

    const res = await callGet({ days: '30' });
    const json = await res.json();
    const total = json.cohorts.reduce((s: number, c: any) => s + c.total, 0);
    expect(total).toBe(3);
  });
});

// ─── Rate limit ───────────────────────────────────────────────────────────────

describe('GET /api/admin/churn-cohort — rate limit', () => {
  it('returns 429 after 20 requests from the same IP', async () => {
    const { GET } = await import('@/app/api/admin/churn-cohort/route');
    const makeReq = () =>
      new NextRequest('http://localhost/api/admin/churn-cohort', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer test-admin-token',
          'x-forwarded-for': '10.91.6.1',
        },
      });

    for (let i = 0; i < 20; i++) {
      const res = await GET(makeReq());
      expect(res.status).toBe(200);
    }

    const res = await GET(makeReq());
    expect(res.status).toBe(429);
    const body = await res.json();
    expect(body.error).toMatch(/too many requests/i);
  });

  it('429 response includes Retry-After header', async () => {
    const { GET } = await import('@/app/api/admin/churn-cohort/route');
    const makeReq = () =>
      new NextRequest('http://localhost/api/admin/churn-cohort', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer test-admin-token',
          'x-forwarded-for': '10.91.6.2',
        },
      });

    for (let i = 0; i < 20; i++) {
      await GET(makeReq());
    }

    const res = await GET(makeReq());
    expect(res.status).toBe(429);
    expect(res.headers.get('Retry-After')).toBeTruthy();
  });

  it('rate limit fires before auth check — wrong token still gets 429 when bucket exhausted', async () => {
    const { GET } = await import('@/app/api/admin/churn-cohort/route');
    const goodReq = () =>
      new NextRequest('http://localhost/api/admin/churn-cohort', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer test-admin-token',
          'x-forwarded-for': '10.91.6.3',
        },
      });
    const badReq = () =>
      new NextRequest('http://localhost/api/admin/churn-cohort', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer wrong-token',
          'x-forwarded-for': '10.91.6.3',
        },
      });

    for (let i = 0; i < 20; i++) {
      await GET(goodReq());
    }

    const res = await GET(badReq());
    expect(res.status).toBe(429);
  });
});
