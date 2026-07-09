// Tests for GET /api/admin/time-to-churn
// Returns histogram of days-from-issuance to first churn event, in four buckets:
//   0-7d (early), 8-30d (mid), 31-90d (late), 91d+ (very late)
// Includes medianDays, meanDays, totalChurned, windowDays.
// Supports ?days= (default 365, max 365) and ?plan= filters.

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

// Insert a churn audit-log event for a license that was issued `issuanceDaysAgo`
// days ago, and the churn event occurred `daysAfterIssuance` days after issuance.
function insertChurnEvent(
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
    : JSON.stringify({ previousStatus: 'active' });
  db.prepare(
    'INSERT INTO audit_log (license_key, action, detail, created_at) VALUES (?, ?, ?, ?)',
  ).run(licenseKey, action, detail, churnDate.toISOString());
}

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(
    os.tmpdir(),
    `adia-ttc-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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
  const { GET } = await import('@/app/api/admin/time-to-churn/route');
  const sp = new URLSearchParams(params);
  const req = new NextRequest(`http://localhost/api/admin/time-to-churn?${sp}`, {
    method: 'GET',
    headers: authHeader(token),
  });
  return GET(req);
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('GET /api/admin/time-to-churn — auth', () => {
  it('returns 401 with no authorization header', async () => {
    const { GET } = await import('@/app/api/admin/time-to-churn/route');
    const req = new NextRequest('http://localhost/api/admin/time-to-churn');
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callGet({}, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query-param auth', async () => {
    const { GET } = await import('@/app/api/admin/time-to-churn/route');
    const req = new NextRequest('http://localhost/api/admin/time-to-churn?token=test-admin-token');
    const res = await GET(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ───────────────────────────────────────────────────────────────

describe('GET /api/admin/time-to-churn — validation', () => {
  it('rejects days=0', async () => {
    const res = await callGet({ days: '0' });
    expect(res.status).toBe(400);
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
    const res = await callGet({ days: '30.5' });
    expect(res.status).toBe(400);
  });

  it('rejects invalid plan', async () => {
    const res = await callGet({ plan: 'premium' });
    expect(res.status).toBe(400);
  });
});

// ─── Response shape ───────────────────────────────────────────────────────────

describe('GET /api/admin/time-to-churn — response shape', () => {
  it('returns 200 on empty DB', async () => {
    const res = await callGet();
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.buckets).toHaveLength(4);
    expect(body.totalChurned).toBe(0);
    expect(body.medianDays).toBeNull();
    expect(body.meanDays).toBeNull();
  });

  it('returns four buckets with correct labels', async () => {
    const res = await callGet();
    const body = await res.json();
    const labels = body.buckets.map((b: any) => b.label);
    expect(labels).toEqual(['0-7d', '8-30d', '31-90d', '91d+']);
  });

  it('each bucket has required fields', async () => {
    const res = await callGet();
    const body = await res.json();
    for (const b of body.buckets) {
      expect(typeof b.label).toBe('string');
      expect(typeof b.minDays).toBe('number');
      expect(typeof b.count).toBe('number');
      expect(typeof b.pct).toBe('number');
      expect('maxDays' in b).toBe(true);
    }
  });

  it('last bucket has maxDays=null', async () => {
    const res = await callGet();
    const body = await res.json();
    expect(body.buckets[3].maxDays).toBeNull();
  });

  it('uses default days=365', async () => {
    const res = await callGet();
    const body = await res.json();
    expect(body.windowDays).toBe(365);
  });

  it('respects days=30', async () => {
    const res = await callGet({ days: '30' });
    const body = await res.json();
    expect(body.windowDays).toBe(30);
  });

  it('accepts days=365', async () => {
    const res = await callGet({ days: '365' });
    expect(res.status).toBe(200);
  });

  it('plan field absent when no plan filter', async () => {
    const res = await callGet();
    const body = await res.json();
    expect(body.plan).toBeUndefined();
  });

  it('plan field present when plan filter set', async () => {
    const res = await callGet({ plan: 'monthly' });
    const body = await res.json();
    expect(body.plan).toBe('monthly');
  });
});

// ─── Core behavior ────────────────────────────────────────────────────────────

describe('GET /api/admin/time-to-churn — core behavior', () => {
  it('counts revoke events', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-R1', 'u1@x.com', 'monthly', 100);
    insertChurnEvent(db, 'K-R1', 'revoke', null, 100, 3);
    db.close();

    const res = await callGet();
    const body = await res.json();
    expect(body.totalChurned).toBe(1);
    expect(body.buckets[0].count).toBe(1); // 0-7d
  });

  it('counts set_status canceled', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-SC', 'u2@x.com', 'monthly', 100);
    insertChurnEvent(db, 'K-SC', 'set_status', 'canceled', 100, 10);
    db.close();

    const res = await callGet();
    const body = await res.json();
    expect(body.totalChurned).toBe(1);
    expect(body.buckets[1].count).toBe(1); // 8-30d
  });

  it('counts set_status expired', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-SE', 'u3@x.com', 'monthly', 100);
    insertChurnEvent(db, 'K-SE', 'set_status', 'expired', 100, 45);
    db.close();

    const res = await callGet();
    const body = await res.json();
    expect(body.totalChurned).toBe(1);
    expect(body.buckets[2].count).toBe(1); // 31-90d
  });

  it('counts set_status past_due', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-PD', 'u4@x.com', 'monthly', 100);
    insertChurnEvent(db, 'K-PD', 'set_status', 'past_due', 100, 120);
    db.close();

    const res = await callGet();
    const body = await res.json();
    expect(body.totalChurned).toBe(1);
    expect(body.buckets[3].count).toBe(1); // 91d+
  });

  it('does NOT count set_status active', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-A', 'u5@x.com', 'monthly', 100);
    insertChurnEvent(db, 'K-A', 'set_status', 'active', 100, 5);
    db.close();

    const res = await callGet();
    const body = await res.json();
    expect(body.totalChurned).toBe(0);
  });

  it('excludes licenses issued outside the window', async () => {
    const db = openDb(dbPath);
    // Issued 400 days ago — outside the 365-day default window
    insertLicenseAt(db, 'K-OLD', 'old@x.com', 'monthly', 400);
    insertChurnEvent(db, 'K-OLD', 'revoke', null, 400, 5);
    db.close();

    const res = await callGet({ days: '365' });
    const body = await res.json();
    expect(body.totalChurned).toBe(0);
  });

  it('includes license issued exactly at the window boundary', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-EDGE', 'edge@x.com', 'monthly', 365);
    insertChurnEvent(db, 'K-EDGE', 'revoke', null, 365, 1);
    db.close();

    const res = await callGet({ days: '365' });
    const body = await res.json();
    expect(body.totalChurned).toBe(1);
  });

  it('uses only the first churn event per license', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-M', 'multi@x.com', 'monthly', 100);
    // First event at day 3 (early bucket), second at day 50 (late bucket)
    insertChurnEvent(db, 'K-M', 'revoke', null, 100, 3);
    insertChurnEvent(db, 'K-M', 'set_status', 'canceled', 100, 50);
    db.close();

    const res = await callGet();
    const body = await res.json();
    expect(body.totalChurned).toBe(1);
    expect(body.buckets[0].count).toBe(1); // day 3 → 0-7d
    expect(body.buckets[2].count).toBe(0); // day 50 not counted
  });

  it('places day-0 churn in 0-7d bucket', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-D0', 'd0@x.com', 'monthly', 50);
    insertChurnEvent(db, 'K-D0', 'revoke', null, 50, 0);
    db.close();

    const res = await callGet();
    const body = await res.json();
    expect(body.buckets[0].count).toBe(1);
  });

  it('places day-7 churn in 0-7d bucket', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-D7', 'd7@x.com', 'monthly', 50);
    insertChurnEvent(db, 'K-D7', 'revoke', null, 50, 7);
    db.close();

    const res = await callGet();
    const body = await res.json();
    expect(body.buckets[0].count).toBe(1);
  });

  it('places day-8 churn in 8-30d bucket', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-D8', 'd8@x.com', 'monthly', 50);
    insertChurnEvent(db, 'K-D8', 'revoke', null, 50, 8);
    db.close();

    const res = await callGet();
    const body = await res.json();
    expect(body.buckets[1].count).toBe(1);
  });

  it('places day-30 churn in 8-30d bucket', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-D30', 'd30@x.com', 'monthly', 50);
    insertChurnEvent(db, 'K-D30', 'revoke', null, 50, 30);
    db.close();

    const res = await callGet();
    const body = await res.json();
    expect(body.buckets[1].count).toBe(1);
  });

  it('places day-31 churn in 31-90d bucket', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-D31', 'd31@x.com', 'monthly', 100);
    insertChurnEvent(db, 'K-D31', 'revoke', null, 100, 31);
    db.close();

    const res = await callGet();
    const body = await res.json();
    expect(body.buckets[2].count).toBe(1);
  });

  it('places day-91 churn in 91d+ bucket', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-D91', 'd91@x.com', 'monthly', 200);
    insertChurnEvent(db, 'K-D91', 'revoke', null, 200, 91);
    db.close();

    const res = await callGet();
    const body = await res.json();
    expect(body.buckets[3].count).toBe(1);
  });
});

