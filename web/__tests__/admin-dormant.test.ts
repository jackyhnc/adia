// Tests for GET /api/admin/dormant
// Returns licenses that HAVE at least one activation but where every machine's
// last_seen is older than `days` days, ordered by most-recently-seen DESC.
// Supports ?days=, ?plan=, ?status=, ?format=csv

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import Database from 'better-sqlite3';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, recordActivation, setStatus, setNote } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

// Helper to back-date an activation's last_seen by N days so we can construct
// dormant scenarios without actually waiting.
function backdateActivation(db: Database.Database, licenseKey: string, machineHash: string, daysAgo: number) {
  const ts = new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000).toISOString();
  db.prepare('UPDATE activations SET last_seen = ?, first_seen = ? WHERE license_key = ? AND machine_hash = ?')
    .run(ts, ts, licenseKey, machineHash);
}

function openDb(p: string) { return new Database(p); }

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(
    os.tmpdir(),
    `adia-dormant-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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
  const { GET } = await import('@/app/api/admin/dormant/route');
  const sp = new URLSearchParams(params);
  const req = new NextRequest(`http://localhost/api/admin/dormant?${sp}`, {
    method: 'GET',
    headers: authHeader(token),
  });
  return GET(req);
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('GET /api/admin/dormant — auth', () => {
  it('returns 401 with no authorization header', async () => {
    const { GET } = await import('@/app/api/admin/dormant/route');
    const req = new NextRequest('http://localhost/api/admin/dormant');
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callGet({}, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query-param auth', async () => {
    const { GET } = await import('@/app/api/admin/dormant/route');
    const req = new NextRequest('http://localhost/api/admin/dormant?token=test-admin-token');
    const res = await GET(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ───────────────────────────────────────────────────────────────

describe('GET /api/admin/dormant — validation', () => {
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

describe('GET /api/admin/dormant — core', () => {
  it('returns empty list when no licenses exist', async () => {
    const res = await callGet({ days: '30' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(0);
    expect(body.licenses).toEqual([]);
    expect(body.days).toBe(30);
  });

  it('excludes a license with no activations (never-activated, not dormant)', async () => {
    insertLicense({ key: 'ADIA-DORM-NACT-0001', email: 'nact@example.com', plan: 'monthly', expiresAt: null });
    const res = await callGet({ days: '30' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(0);
  });

  it('excludes a license with a recent activation (not dormant)', async () => {
    insertLicense({ key: 'ADIA-DORM-REC-0001', email: 'rec@example.com', plan: 'monthly', expiresAt: null });
    recordActivation('ADIA-DORM-REC-0001', 'abc123');
    // last_seen is NOW — not dormant under 30-day window
    const res = await callGet({ days: '30' });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).not.toContain('ADIA-DORM-REC-0001');
  });

  it('returns a license whose activation is older than the window', async () => {
    insertLicense({ key: 'ADIA-DORM-OLD-0001', email: 'old@example.com', plan: 'monthly', expiresAt: null });
    recordActivation('ADIA-DORM-OLD-0001', 'abc123');
    const rawDb = openDb(dbPath);
    backdateActivation(rawDb, 'ADIA-DORM-OLD-0001', 'abc123', 45);
    rawDb.close();

    const res = await callGet({ days: '30' });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-DORM-OLD-0001');
  });

  it('returns machineCount and lastSeen in each row', async () => {
    insertLicense({ key: 'ADIA-DORM-SHPE-0001', email: 'shape@example.com', plan: 'monthly', expiresAt: null });
    recordActivation('ADIA-DORM-SHPE-0001', 'mac1');
    const rawDb = openDb(dbPath);
    backdateActivation(rawDb, 'ADIA-DORM-SHPE-0001', 'mac1', 60);
    rawDb.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    expect(body.count).toBe(1);
    const l = body.licenses[0];
    expect(l).toHaveProperty('key', 'ADIA-DORM-SHPE-0001');
    expect(l).toHaveProperty('email', 'shape@example.com');
    expect(l).toHaveProperty('plan', 'monthly');
    expect(l).toHaveProperty('status', 'active');
    expect(l).toHaveProperty('issuedAt');
    expect(l).toHaveProperty('machineCount', 1);
    expect(l).toHaveProperty('lastSeen');
    expect(typeof l.lastSeen).toBe('string');
  });

  it('response includes licenses, count, and days fields', async () => {
    const res = await callGet({ days: '14' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('licenses');
    expect(body).toHaveProperty('count');
    expect(body).toHaveProperty('days', 14);
    expect(Array.isArray(body.licenses)).toBe(true);
    expect(typeof body.count).toBe('number');
  });

  it('uses 30 days as default when days param is omitted', async () => {
    const res = await callGet();
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.days).toBe(30);
  });

  it('a license with one dormant + one recent machine is NOT dormant (MAX last_seen is recent)', async () => {
    insertLicense({ key: 'ADIA-DORM-MIX-0001', email: 'mix@example.com', plan: 'monthly', expiresAt: null });
    recordActivation('ADIA-DORM-MIX-0001', 'old-mac');
    recordActivation('ADIA-DORM-MIX-0001', 'new-mac');
    const rawDb = openDb(dbPath);
    backdateActivation(rawDb, 'ADIA-DORM-MIX-0001', 'old-mac', 90);
    // new-mac stays at NOW
    rawDb.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).not.toContain('ADIA-DORM-MIX-0001');
  });

  it('orders results by lastSeen DESC — most recently seen first', async () => {
    // Two dormant licenses; one was last seen 90 days ago, one 45 days ago.
    // The 45-day-old one should appear first.
    insertLicense({ key: 'ADIA-DORM-ORD-0001', email: 'ord1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-DORM-ORD-0002', email: 'ord2@example.com', plan: 'monthly', expiresAt: null });
    recordActivation('ADIA-DORM-ORD-0001', 'mac-a');
    recordActivation('ADIA-DORM-ORD-0002', 'mac-b');
    const rawDb = openDb(dbPath);
    backdateActivation(rawDb, 'ADIA-DORM-ORD-0001', 'mac-a', 90);
    backdateActivation(rawDb, 'ADIA-DORM-ORD-0002', 'mac-b', 45);
    rawDb.close();

    const res = await callGet({ days: '30' });
    const body = await res.json();
    expect(body.count).toBe(2);
    // 45-days-ago is more recent than 90-days-ago, so ORD-0002 comes first
    expect(body.licenses[0].key).toBe('ADIA-DORM-ORD-0002');
    expect(body.licenses[1].key).toBe('ADIA-DORM-ORD-0001');
  });
});

// ─── Plan filter ──────────────────────────────────────────────────────────────

describe('GET /api/admin/dormant — plan filter', () => {
  it('filters to monthly plan only', async () => {
    insertLicense({ key: 'ADIA-DORM-PLN-M001', email: 'plnm@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-DORM-PLN-Y001', email: 'plny@example.com', plan: 'yearly', expiresAt: null });
    recordActivation('ADIA-DORM-PLN-M001', 'mac1');
    recordActivation('ADIA-DORM-PLN-Y001', 'mac2');
    const rawDb = openDb(dbPath);
    backdateActivation(rawDb, 'ADIA-DORM-PLN-M001', 'mac1', 60);
    backdateActivation(rawDb, 'ADIA-DORM-PLN-Y001', 'mac2', 60);
    rawDb.close();

    const res = await callGet({ days: '30', plan: 'monthly' });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-DORM-PLN-M001');
    expect(keys).not.toContain('ADIA-DORM-PLN-Y001');
  });

  it('filters to lifetime plan only', async () => {
    insertLicense({ key: 'ADIA-DORM-LIFE-0001', email: 'life@example.com', plan: 'lifetime', expiresAt: null });
    insertLicense({ key: 'ADIA-DORM-LIFE-0002', email: 'lifem@example.com', plan: 'monthly', expiresAt: null });
    recordActivation('ADIA-DORM-LIFE-0001', 'mac1');
    recordActivation('ADIA-DORM-LIFE-0002', 'mac2');
    const rawDb = openDb(dbPath);
    backdateActivation(rawDb, 'ADIA-DORM-LIFE-0001', 'mac1', 60);
    backdateActivation(rawDb, 'ADIA-DORM-LIFE-0002', 'mac2', 60);
    rawDb.close();

    const res = await callGet({ days: '30', plan: 'lifetime' });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-DORM-LIFE-0001');
    expect(keys).not.toContain('ADIA-DORM-LIFE-0002');
  });
});

// ─── Status filter ────────────────────────────────────────────────────────────

describe('GET /api/admin/dormant — status filter', () => {
  it('returns all statuses when status param omitted', async () => {
    insertLicense({ key: 'ADIA-DORM-STS-0001', email: 'sts1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-DORM-STS-0002', email: 'sts2@example.com', plan: 'monthly', expiresAt: null });
    setStatus('ADIA-DORM-STS-0002', 'canceled');
    recordActivation('ADIA-DORM-STS-0001', 'mac1');
    recordActivation('ADIA-DORM-STS-0002', 'mac2');
    const rawDb = openDb(dbPath);
    backdateActivation(rawDb, 'ADIA-DORM-STS-0001', 'mac1', 60);
    backdateActivation(rawDb, 'ADIA-DORM-STS-0002', 'mac2', 60);
    rawDb.close();

    const res = await callGet({ days: '30' });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-DORM-STS-0001');
    expect(keys).toContain('ADIA-DORM-STS-0002');
  });

  it('filters to active-only when status=active', async () => {
    insertLicense({ key: 'ADIA-DORM-STA-0001', email: 'sta1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-DORM-STA-0002', email: 'sta2@example.com', plan: 'monthly', expiresAt: null });
    setStatus('ADIA-DORM-STA-0002', 'canceled');
    recordActivation('ADIA-DORM-STA-0001', 'mac1');
    recordActivation('ADIA-DORM-STA-0002', 'mac2');
    const rawDb = openDb(dbPath);
    backdateActivation(rawDb, 'ADIA-DORM-STA-0001', 'mac1', 60);
    backdateActivation(rawDb, 'ADIA-DORM-STA-0002', 'mac2', 60);
    rawDb.close();

    const res = await callGet({ days: '30', status: 'active' });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-DORM-STA-0001');
    expect(keys).not.toContain('ADIA-DORM-STA-0002');
  });

  it('filters to canceled-only when status=canceled', async () => {
    insertLicense({ key: 'ADIA-DORM-CNC-0001', email: 'cnc1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-DORM-CNC-0002', email: 'cnc2@example.com', plan: 'monthly', expiresAt: null });
    setStatus('ADIA-DORM-CNC-0002', 'canceled');
    recordActivation('ADIA-DORM-CNC-0001', 'mac1');
    recordActivation('ADIA-DORM-CNC-0002', 'mac2');
    const rawDb = openDb(dbPath);
    backdateActivation(rawDb, 'ADIA-DORM-CNC-0001', 'mac1', 60);
    backdateActivation(rawDb, 'ADIA-DORM-CNC-0002', 'mac2', 60);
    rawDb.close();

    const res = await callGet({ days: '30', status: 'canceled' });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).not.toContain('ADIA-DORM-CNC-0001');
    expect(keys).toContain('ADIA-DORM-CNC-0002');
  });
});

// ─── Days window ──────────────────────────────────────────────────────────────

describe('GET /api/admin/dormant — days window', () => {
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

  it('a license dormant for exactly 45 days appears under days=30 but not days=60', async () => {
    insertLicense({ key: 'ADIA-DORM-WIN-0001', email: 'win@example.com', plan: 'monthly', expiresAt: null });
    recordActivation('ADIA-DORM-WIN-0001', 'mac1');
    const rawDb = openDb(dbPath);
    backdateActivation(rawDb, 'ADIA-DORM-WIN-0001', 'mac1', 45);
    rawDb.close();

    const res30 = await callGet({ days: '30' });
    const body30 = await res30.json();
    expect(body30.licenses.map((l: { key: string }) => l.key)).toContain('ADIA-DORM-WIN-0001');

    const res60 = await callGet({ days: '60' });
    const body60 = await res60.json();
    expect(body60.licenses.map((l: { key: string }) => l.key)).not.toContain('ADIA-DORM-WIN-0001');
  });
});

// ─── CSV format ───────────────────────────────────────────────────────────────

describe('GET /api/admin/dormant — CSV', () => {
  it('returns CSV content-type with format=csv', async () => {
    const res = await callGet({ format: 'csv' });
    expect(res.headers.get('content-type')).toMatch(/text\/csv/);
  });

  it('CSV Content-Disposition has a .csv filename', async () => {
    const res = await callGet({ format: 'csv' });
    const cd = res.headers.get('content-disposition') ?? '';
    expect(cd).toMatch(/attachment.*\.csv/);
  });

  it('CSV has correct header row including lastSeen column', async () => {
    const res = await callGet({ format: 'csv' });
    const text = await res.text();
    expect(text.split('\n')[0]).toBe('key,email,plan,status,issuedAt,machineCount,lastSeen,note');
  });

  it('CSV includes a matching row for a dormant license', async () => {
    insertLicense({ key: 'ADIA-DORM-CSV-0001', email: 'csv@example.com', plan: 'monthly', expiresAt: null });
    recordActivation('ADIA-DORM-CSV-0001', 'mac1');
    const rawDb = openDb(dbPath);
    backdateActivation(rawDb, 'ADIA-DORM-CSV-0001', 'mac1', 60);
    rawDb.close();

    const res = await callGet({ days: '30', format: 'csv' });
    const text = await res.text();
    expect(text).toContain('ADIA-DORM-CSV-0001');
    expect(text).toContain('csv@example.com');
  });

  it('CSV escapes commas and quotes in note field', async () => {
    insertLicense({ key: 'ADIA-DORM-ESC-0001', email: 'esc@example.com', plan: 'monthly', expiresAt: null });
    recordActivation('ADIA-DORM-ESC-0001', 'mac1');
    const rawDb = openDb(dbPath);
    backdateActivation(rawDb, 'ADIA-DORM-ESC-0001', 'mac1', 60);
    rawDb.close();
    setNote('ADIA-DORM-ESC-0001', 'has, comma and "quote"');

    const res = await callGet({ days: '30', format: 'csv' });
    const text = await res.text();
    expect(text).toContain('"has, comma and ""quote"""');
  });
});

// ─── Rate limit ───────────────────────────────────────────────────────────────

describe('GET /api/admin/dormant — rate limit', () => {
  it('returns 429 after 20 requests from the same IP', async () => {
    const { GET } = await import('@/app/api/admin/dormant/route');
    const ip = '10.95.1.1';
    let lastStatus = 0;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/dormant', {
        method: 'GET',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
      });
      const res = await GET(req);
      lastStatus = res.status;
    }
    expect(lastStatus).toBe(429);
  });

  it('429 response includes Retry-After header', async () => {
    const { GET } = await import('@/app/api/admin/dormant/route');
    const ip = '10.95.1.2';
    let lastRes: Response | null = null;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/dormant', {
        method: 'GET',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
      });
      lastRes = await GET(req);
    }
    expect(lastRes?.headers.get('Retry-After')).toBeTruthy();
  });

  it('rate limit fires before auth check — wrong token still gets 429 when bucket exhausted', async () => {
    const { GET } = await import('@/app/api/admin/dormant/route');
    const ip = '10.95.1.3';
    for (let i = 0; i < 20; i++) {
      const req = new NextRequest('http://localhost/api/admin/dormant', {
        method: 'GET',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
      });
      await GET(req);
    }
    const req = new NextRequest('http://localhost/api/admin/dormant', {
      method: 'GET',
      headers: { Authorization: 'Bearer wrong-token', 'x-forwarded-for': ip },
    });
    const res = await GET(req);
    expect(res.status).toBe(429);
  });
});
