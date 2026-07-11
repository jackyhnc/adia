// Tests for GET /api/admin/dormant-churn
// Returns licenses that had ≥1 activation AND a churn event (revoke or
// set_status→canceled/expired/past_due) within the last `days` days.
// Supports ?days=, ?plan=, ?status=, ?format=csv

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import Database from 'better-sqlite3';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, recordActivation, setStatus } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

function openDb(p: string) { return new Database(p); }

// Insert a churn audit_log entry with a specific created_at timestamp.
function insertChurnEvent(
  db: Database.Database,
  licenseKey: string,
  action: 'revoke' | 'set_status',
  churnStatus: string | null,
  daysAgo: number,
) {
  const d = new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000);
  d.setUTCHours(12, 0, 0, 0);
  const detail = action === 'set_status' && churnStatus
    ? JSON.stringify({ status: churnStatus, previousStatus: 'active' })
    : JSON.stringify({ previousStatus: 'active' });
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
    `adia-dc-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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
  const { GET } = await import('@/app/api/admin/dormant-churn/route');
  const sp = new URLSearchParams(params);
  const req = new NextRequest(`http://localhost/api/admin/dormant-churn?${sp}`, {
    method: 'GET',
    headers: authHeader(token),
  });
  return GET(req);
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('GET /api/admin/dormant-churn — auth', () => {
  it('returns 401 with no authorization header', async () => {
    const { GET } = await import('@/app/api/admin/dormant-churn/route');
    const req = new NextRequest('http://localhost/api/admin/dormant-churn');
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callGet({}, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query-param auth', async () => {
    const { GET } = await import('@/app/api/admin/dormant-churn/route');
    const req = new NextRequest('http://localhost/api/admin/dormant-churn?token=test-admin-token');
    const res = await GET(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ───────────────────────────────────────────────────────────────

describe('GET /api/admin/dormant-churn — validation', () => {
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
    const res = await callGet({ plan: 'enterprise' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/plan/i);
  });

  it('returns 400 for invalid status', async () => {
    const res = await callGet({ status: 'banned' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/status/i);
  });

  it('returns 400 for invalid format', async () => {
    const res = await callGet({ format: 'xml' });
    expect(res.status).toBe(400);
  });
});

// ─── Core behaviour ──────────────────────────────────────────────────────────

describe('GET /api/admin/dormant-churn — core', () => {
  it('returns empty list when no licenses exist', async () => {
    const res = await callGet({ days: '30' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(0);
    expect(body.licenses).toEqual([]);
    expect(body.days).toBe(30);
  });

  it('uses 30 days as default when days param is omitted', async () => {
    const res = await callGet();
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.days).toBe(30);
  });

  it('returns a license with activation + revoke churn event', async () => {
    lic('ADIA-DC-REVO-0001', 'revo@example.com');
    recordActivation('ADIA-DC-REVO-0001', 'mac1');
    const rawDb = openDb(dbPath);
    insertChurnEvent(rawDb, 'ADIA-DC-REVO-0001', 'revoke', null, 5);
    rawDb.close();

    const res = await callGet({ days: '30' });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-DC-REVO-0001');
  });

  it('returns a license with activation + set_status=canceled churn event', async () => {
    lic('ADIA-DC-CNC-0001', 'cnc@example.com');
    recordActivation('ADIA-DC-CNC-0001', 'mac1');
    const rawDb = openDb(dbPath);
    insertChurnEvent(rawDb, 'ADIA-DC-CNC-0001', 'set_status', 'canceled', 5);
    rawDb.close();

    const res = await callGet({ days: '30' });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-DC-CNC-0001');
  });

  it('returns a license with activation + set_status=expired churn event', async () => {
    lic('ADIA-DC-EXP-0001', 'exp@example.com');
    recordActivation('ADIA-DC-EXP-0001', 'mac1');
    const rawDb = openDb(dbPath);
    insertChurnEvent(rawDb, 'ADIA-DC-EXP-0001', 'set_status', 'expired', 5);
    rawDb.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-DC-EXP-0001');
  });

  it('returns a license with activation + set_status=past_due churn event', async () => {
    lic('ADIA-DC-PDU-0001', 'pdu@example.com');
    recordActivation('ADIA-DC-PDU-0001', 'mac1');
    const rawDb = openDb(dbPath);
    insertChurnEvent(rawDb, 'ADIA-DC-PDU-0001', 'set_status', 'past_due', 5);
    rawDb.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-DC-PDU-0001');
  });

  it('excludes a license with no activations even if it has a churn event', async () => {
    lic('ADIA-DC-NOACT-0001', 'noact@example.com');
    const rawDb = openDb(dbPath);
    insertChurnEvent(rawDb, 'ADIA-DC-NOACT-0001', 'revoke', null, 5);
    rawDb.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).not.toContain('ADIA-DC-NOACT-0001');
  });

  it('excludes a license with activation but no churn event', async () => {
    lic('ADIA-DC-NOCH-0001', 'noch@example.com');
    recordActivation('ADIA-DC-NOCH-0001', 'mac1');

    const res = await callGet({ days: '30' });
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).not.toContain('ADIA-DC-NOCH-0001');
  });

  it('excludes set_status=active audit entry (not a churn event)', async () => {
    lic('ADIA-DC-REAC-0001', 'reac@example.com');
    recordActivation('ADIA-DC-REAC-0001', 'mac1');
    const rawDb = openDb(dbPath);
    // set_status active is a reactivation — NOT a churn event
    const ts = new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString();
    rawDb.prepare(
      'INSERT INTO audit_log (license_key, action, detail, created_at) VALUES (?, ?, ?, ?)',
    ).run('ADIA-DC-REAC-0001', 'set_status', JSON.stringify({ status: 'active' }), ts);
    rawDb.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).not.toContain('ADIA-DC-REAC-0001');
  });

  it('response shape includes licenses, count, and days fields', async () => {
    const res = await callGet({ days: '14' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('licenses');
    expect(body).toHaveProperty('count');
    expect(body).toHaveProperty('days', 14);
    expect(Array.isArray(body.licenses)).toBe(true);
    expect(typeof body.count).toBe('number');
  });

  it('each row includes key, email, plan, status, issuedAt, machineCount, and churnDate', async () => {
    lic('ADIA-DC-SHPE-0001', 'shape@example.com', 'yearly');
    recordActivation('ADIA-DC-SHPE-0001', 'mac1');
    recordActivation('ADIA-DC-SHPE-0001', 'mac2');
    const rawDb = openDb(dbPath);
    insertChurnEvent(rawDb, 'ADIA-DC-SHPE-0001', 'revoke', null, 3);
    rawDb.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    expect(body.count).toBe(1);
    const l = body.licenses[0];
    expect(l).toHaveProperty('key', 'ADIA-DC-SHPE-0001');
    expect(l).toHaveProperty('email', 'shape@example.com');
    expect(l).toHaveProperty('plan', 'yearly');
    expect(l).toHaveProperty('status', 'active');
    expect(l).toHaveProperty('issuedAt');
    expect(l).toHaveProperty('machineCount', 2);
    expect(l).toHaveProperty('churnDate');
    expect(typeof l.churnDate).toBe('string');
  });

  it('churnDate reflects the first churn event when there are multiple', async () => {
    lic('ADIA-DC-FCHURN-0001', 'first@example.com');
    recordActivation('ADIA-DC-FCHURN-0001', 'mac1');
    const rawDb = openDb(dbPath);
    // Two churn events — first was 20 days ago, second 5 days ago
    insertChurnEvent(rawDb, 'ADIA-DC-FCHURN-0001', 'revoke', null, 20);
    insertChurnEvent(rawDb, 'ADIA-DC-FCHURN-0001', 'set_status', 'canceled', 5);
    rawDb.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    const l = body.licenses.find((r: any) => r.key === 'ADIA-DC-FCHURN-0001');
    expect(l).toBeDefined();
    // churnDate should be the earlier of the two (20 days ago)
    const churnD = new Date(l.churnDate);
    const fiveDaysAgo = new Date(Date.now() - 5 * 24 * 60 * 60 * 1000);
    expect(churnD < fiveDaysAgo).toBe(true);
  });

  it('orders results by churnDate DESC — most recently churned first', async () => {
    lic('ADIA-DC-ORD-0001', 'ord1@example.com');
    lic('ADIA-DC-ORD-0002', 'ord2@example.com');
    recordActivation('ADIA-DC-ORD-0001', 'mac-a');
    recordActivation('ADIA-DC-ORD-0002', 'mac-b');
    const rawDb = openDb(dbPath);
    insertChurnEvent(rawDb, 'ADIA-DC-ORD-0001', 'revoke', null, 20); // churned 20 days ago
    insertChurnEvent(rawDb, 'ADIA-DC-ORD-0002', 'revoke', null, 5);  // churned 5 days ago
    rawDb.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    expect(body.count).toBe(2);
    // ORD-0002 (5 days ago) should appear first (more recent)
    expect(body.licenses[0].key).toBe('ADIA-DC-ORD-0002');
    expect(body.licenses[1].key).toBe('ADIA-DC-ORD-0001');
  });
});

// ─── Days window ──────────────────────────────────────────────────────────────

describe('GET /api/admin/dormant-churn — days window', () => {
  it('accepts days=365 (max)', async () => {
    const res = await callGet({ days: '365' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.days).toBe(365);
  });

  it('accepts days=1 (min)', async () => {
    const res = await callGet({ days: '1' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.days).toBe(1);
  });

  it('excludes a churn event outside the days window', async () => {
    lic('ADIA-DC-WIN-0001', 'win@example.com');
    recordActivation('ADIA-DC-WIN-0001', 'mac1');
    const rawDb = openDb(dbPath);
    // Churned 45 days ago — outside a 30-day window
    insertChurnEvent(rawDb, 'ADIA-DC-WIN-0001', 'revoke', null, 45);
    rawDb.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).not.toContain('ADIA-DC-WIN-0001');
  });

  it('includes a churn event within the days window', async () => {
    lic('ADIA-DC-WIN-0002', 'win2@example.com');
    recordActivation('ADIA-DC-WIN-0002', 'mac1');
    const rawDb = openDb(dbPath);
    // Churned 10 days ago — inside a 30-day window
    insertChurnEvent(rawDb, 'ADIA-DC-WIN-0002', 'revoke', null, 10);
    rawDb.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-DC-WIN-0002');
  });

  it('a license churned 45 days ago appears under days=60 but not days=30', async () => {
    lic('ADIA-DC-BWIN-0001', 'bwin@example.com');
    recordActivation('ADIA-DC-BWIN-0001', 'mac1');
    const rawDb = openDb(dbPath);
    insertChurnEvent(rawDb, 'ADIA-DC-BWIN-0001', 'revoke', null, 45);
    rawDb.close();

    const res30 = await callGet({ days: '30' });
    const body30 = await res30.json();
    expect(body30.licenses.map((l: { key: string }) => l.key)).not.toContain('ADIA-DC-BWIN-0001');

    const res60 = await callGet({ days: '60' });
    const body60 = await res60.json();
    expect(body60.licenses.map((l: { key: string }) => l.key)).toContain('ADIA-DC-BWIN-0001');
  });
});

// ─── Plan filter ──────────────────────────────────────────────────────────────

describe('GET /api/admin/dormant-churn — plan filter', () => {
  it('filters to monthly plan only', async () => {
    lic('ADIA-DC-PLN-M001', 'plnm@example.com', 'monthly');
    lic('ADIA-DC-PLN-Y001', 'plny@example.com', 'yearly');
    recordActivation('ADIA-DC-PLN-M001', 'mac1');
    recordActivation('ADIA-DC-PLN-Y001', 'mac2');
    const rawDb = openDb(dbPath);
    insertChurnEvent(rawDb, 'ADIA-DC-PLN-M001', 'revoke', null, 5);
    insertChurnEvent(rawDb, 'ADIA-DC-PLN-Y001', 'revoke', null, 5);
    rawDb.close();

    const res = await callGet({ days: '30', plan: 'monthly' });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-DC-PLN-M001');
    expect(keys).not.toContain('ADIA-DC-PLN-Y001');
  });

  it('filters to lifetime plan only', async () => {
    lic('ADIA-DC-PLN-L001', 'plnl@example.com', 'lifetime');
    lic('ADIA-DC-PLN-M002', 'plnm2@example.com', 'monthly');
    recordActivation('ADIA-DC-PLN-L001', 'mac1');
    recordActivation('ADIA-DC-PLN-M002', 'mac2');
    const rawDb = openDb(dbPath);
    insertChurnEvent(rawDb, 'ADIA-DC-PLN-L001', 'revoke', null, 5);
    insertChurnEvent(rawDb, 'ADIA-DC-PLN-M002', 'revoke', null, 5);
    rawDb.close();

    const res = await callGet({ days: '30', plan: 'lifetime' });
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-DC-PLN-L001');
    expect(keys).not.toContain('ADIA-DC-PLN-M002');
  });
});

// ─── Status filter ────────────────────────────────────────────────────────────

describe('GET /api/admin/dormant-churn — status filter', () => {
  it('returns all statuses when status param omitted', async () => {
    lic('ADIA-DC-STS-0001', 'sts1@example.com');
    lic('ADIA-DC-STS-0002', 'sts2@example.com');
    setStatus('ADIA-DC-STS-0002', 'canceled');
    recordActivation('ADIA-DC-STS-0001', 'mac1');
    recordActivation('ADIA-DC-STS-0002', 'mac2');
    const rawDb = openDb(dbPath);
    insertChurnEvent(rawDb, 'ADIA-DC-STS-0001', 'revoke', null, 5);
    insertChurnEvent(rawDb, 'ADIA-DC-STS-0002', 'set_status', 'canceled', 5);
    rawDb.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-DC-STS-0001');
    expect(keys).toContain('ADIA-DC-STS-0002');
  });

  it('filters to canceled-only when status=canceled', async () => {
    lic('ADIA-DC-STA-0001', 'sta1@example.com');
    lic('ADIA-DC-STA-0002', 'sta2@example.com');
    setStatus('ADIA-DC-STA-0002', 'canceled');
    recordActivation('ADIA-DC-STA-0001', 'mac1');
    recordActivation('ADIA-DC-STA-0002', 'mac2');
    const rawDb = openDb(dbPath);
    insertChurnEvent(rawDb, 'ADIA-DC-STA-0001', 'revoke', null, 5);
    insertChurnEvent(rawDb, 'ADIA-DC-STA-0002', 'revoke', null, 5);
    rawDb.close();

    const res = await callGet({ days: '30', status: 'canceled' });
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).not.toContain('ADIA-DC-STA-0001');
    expect(keys).toContain('ADIA-DC-STA-0002');
  });
});

// ─── CSV format ───────────────────────────────────────────────────────────────

describe('GET /api/admin/dormant-churn — CSV', () => {
  it('returns CSV content-type with format=csv', async () => {
    const res = await callGet({ format: 'csv' });
    expect(res.headers.get('content-type')).toMatch(/text\/csv/);
  });

  it('CSV Content-Disposition has a .csv filename containing "dormant-churn"', async () => {
    const res = await callGet({ format: 'csv' });
    const cd = res.headers.get('content-disposition') ?? '';
    expect(cd).toMatch(/attachment.*dormant-churn.*\.csv/);
  });

  it('CSV has correct header row with churnDate column', async () => {
    const res = await callGet({ format: 'csv' });
    const text = await res.text();
    expect(text.split('\n')[0]).toBe('key,email,plan,status,issuedAt,machineCount,churnDate,note');
  });

  it('CSV includes a matching data row for a dormant-churn license', async () => {
    lic('ADIA-DC-CSV-0001', 'csv@example.com');
    recordActivation('ADIA-DC-CSV-0001', 'mac1');
    const rawDb = openDb(dbPath);
    insertChurnEvent(rawDb, 'ADIA-DC-CSV-0001', 'revoke', null, 5);
    rawDb.close();

    const res = await callGet({ days: '30', format: 'csv' });
    const text = await res.text();
    expect(text).toContain('ADIA-DC-CSV-0001');
    expect(text).toContain('csv@example.com');
  });
});

// ─── Rate limit ───────────────────────────────────────────────────────────────

describe('GET /api/admin/dormant-churn — rate limit', () => {
  it('returns 429 after 20 requests from the same IP', async () => {
    const { GET } = await import('@/app/api/admin/dormant-churn/route');
    const ip = '10.92.1.1';
    let lastStatus = 0;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/dormant-churn', {
        method: 'GET',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
      });
      const res = await GET(req);
      lastStatus = res.status;
    }
    expect(lastStatus).toBe(429);
  });

  it('429 response includes Retry-After header', async () => {
    const { GET } = await import('@/app/api/admin/dormant-churn/route');
    const ip = '10.92.1.2';
    let lastRes: Response | null = null;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/dormant-churn', {
        method: 'GET',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
      });
      lastRes = await GET(req);
    }
    expect(lastRes?.headers.get('Retry-After')).toBeTruthy();
  });

  it('rate limit fires before auth check — wrong token still gets 429 when bucket exhausted', async () => {
    const { GET } = await import('@/app/api/admin/dormant-churn/route');
    const ip = '10.92.1.3';
    // Exhaust the bucket with valid token
    for (let i = 0; i < 20; i++) {
      const req = new NextRequest('http://localhost/api/admin/dormant-churn', {
        method: 'GET',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
      });
      await GET(req);
    }
    // Wrong token on 21st request — should get 429 not 401
    const req = new NextRequest('http://localhost/api/admin/dormant-churn', {
      method: 'GET',
      headers: { Authorization: 'Bearer wrong-token', 'x-forwarded-for': ip },
    });
    const res = await GET(req);
    expect(res.status).toBe(429);
  });

  it('rate limit fires before format-parse — ?format=csv gets 429 when bucket exhausted', async () => {
    const { GET } = await import('@/app/api/admin/dormant-churn/route');
    const ip = '10.92.1.4';
    // Exhaust the bucket with JSON requests
    for (let i = 0; i < 20; i++) {
      const req = new NextRequest('http://localhost/api/admin/dormant-churn', {
        method: 'GET',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
      });
      await GET(req);
    }
    // CSV request on 21st — should get 429, not a CSV response
    const csvReq = new NextRequest('http://localhost/api/admin/dormant-churn?format=csv', {
      method: 'GET',
      headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
    });
    const res = await GET(csvReq);
    expect(res.status).toBe(429);
    // Must not be a CSV response
    expect(res.headers.get('content-type')).not.toMatch(/text\/csv/);
  });
});