// ─── Pct + stats ──────────────────────────────────────────────────────────────

describe('GET /api/admin/time-to-churn — pct and stats', () => {
  it('pct sums to 100 when all churned in one bucket', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-P1', 'p1@x.com', 'monthly', 50);
    insertChurnEvent(db, 'K-P1', 'revoke', null, 50, 3);
    insertLicenseAt(db, 'K-P2', 'p2@x.com', 'monthly', 50);
    insertChurnEvent(db, 'K-P2', 'revoke', null, 50, 5);
    db.close();

    const res = await callGet();
    const body = await res.json();
    expect(body.buckets[0].pct).toBe(100);
    expect(body.buckets[1].pct).toBe(0);
  });

  it('pct is 50 for each of two equal buckets', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-H1', 'h1@x.com', 'monthly', 50);
    insertChurnEvent(db, 'K-H1', 'revoke', null, 50, 3);    // 0-7d
    insertLicenseAt(db, 'K-H2', 'h2@x.com', 'monthly', 50);
    insertChurnEvent(db, 'K-H2', 'revoke', null, 50, 120);  // 91d+
    db.close();

    const res = await callGet();
    const body = await res.json();
    expect(body.buckets[0].pct).toBe(50);
    expect(body.buckets[3].pct).toBe(50);
  });

  it('medianDays correct for odd count', async () => {
    // Days: [3, 10, 50] → sorted → median = 10
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-M1', 'm1@x.com', 'monthly', 100);
    insertChurnEvent(db, 'K-M1', 'revoke', null, 100, 3);
    insertLicenseAt(db, 'K-M2', 'm2@x.com', 'monthly', 100);
    insertChurnEvent(db, 'K-M2', 'revoke', null, 100, 10);
    insertLicenseAt(db, 'K-M3', 'm3@x.com', 'monthly', 100);
    insertChurnEvent(db, 'K-M3', 'revoke', null, 100, 50);
    db.close();

    const res = await callGet();
    const body = await res.json();
    expect(body.medianDays).toBe(10);
  });

  it('medianDays is average of two middle values for even count', async () => {
    // Days: [3, 10] → median = (3+10)/2 = 6.5
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-E1', 'e1@x.com', 'monthly', 50);
    insertChurnEvent(db, 'K-E1', 'revoke', null, 50, 3);
    insertLicenseAt(db, 'K-E2', 'e2@x.com', 'monthly', 50);
    insertChurnEvent(db, 'K-E2', 'revoke', null, 50, 10);
    db.close();

    const res = await callGet();
    const body = await res.json();
    expect(body.medianDays).toBe(6.5);
  });

  it('meanDays correct', async () => {
    // Days: [0, 10, 20] → mean = 30/3 = 10
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-N1', 'n1@x.com', 'monthly', 50);
    insertChurnEvent(db, 'K-N1', 'revoke', null, 50, 0);
    insertLicenseAt(db, 'K-N2', 'n2@x.com', 'monthly', 50);
    insertChurnEvent(db, 'K-N2', 'revoke', null, 50, 10);
    insertLicenseAt(db, 'K-N3', 'n3@x.com', 'monthly', 50);
    insertChurnEvent(db, 'K-N3', 'revoke', null, 50, 20);
    db.close();

    const res = await callGet();
    const body = await res.json();
    expect(body.meanDays).toBe(10);
  });

  it('medianDays and meanDays null when no churn events', async () => {
    const res = await callGet();
    const body = await res.json();
    expect(body.medianDays).toBeNull();
    expect(body.meanDays).toBeNull();
  });
});

