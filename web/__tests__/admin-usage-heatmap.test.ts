// Tests for GET /api/admin/usage-heatmap
// Returns a 24-bucket array (hours 0–23) counting new activations by hour-of-day
// over the last N days. Supports ?days= and ?plan= filters.

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import Database from 'better-sqlite3';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, recordActivation } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

function openDb(p: string) { return new Database(p); }

// Set an activation's first_seen to a specific UTC hour and daysAgo in the past.
function backdateActivationFirstSeen(
  db: Database.Database,
  licenseKey: string,
  machineHash: string,
  daysAgo: number,
  utcHour: number,
) {
  const d = new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000);
  d.setUTCHours(utcHour, 0, 0, 0);
  const ts = d.toISOString();
  db.prepare('UPDATE activations SET first_seen = ? WHERE license_key = ? AND machine_hash = ?')
    .run(ts, licenseKey, machineHash);
}

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(
    os.tmpdir(),
    `adia-heatmap-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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
  const { GET } = await import('@/app/api/admin/usage-heatmap/route');
  const sp = new URLSearchParams(params);
  const req = new NextRequest(`http://localhost/api/admin/usage-heatmap?${sp}`, {
    method: 'GET',
    headers: authHeader(token),
  });
  return GET(req);
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('GET /api/admin/usage-heatmap — auth', () => {
  it('returns 401 with no authorization header', async () => {
    const { GET } = await import('@/app/api/admin/usage-heatmap/route');
    const req = new NextRequest('http://localhost/api/admin/usage-heatmap');
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callGet({}, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query-param auth', async () => {
    const { GET } = await import('@/app/api/admin/usage-heatmap/route');
    const req = new NextRequest('http://localhost/api/admin/usage-heatmap?token=test-admin-token');
    const res = await GET(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ───────────────────────────────────────────────────────────────

describe('GET /api/admin/usage-heatmap — validation', () => {
  it('returns 400 for days=0', async () => {
    const res = await callGet({ days: '0' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/days/i);
  });

  it('returns 400 for days=91 (exceeds max)', async () => {
    const res = await callGet({ days: '91' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/days/i);
  });

  it('returns 400 for non-integer days', async () => {
    const res = await callGet({ days: 'abc' });
    expect(res.status).toBe(400);
  });

  it('returns 400 for fractional days', async () => {
    const res = await callGet({ days: '3.5' });
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

describe('GET /api/admin/usage-heatmap — response shape', () => {
  it('returns 200 with 24-bucket array on empty DB', async () => {
    const res = await callGet({ days: '7' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.buckets).toHaveLength(24);
    expect(body.days).toBe(7);
    expect(body.total).toBe(0);
  });

  it('all buckets have hour 0–23 in order', async () => {
    const res = await callGet({ days: '7' });
    const body = await res.json();
    body.buckets.forEach((b: { hour: number; count: number }, i: number) => {
      expect(b.hour).toBe(i);
      expect(typeof b.count).toBe('number');
    });
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

  it('uses default days=7 when not specified', async () => {
    const res = await callGet();
    const body = await res.json();
    expect(body.days).toBe(7);
  });

  it('accepts days=1 (minimum valid)', async () => {
    const res = await callGet({ days: '1' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.days).toBe(1);
  });

  it('accepts days=90 (maximum valid)', async () => {
    const res = await callGet({ days: '90' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.days).toBe(90);
  });
});

// ─── Core behavior ────────────────────────────────────────────────────────────

describe('GET /api/admin/usage-heatmap — core behavior', () => {
  it('counts an activation in the correct hour bucket', async () => {
    insertLicense({ key: 'ADIA-HEAT-0001', email: 'user@example.com', plan: 'monthly', expiresAt: null });
    recordActivation('ADIA-HEAT-0001', 'machine-a');
    const db = openDb(dbPath);
    // Place activation at UTC hour 14, 1 day ago
    backdateActivationFirstSeen(db, 'ADIA-HEAT-0001', 'machine-a', 1, 14);
    db.close();

    const res = await callGet({ days: '7' });
    const body = await res.json();
    expect(body.buckets[14].count).toBe(1);
    expect(body.total).toBe(1);
  });

  it('buckets with no activations have count=0', async () => {
    insertLicense({ key: 'ADIA-HEAT-0002', email: 'user2@example.com', plan: 'yearly', expiresAt: null });
    recordActivation('ADIA-HEAT-0002', 'machine-b');
    const db = openDb(dbPath);
    backdateActivationFirstSeen(db, 'ADIA-HEAT-0002', 'machine-b', 1, 9);
    db.close();

    const res = await callGet({ days: '7' });
    const body = await res.json();
    // All hours except 9 should be 0
    body.buckets.forEach((b: { hour: number; count: number }) => {
      if (b.hour !== 9) expect(b.count).toBe(0);
    });
  });

  it('counts multiple activations in the same hour', async () => {
    insertLicense({ key: 'ADIA-HEAT-0003', email: 'a@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-HEAT-0004', email: 'b@example.com', plan: 'monthly', expiresAt: null });
    recordActivation('ADIA-HEAT-0003', 'machine-c');
    recordActivation('ADIA-HEAT-0004', 'machine-d');
    const db = openDb(dbPath);
    backdateActivationFirstSeen(db, 'ADIA-HEAT-0003', 'machine-c', 2, 8);
    backdateActivationFirstSeen(db, 'ADIA-HEAT-0004', 'machine-d', 2, 8);
    db.close();

    const res = await callGet({ days: '7' });
    const body = await res.json();
    expect(body.buckets[8].count).toBe(2);
    expect(body.total).toBe(2);
  });

  it('spreads activations across multiple hours correctly', async () => {
    insertLicense({ key: 'ADIA-HEAT-0005', email: 'c@example.com', plan: 'lifetime', expiresAt: null });
    insertLicense({ key: 'ADIA-HEAT-0006', email: 'd@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation('ADIA-HEAT-0005', 'machine-e');
    recordActivation('ADIA-HEAT-0006', 'machine-f');
    const db = openDb(dbPath);
    backdateActivationFirstSeen(db, 'ADIA-HEAT-0005', 'machine-e', 1, 3);
    backdateActivationFirstSeen(db, 'ADIA-HEAT-0006', 'machine-f', 1, 21);
    db.close();

    const res = await callGet({ days: '7' });
    const body = await res.json();
    expect(body.buckets[3].count).toBe(1);
    expect(body.buckets[21].count).toBe(1);
    expect(body.total).toBe(2);
  });

  it('excludes activations older than the window', async () => {
    insertLicense({ key: 'ADIA-HEAT-0007', email: 'e@example.com', plan: 'monthly', expiresAt: null });
    recordActivation('ADIA-HEAT-0007', 'machine-g');
    const db = openDb(dbPath);
    // 10 days ago — outside a 7-day window
    backdateActivationFirstSeen(db, 'ADIA-HEAT-0007', 'machine-g', 10, 12);
    db.close();

    const res = await callGet({ days: '7' });
    const body = await res.json();
    expect(body.total).toBe(0);
    body.buckets.forEach((b: { count: number }) => expect(b.count).toBe(0));
  });

  it('includes activations within the window', async () => {
    insertLicense({ key: 'ADIA-HEAT-0008', email: 'f@example.com', plan: 'yearly', expiresAt: null });
    recordActivation('ADIA-HEAT-0008', 'machine-h');
    const db = openDb(dbPath);
    // 6 days ago — inside a 7-day window
    backdateActivationFirstSeen(db, 'ADIA-HEAT-0008', 'machine-h', 6, 16);
    db.close();

    const res = await callGet({ days: '7' });
    const body = await res.json();
    expect(body.total).toBe(1);
    expect(body.buckets[16].count).toBe(1);
  });
});

// ─── Plan filter ──────────────────────────────────────────────────────────────

describe('GET /api/admin/usage-heatmap — plan filter', () => {
  it('only counts activations for the specified plan', async () => {
    insertLicense({ key: 'ADIA-HEAT-0009', email: 'g@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-HEAT-0010', email: 'h@example.com', plan: 'yearly', expiresAt: null });
    recordActivation('ADIA-HEAT-0009', 'machine-i');
    recordActivation('ADIA-HEAT-0010', 'machine-j');
    const db = openDb(dbPath);
    backdateActivationFirstSeen(db, 'ADIA-HEAT-0009', 'machine-i', 1, 10);
    backdateActivationFirstSeen(db, 'ADIA-HEAT-0010', 'machine-j', 1, 10);
    db.close();

    const res = await callGet({ days: '7', plan: 'monthly' });
    const body = await res.json();
    expect(body.total).toBe(1);
    expect(body.buckets[10].count).toBe(1);
  });

  it('returns 0 activations when plan filter matches no licenses', async () => {
    insertLicense({ key: 'ADIA-HEAT-0011', email: 'i@example.com', plan: 'monthly', expiresAt: null });
    recordActivation('ADIA-HEAT-0011', 'machine-k');
    const db = openDb(dbPath);
    backdateActivationFirstSeen(db, 'ADIA-HEAT-0011', 'machine-k', 1, 7);
    db.close();

    const res = await callGet({ days: '7', plan: 'lifetime' });
    const body = await res.json();
    expect(body.total).toBe(0);
  });

  it('all valid plans are accepted without 400', async () => {
    for (const plan of ['monthly', 'yearly', 'lifetime']) {
      const res = await callGet({ days: '7', plan });
      expect(res.status).toBe(200);
    }
  });
});

// ─── Rate limit ───────────────────────────────────────────────────────────────

describe('GET /api/admin/usage-heatmap — rate limit', () => {
  it('returns 429 after 20 requests from the same IP', async () => {
    const { GET } = await import('@/app/api/admin/usage-heatmap/route');
    const makeReq = () =>
      new NextRequest('http://localhost/api/admin/usage-heatmap', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer test-admin-token',
          'x-forwarded-for': '10.91.2.1',
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
    const { GET } = await import('@/app/api/admin/usage-heatmap/route');
    const makeReq = () =>
      new NextRequest('http://localhost/api/admin/usage-heatmap', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer test-admin-token',
          'x-forwarded-for': '10.91.2.2',
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
    const { GET } = await import('@/app/api/admin/usage-heatmap/route');
    const goodReq = () =>
      new NextRequest('http://localhost/api/admin/usage-heatmap', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer test-admin-token',
          'x-forwarded-for': '10.91.2.3',
        },
      });
    const badReq = () =>
      new NextRequest('http://localhost/api/admin/usage-heatmap', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer wrong-token',
          'x-forwarded-for': '10.91.2.3',
        },
      });

    for (let i = 0; i < 20; i++) {
      await GET(goodReq());
    }

    const res = await GET(badReq());
    expect(res.status).toBe(429);
  });
});
