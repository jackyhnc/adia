// Tests for GET /api/admin/cohort-retention
// Groups licenses by issuance date; returns per-day cohort rows and 30/60/90d summary stats.
// Each cohort row: { date, total, activeNow, ageDays, retentionRate }.
// Supports ?days= (default 90, max 365) and ?plan= filters.

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import Database from 'better-sqlite3';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, setStatus } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

function openDb(p: string) { return new Database(p); }

// Backdate a license's issued_at to `daysAgo` days before now (UTC noon).
function backdateLicense(db: Database.Database, key: string, daysAgo: number) {
  const d = new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000);
  d.setUTCHours(12, 0, 0, 0);
  db.prepare('UPDATE licenses SET issued_at = ? WHERE key = ?').run(d.toISOString(), key);
}

// Helper: insert a license with the required expiresAt field.
function lic(key: string, email: string, plan: 'monthly' | 'yearly' | 'lifetime' = 'monthly') {
  insertLicense({ key, email, plan, expiresAt: null });
}

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(
    os.tmpdir(),
    `adia-cohort-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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
  const { GET } = await import('@/app/api/admin/cohort-retention/route');
  const sp = new URLSearchParams(params);
  const req = new NextRequest(`http://localhost/api/admin/cohort-retention?${sp}`, {
    method: 'GET',
    headers: authHeader(token),
  });
  return GET(req);
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('GET /api/admin/cohort-retention — auth', () => {
  it('returns 401 with no authorization header', async () => {
    const { GET } = await import('@/app/api/admin/cohort-retention/route');
    const req = new NextRequest('http://localhost/api/admin/cohort-retention');
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callGet({}, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query-param auth', async () => {
    const { GET } = await import('@/app/api/admin/cohort-retention/route');
    const req = new NextRequest('http://localhost/api/admin/cohort-retention?token=test-admin-token');
    const res = await GET(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ───────────────────────────────────────────────────────────────

describe('GET /api/admin/cohort-retention — validation', () => {
  it('returns 400 for days=0', async () => {
    const res = await callGet({ days: '0' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/days/i);
  });

  it('returns 400 for days=366 (exceeds max)', async () => {
    const res = await callGet({ days: '366' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/days/i);
  });

  it('returns 400 for non-integer days', async () => {
    const res = await callGet({ days: 'abc' });
    expect(res.status).toBe(400);
  });

  it('returns 400 for fractional days', async () => {
    const res = await callGet({ days: '7.5' });
    expect(res.status).toBe(400);
  });

  it('returns 400 for invalid plan', async () => {
    const res = await callGet({ plan: 'bogus' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/plan/i);
  });
});

// ─── Response shape ───────────────────────────────────────────────────────────

describe('GET /api/admin/cohort-retention — response shape', () => {
  it('returns 200 on empty DB', async () => {
    const res = await callGet({ days: '30' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(Array.isArray(body.cohorts)).toBe(true);
    expect(body.windowDays).toBe(30);
  });

  it('returns empty cohorts array on empty DB', async () => {
    const res = await callGet({ days: '7' });
    const body = await res.json();
    expect(body.cohorts).toHaveLength(0);
  });

  it('defaults to 90-day window', async () => {
    const res = await callGet();
    const body = await res.json();
    expect(body.windowDays).toBe(90);
  });

  it('all summary fields are null on empty DB', async () => {
    const res = await callGet();
    const body = await res.json();
    expect(body.summary30d).toBeNull();
    expect(body.summary60d).toBeNull();
    expect(body.summary90d).toBeNull();
  });

  it('cohort row has correct shape', async () => {
    const raw = openDb(dbPath);
    lic('SHAPE-1', 'a@test.com');
    backdateLicense(raw, 'SHAPE-1', 5);
    raw.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    expect(body.cohorts.length).toBeGreaterThan(0);
    const c = body.cohorts[0];
    expect(typeof c.date).toBe('string');
    expect(c.date).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    expect(typeof c.total).toBe('number');
    expect(typeof c.activeNow).toBe('number');
    expect(typeof c.ageDays).toBe('number');
    expect(typeof c.retentionRate).toBe('number');
  });

  it('does not include plan in response when not filtered', async () => {
    const res = await callGet({ days: '7' });
    const body = await res.json();
    expect(body.plan).toBeUndefined();
  });

  it('includes plan in response when filtered', async () => {
    const res = await callGet({ days: '7', plan: 'monthly' });
    const body = await res.json();
    expect(body.plan).toBe('monthly');
  });

  it('accepts days=1 (minimum valid)', async () => {
    const res = await callGet({ days: '1' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.windowDays).toBe(1);
  });

  it('accepts days=365 (maximum valid)', async () => {
    const res = await callGet({ days: '365' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.windowDays).toBe(365);
  });
});

// ─── Core behavior ────────────────────────────────────────────────────────────

describe('GET /api/admin/cohort-retention — core behavior', () => {
  it('groups licenses by issuance date into cohorts', async () => {
    const raw = openDb(dbPath);
    lic('GRP-1', 'a@test.com');
    lic('GRP-2', 'b@test.com');
    backdateLicense(raw, 'GRP-1', 10);
    backdateLicense(raw, 'GRP-2', 10); // same day as GRP-1
    raw.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    expect(body.cohorts).toHaveLength(1);
    expect(body.cohorts[0].total).toBe(2);
  });

  it('counts active licenses in activeNow', async () => {
    const raw = openDb(dbPath);
    lic('ACT-1', 'a@test.com');
    backdateLicense(raw, 'ACT-1', 5);
    raw.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    expect(body.cohorts[0].activeNow).toBe(1);
  });

  it('does not count canceled licenses in activeNow', async () => {
    const raw = openDb(dbPath);
    lic('CAN-1', 'a@test.com');
    setStatus('CAN-1', 'canceled');
    backdateLicense(raw, 'CAN-1', 5);
    raw.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    expect(body.cohorts[0].activeNow).toBe(0);
    expect(body.cohorts[0].total).toBe(1);
  });

  it('does not count expired licenses in activeNow', async () => {
    const raw = openDb(dbPath);
    lic('EXP-1', 'a@test.com');
    setStatus('EXP-1', 'expired');
    backdateLicense(raw, 'EXP-1', 5);
    raw.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    expect(body.cohorts[0].activeNow).toBe(0);
  });

  it('does not count past_due licenses in activeNow', async () => {
    const raw = openDb(dbPath);
    lic('PD-1', 'a@test.com');
    setStatus('PD-1', 'past_due');
    backdateLicense(raw, 'PD-1', 5);
    raw.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    expect(body.cohorts[0].activeNow).toBe(0);
    expect(body.cohorts[0].total).toBe(1);
  });

  it('computes retentionRate as activeNow/total*100 rounded to 1dp', async () => {
    const raw = openDb(dbPath);
    lic('RT-1', 'a@test.com');
    lic('RT-2', 'b@test.com');
    lic('RT-3', 'c@test.com');
    setStatus('RT-3', 'canceled');
    backdateLicense(raw, 'RT-1', 10);
    backdateLicense(raw, 'RT-2', 10);
    backdateLicense(raw, 'RT-3', 10);
    raw.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    // 2 active / 3 total = 66.666... → 66.7%
    expect(body.cohorts[0].retentionRate).toBeCloseTo(66.7, 0);
  });

  it('cohorts are in ascending date order (oldest first)', async () => {
    const raw = openDb(dbPath);
    lic('ORD-1', 'a@test.com');
    lic('ORD-2', 'b@test.com');
    backdateLicense(raw, 'ORD-1', 20);
    backdateLicense(raw, 'ORD-2', 5);
    raw.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    expect(body.cohorts.length).toBeGreaterThan(1);
    for (let i = 1; i < body.cohorts.length; i++) {
      expect(body.cohorts[i].date >= body.cohorts[i - 1].date).toBe(true);
    }
  });

  it('excludes licenses issued before the window', async () => {
    const raw = openDb(dbPath);
    lic('WIN-1', 'a@test.com');
    backdateLicense(raw, 'WIN-1', 40); // outside 30-day window
    raw.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    expect(body.cohorts).toHaveLength(0);
  });

  it('includes licenses issued within the window', async () => {
    const raw = openDb(dbPath);
    lic('EDGE-1', 'a@test.com');
    backdateLicense(raw, 'EDGE-1', 29); // within 30-day window
    raw.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    expect(body.cohorts.length).toBeGreaterThan(0);
  });

  it('ageDays reflects days since cohort date', async () => {
    const raw = openDb(dbPath);
    lic('AGE-1', 'a@test.com');
    backdateLicense(raw, 'AGE-1', 15);
    raw.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    expect(body.cohorts[0].ageDays).toBeGreaterThanOrEqual(14);
    expect(body.cohorts[0].ageDays).toBeLessThanOrEqual(16);
  });
});

// ─── Summary stats ────────────────────────────────────────────────────────────

describe('GET /api/admin/cohort-retention — summary stats', () => {
  it('summary30d is null when no cohorts are >= 30 days old', async () => {
    const raw = openDb(dbPath);
    lic('S30-1', 'a@test.com');
    backdateLicense(raw, 'S30-1', 10); // only 10 days old
    raw.close();

    const res = await callGet({ days: '60' });
    const body = await res.json();
    expect(body.summary30d).toBeNull();
  });

  it('summary30d is populated when cohorts >= 30 days old exist', async () => {
    const raw = openDb(dbPath);
    lic('S30-2', 'a@test.com');
    backdateLicense(raw, 'S30-2', 35);
    raw.close();

    const res = await callGet({ days: '90' });
    const body = await res.json();
    expect(body.summary30d).not.toBeNull();
    expect(body.summary30d.cohortCount).toBe(1);
    expect(body.summary30d.totalLicenses).toBe(1);
    expect(body.summary30d.activeCount).toBe(1);
    expect(body.summary30d.rate).toBe(100);
  });

  it('summary60d excludes cohorts < 60 days old', async () => {
    const raw = openDb(dbPath);
    lic('S60-1', 'a@test.com');
    lic('S60-2', 'b@test.com');
    backdateLicense(raw, 'S60-1', 35); // old enough for 30d, not 60d
    backdateLicense(raw, 'S60-2', 65); // old enough for 60d
    raw.close();

    const res = await callGet({ days: '120' });
    const body = await res.json();
    expect(body.summary60d).not.toBeNull();
    expect(body.summary60d.cohortCount).toBe(1); // only S60-2's cohort
    expect(body.summary60d.totalLicenses).toBe(1);
  });

  it('summary90d is null when no cohorts >= 90 days old in window', async () => {
    const raw = openDb(dbPath);
    lic('S90-1', 'a@test.com');
    backdateLicense(raw, 'S90-1', 60);
    raw.close();

    const res = await callGet({ days: '90' });
    const body = await res.json();
    expect(body.summary90d).toBeNull();
  });

  it('summary stats aggregate across multiple cohort dates', async () => {
    const raw = openDb(dbPath);
    lic('AGG-1', 'a@test.com');
    lic('AGG-2', 'b@test.com');
    setStatus('AGG-2', 'canceled');
    backdateLicense(raw, 'AGG-1', 32);
    backdateLicense(raw, 'AGG-2', 38);
    raw.close();

    const res = await callGet({ days: '90' });
    const body = await res.json();
    expect(body.summary30d.cohortCount).toBe(2);
    expect(body.summary30d.totalLicenses).toBe(2);
    expect(body.summary30d.activeCount).toBe(1);
    expect(body.summary30d.rate).toBe(50);
  });
});

// ─── Plan filter ──────────────────────────────────────────────────────────────

describe('GET /api/admin/cohort-retention — plan filter', () => {
  it('filters to monthly only', async () => {
    const raw = openDb(dbPath);
    lic('PLN-M', 'a@test.com', 'monthly');
    lic('PLN-Y', 'b@test.com', 'yearly');
    backdateLicense(raw, 'PLN-M', 5);
    backdateLicense(raw, 'PLN-Y', 5);
    raw.close();

    const res = await callGet({ days: '30', plan: 'monthly' });
    const body = await res.json();
    expect(body.cohorts[0].total).toBe(1);
  });

  it('filters to yearly only', async () => {
    const raw = openDb(dbPath);
    lic('PLN-M2', 'a@test.com', 'monthly');
    lic('PLN-Y2', 'b@test.com', 'yearly');
    backdateLicense(raw, 'PLN-M2', 5);
    backdateLicense(raw, 'PLN-Y2', 5);
    raw.close();

    const res = await callGet({ days: '30', plan: 'yearly' });
    const body = await res.json();
    expect(body.cohorts[0].total).toBe(1);
  });

  it('returns empty cohorts when plan filter matches nothing', async () => {
    const raw = openDb(dbPath);
    lic('PLN-LT', 'a@test.com', 'monthly');
    backdateLicense(raw, 'PLN-LT', 5);
    raw.close();

    const res = await callGet({ days: '30', plan: 'lifetime' });
    const body = await res.json();
    expect(body.cohorts).toHaveLength(0);
  });

  it('no filter returns all plans', async () => {
    const raw = openDb(dbPath);
    lic('ALL-M', 'a@test.com', 'monthly');
    lic('ALL-Y', 'b@test.com', 'yearly');
    lic('ALL-L', 'c@test.com', 'lifetime');
    backdateLicense(raw, 'ALL-M', 5);
    backdateLicense(raw, 'ALL-Y', 5);
    backdateLicense(raw, 'ALL-L', 5);
    raw.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    expect(body.cohorts[0].total).toBe(3);
  });
});

// ─── Rate limit ───────────────────────────────────────────────────────────────

describe('GET /api/admin/cohort-retention — rate limit', () => {
  it('returns 429 after 20 requests from the same IP', async () => {
    const { GET } = await import('@/app/api/admin/cohort-retention/route');
    const makeReq = () =>
      new NextRequest('http://localhost/api/admin/cohort-retention', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer test-admin-token',
          'x-forwarded-for': '10.91.5.1',
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
    const { GET } = await import('@/app/api/admin/cohort-retention/route');
    const makeReq = () =>
      new NextRequest('http://localhost/api/admin/cohort-retention', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer test-admin-token',
          'x-forwarded-for': '10.91.5.2',
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
    const { GET } = await import('@/app/api/admin/cohort-retention/route');
    const goodReq = () =>
      new NextRequest('http://localhost/api/admin/cohort-retention', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer test-admin-token',
          'x-forwarded-for': '10.91.5.3',
        },
      });
    const badReq = () =>
      new NextRequest('http://localhost/api/admin/cohort-retention', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer wrong-token',
          'x-forwarded-for': '10.91.5.3',
        },
      });

    for (let i = 0; i < 20; i++) {
      await GET(goodReq());
    }

    const res = await GET(badReq());
    expect(res.status).toBe(429);
  });
});