// ─── Plan filter ──────────────────────────────────────────────────────────────

describe('GET /api/admin/time-to-churn — plan filter', () => {
  it('monthly filter excludes yearly churn', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-MO', 'mo@x.com', 'monthly', 50);
    insertChurnEvent(db, 'K-MO', 'revoke', null, 50, 3);
    insertLicenseAt(db, 'K-YR', 'yr@x.com', 'yearly', 50);
    insertChurnEvent(db, 'K-YR', 'revoke', null, 50, 5);
    db.close();

    const res = await callGet({ plan: 'monthly' });
    const body = await res.json();
    expect(body.totalChurned).toBe(1);
    expect(body.buckets[0].count).toBe(1);
  });

  it('yearly filter returns only yearly churn', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-MO2', 'mo2@x.com', 'monthly', 50);
    insertChurnEvent(db, 'K-MO2', 'revoke', null, 50, 3);
    insertLicenseAt(db, 'K-YR2', 'yr2@x.com', 'yearly', 50);
    insertChurnEvent(db, 'K-YR2', 'revoke', null, 50, 15);
    db.close();

    const res = await callGet({ plan: 'yearly' });
    const body = await res.json();
    expect(body.totalChurned).toBe(1);
    expect(body.buckets[1].count).toBe(1); // 15d → 8-30d
  });

  it('lifetime filter with no lifetime churn returns totalChurned=0', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-MO3', 'mo3@x.com', 'monthly', 50);
    insertChurnEvent(db, 'K-MO3', 'revoke', null, 50, 3);
    db.close();

    const res = await callGet({ plan: 'lifetime' });
    const body = await res.json();
    expect(body.totalChurned).toBe(0);
  });

  it('no filter returns all plans', async () => {
    const db = openDb(dbPath);
    insertLicenseAt(db, 'K-ALL1', 'all1@x.com', 'monthly', 50);
    insertChurnEvent(db, 'K-ALL1', 'revoke', null, 50, 3);
    insertLicenseAt(db, 'K-ALL2', 'all2@x.com', 'yearly', 50);
    insertChurnEvent(db, 'K-ALL2', 'revoke', null, 50, 50);
    insertLicenseAt(db, 'K-ALL3', 'all3@x.com', 'lifetime', 50);
    insertChurnEvent(db, 'K-ALL3', 'revoke', null, 50, 120);
    db.close();

    const res = await callGet();
    const body = await res.json();
    expect(body.totalChurned).toBe(3);
  });
});

// ─── Rate limit ───────────────────────────────────────────────────────────────

describe('GET /api/admin/time-to-churn — rate limit', () => {
  it('returns 429 after 20 requests from the same IP', async () => {
    const { GET } = await import('@/app/api/admin/time-to-churn/route');
    const makeReq = () =>
      new NextRequest('http://localhost/api/admin/time-to-churn', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer test-admin-token',
          'x-forwarded-for': '10.91.0.1',
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
    const { GET } = await import('@/app/api/admin/time-to-churn/route');
    const makeReq = () =>
      new NextRequest('http://localhost/api/admin/time-to-churn', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer test-admin-token',
          'x-forwarded-for': '10.91.0.2',
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
    const { GET } = await import('@/app/api/admin/time-to-churn/route');
    const goodReq = () =>
      new NextRequest('http://localhost/api/admin/time-to-churn', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer test-admin-token',
          'x-forwarded-for': '10.91.0.3',
        },
      });
    const badReq = () =>
      new NextRequest('http://localhost/api/admin/time-to-churn', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer wrong-token',
          'x-forwarded-for': '10.91.0.3',
        },
      });

    for (let i = 0; i < 20; i++) {
      await GET(goodReq());
    }

    const res = await GET(badReq());
    expect(res.status).toBe(429);
  });
});
