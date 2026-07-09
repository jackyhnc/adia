// Tests for GET /api/admin/activation-timeline
// Returns daily activation counts over the last N days (oldest first).
// Each bucket: { date: "YYYY-MM-DD", count: N }. Missing days have count=0.
// Supports ?days= (default 30, max 365) and ?plan= filters.

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

// Set an activation's first_seen to exactly `daysAgo` days before now (UTC midnight).
function backdateActivationToDay(
  db: Database.Database,
  licenseKey: string,
  machineHash: string,
  daysAgo: number,
) {
  const d = new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000);
  d.setUTCHours(12, 0, 0, 0); // noon UTC, safely within the calendar day
  db.prepare('UPDATE activations SET first_seen = ? WHERE license_key = ? AND machine_hash = ?')
    .run(d.toISOString(), licenseKey, machineHash);
}

// Returns "YYYY-MM-DD" for `daysAgo` days before today (UTC).
function utcDateStr(daysAgo: number): string {
  const d = new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000);
  return d.toISOString().slice(0, 10);
}

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(
    os.tmpdir(),
    `adia-timeline-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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
  const { GET } = await import('@/app/api/admin/activation-timeline/route');
  const sp = new URLSearchParams(params);
  const req = new NextRequest(`http://localhost/api/admin/activation-timeline?${sp}`, {
    method: 'GET',
    headers: authHeader(token),
  });
  return GET(req);
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('GET /api/admin/activation-timeline — auth', () => {
  it('returns 401 with no authorization header', async () => {
    const { GET } = await import('@/app/api/admin/activation-timeline/route');
    const req = new NextRequest('http://localhost/api/admin/activation-timeline');
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callGet({}, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query-param auth', async () => {
    const { GET } = await import('@/app/api/admin/activation-timeline/route');
    const req = new NextRequest('http://localhost/api/admin/activation-timeline?token=test-admin-token');
    const res = await GET(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ───────────────────────────────────────────────────────────────

describe('GET /api/admin/activation-timeline — validation', () => {
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

describe('GET /api/admin/activation-timeline — response shape', () => {
  it('returns 200 with empty DB', async () => {
    const res = await callGet({ days: '7' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.days).toBe(7);
    expect(body.total).toBe(0);
    expect(Array.isArray(body.buckets)).toBe(true);
  });

  it('returns exactly `days` buckets', async () => {
    const res = await callGet({ days: '7' });
    const body = await res.json();
    expect(body.buckets).toHaveLength(7);
  });

  it('returns 30 buckets by default', async () => {
    const res = await callGet();
    const body = await res.json();
    expect(body.buckets).toHaveLength(30);
    expect(body.days).toBe(30);
  });

  it('buckets have correct shape', async () => {
    const res = await callGet({ days: '7' });
    const body = await res.json();
    for (const b of body.buckets) {
      expect(typeof b.date).toBe('string');
      expect(b.date).toMatch(/^\d{4}-\d{2}-\d{2}$/);
      expect(typeof b.count).toBe('number');
    }
  });

  it('buckets are in ascending date order (oldest first)', async () => {
    const res = await callGet({ days: '7' });
    const body = await res.json();
    for (let i = 1; i < body.buckets.length; i++) {
      expect(body.buckets[i].date > body.buckets[i - 1].date).toBe(true);
    }
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
    expect(body.buckets).toHaveLength(1);
    expect(body.days).toBe(1);
  });

  it('accepts days=365 (maximum valid)', async () => {
    const res = await callGet({ days: '365' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.buckets).toHaveLength(365);
    expect(body.days).toBe(365);
  });

  it('all buckets have count=0 on empty DB', async () => {
    const res = await callGet({ days: '14' });
    const body = await res.json();
    expect(body.total).toBe(0);
    for (const b of body.buckets) expect(b.count).toBe(0);
  });
});

// ─── Core behavior ────────────────────────────────────────────────────────────

describe('GET /api/admin/activation-timeline — core behavior', () => {
  it('counts an activation in the correct date bucket', async () => {
    insertLicense({ key: 'ADIA-TL-0001', email: 'a@example.com', plan: 'monthly', expiresAt: null });
    recordActivation('ADIA-TL-0001', 'mach-a');
    const db = openDb(dbPath);
    backdateActivationToDay(db, 'ADIA-TL-0001', 'mach-a', 2);
    db.close();

    const res = await callGet({ days: '7' });
    const body = await res.json();
    const expected = utcDateStr(2);
    const bucket = body.buckets.find((b: TimelineDay) => b.date === expected);
    expect(bucket).toBeDefined();
    expect(bucket!.count).toBe(1);
    expect(body.total).toBe(1);
  });

  it('days with no activations have count=0', async () => {
    insertLicense({ key: 'ADIA-TL-0002', email: 'b@example.com', plan: 'yearly', expiresAt: null });
    recordActivation('ADIA-TL-0002', 'mach-b');
    const db = openDb(dbPath);
    backdateActivationToDay(db, 'ADIA-TL-0002', 'mach-b', 1);
    db.close();

    const res = await callGet({ days: '7' });
    const body = await res.json();
    const today = utcDateStr(0);
    const yesterday = utcDateStr(1);
    for (const b of body.buckets) {
      if (b.date !== yesterday) expect(b.count).toBe(0);
      else expect(b.count).toBe(1);
    }
    // today should be 0 (activation was yesterday)
    const todayBucket = body.buckets.find((b: TimelineDay) => b.date === today);
    expect(todayBucket?.count).toBe(0);
  });

  it('counts multiple activations on the same day', async () => {
    insertLicense({ key: 'ADIA-TL-0003', email: 'c@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-TL-0004', email: 'd@example.com', plan: 'monthly', expiresAt: null });
    recordActivation('ADIA-TL-0003', 'mach-c');
    recordActivation('ADIA-TL-0004', 'mach-d');
    const db = openDb(dbPath);
    backdateActivationToDay(db, 'ADIA-TL-0003', 'mach-c', 3);
    backdateActivationToDay(db, 'ADIA-TL-0004', 'mach-d', 3);
    db.close();

    const res = await callGet({ days: '7' });
    const body = await res.json();
    const expected = utcDateStr(3);
    const bucket = body.buckets.find((b: TimelineDay) => b.date === expected);
    expect(bucket!.count).toBe(2);
    expect(body.total).toBe(2);
  });

  it('spreads activations across multiple days correctly', async () => {
    insertLicense({ key: 'ADIA-TL-0005', email: 'e@example.com', plan: 'lifetime', expiresAt: null });
    insertLicense({ key: 'ADIA-TL-0006', email: 'f@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation('ADIA-TL-0005', 'mach-e');
    recordActivation('ADIA-TL-0006', 'mach-f');
    const db = openDb(dbPath);
    backdateActivationToDay(db, 'ADIA-TL-0005', 'mach-e', 1);
    backdateActivationToDay(db, 'ADIA-TL-0006', 'mach-f', 4);
    db.close();

    const res = await callGet({ days: '7' });
    const body = await res.json();
    const d1 = utcDateStr(1);
    const d4 = utcDateStr(4);
    expect(body.buckets.find((b: TimelineDay) => b.date === d1)!.count).toBe(1);
    expect(body.buckets.find((b: TimelineDay) => b.date === d4)!.count).toBe(1);
    expect(body.total).toBe(2);
  });

  it('excludes activations older than the window', async () => {
    insertLicense({ key: 'ADIA-TL-0007', email: 'g@example.com', plan: 'monthly', expiresAt: null });
    recordActivation('ADIA-TL-0007', 'mach-g');
    const db = openDb(dbPath);
    // 10 days ago — outside a 7-day window
    backdateActivationToDay(db, 'ADIA-TL-0007', 'mach-g', 10);
    db.close();

    const res = await callGet({ days: '7' });
    const body = await res.json();
    expect(body.total).toBe(0);
    for (const b of body.buckets) expect(b.count).toBe(0);
  });

  it('includes activations within the window', async () => {
    insertLicense({ key: 'ADIA-TL-0008', email: 'h@example.com', plan: 'yearly', expiresAt: null });
    recordActivation('ADIA-TL-0008', 'mach-h');
    const db = openDb(dbPath);
    // 6 days ago — inside a 7-day window
    backdateActivationToDay(db, 'ADIA-TL-0008', 'mach-h', 6);
    db.close();

    const res = await callGet({ days: '7' });
    const body = await res.json();
    expect(body.total).toBe(1);
    const d6 = utcDateStr(6);
    expect(body.buckets.find((b: TimelineDay) => b.date === d6)!.count).toBe(1);
  });

  it('total equals sum of all bucket counts', async () => {
    insertLicense({ key: 'ADIA-TL-0009', email: 'i@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-TL-0010', email: 'j@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-TL-0011', email: 'k@example.com', plan: 'yearly', expiresAt: null });
    recordActivation('ADIA-TL-0009', 'mach-i');
    recordActivation('ADIA-TL-0010', 'mach-j');
    recordActivation('ADIA-TL-0011', 'mach-k');
    const db = openDb(dbPath);
    backdateActivationToDay(db, 'ADIA-TL-0009', 'mach-i', 1);
    backdateActivationToDay(db, 'ADIA-TL-0010', 'mach-j', 2);
    backdateActivationToDay(db, 'ADIA-TL-0011', 'mach-k', 3);
    db.close();

    const res = await callGet({ days: '7' });
    const body = await res.json();
    const summed = body.buckets.reduce((s: number, b: TimelineDay) => s + b.count, 0);
    expect(body.total).toBe(3);
    expect(summed).toBe(body.total);
  });
});

// ─── Plan filter ──────────────────────────────────────────────────────────────

describe('GET /api/admin/activation-timeline — plan filter', () => {
  it('only counts activations for the specified plan', async () => {
    insertLicense({ key: 'ADIA-TL-0012', email: 'l@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-TL-0013', email: 'm@example.com', plan: 'yearly', expiresAt: null });
    recordActivation('ADIA-TL-0012', 'mach-l');
    recordActivation('ADIA-TL-0013', 'mach-m');
    const db = openDb(dbPath);
    backdateActivationToDay(db, 'ADIA-TL-0012', 'mach-l', 1);
    backdateActivationToDay(db, 'ADIA-TL-0013', 'mach-m', 1);
    db.close();

    const res = await callGet({ days: '7', plan: 'monthly' });
    const body = await res.json();
    expect(body.total).toBe(1);
    const d1 = utcDateStr(1);
    expect(body.buckets.find((b: TimelineDay) => b.date === d1)!.count).toBe(1);
  });

  it('returns 0 activations when plan filter matches no licenses', async () => {
    insertLicense({ key: 'ADIA-TL-0014', email: 'n@example.com', plan: 'monthly', expiresAt: null });
    recordActivation('ADIA-TL-0014', 'mach-n');
    const db = openDb(dbPath);
    backdateActivationToDay(db, 'ADIA-TL-0014', 'mach-n', 1);
    db.close();

    const res = await callGet({ days: '7', plan: 'lifetime' });
    const body = await res.json();
    expect(body.total).toBe(0);
  });

  it('yearly filter excludes monthly activations', async () => {
    insertLicense({ key: 'ADIA-TL-0015', email: 'o@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-TL-0016', email: 'p@example.com', plan: 'yearly', expiresAt: null });
    recordActivation('ADIA-TL-0015', 'mach-o');
    recordActivation('ADIA-TL-0016', 'mach-p');
    const db = openDb(dbPath);
    backdateActivationToDay(db, 'ADIA-TL-0015', 'mach-o', 2);
    backdateActivationToDay(db, 'ADIA-TL-0016', 'mach-p', 2);
    db.close();

    const res = await callGet({ days: '7', plan: 'yearly' });
    const body = await res.json();
    expect(body.total).toBe(1);
  });

  it('all valid plans are accepted without 400', async () => {
    for (const plan of ['monthly', 'yearly', 'lifetime']) {
      const res = await callGet({ days: '7', plan });
      expect(res.status).toBe(200);
    }
  });

  it('no plan filter returns all plans combined', async () => {
    insertLicense({ key: 'ADIA-TL-0017', email: 'q@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-TL-0018', email: 'r@example.com', plan: 'yearly', expiresAt: null });
    insertLicense({ key: 'ADIA-TL-0019', email: 's@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation('ADIA-TL-0017', 'mach-q');
    recordActivation('ADIA-TL-0018', 'mach-r');
    recordActivation('ADIA-TL-0019', 'mach-s');
    const db = openDb(dbPath);
    backdateActivationToDay(db, 'ADIA-TL-0017', 'mach-q', 1);
    backdateActivationToDay(db, 'ADIA-TL-0018', 'mach-r', 1);
    backdateActivationToDay(db, 'ADIA-TL-0019', 'mach-s', 1);
    db.close();

    const res = await callGet({ days: '7' });
    const body = await res.json();
    expect(body.total).toBe(3);
  });
});

type TimelineDay = { date: string; count: number };

// ─── Rate limit ───────────────────────────────────────────────────────────────

describe('GET /api/admin/activation-timeline — rate limit', () => {
  it('returns 429 after 20 requests from the same IP', async () => {
    const { GET } = await import('@/app/api/admin/activation-timeline/route');
    const makeReq = () =>
      new NextRequest('http://localhost/api/admin/activation-timeline', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer test-admin-token',
          'x-forwarded-for': '10.91.4.1',
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
    const { GET } = await import('@/app/api/admin/activation-timeline/route');
    const makeReq = () =>
      new NextRequest('http://localhost/api/admin/activation-timeline', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer test-admin-token',
          'x-forwarded-for': '10.91.4.2',
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
    const { GET } = await import('@/app/api/admin/activation-timeline/route');
    const goodReq = () =>
      new NextRequest('http://localhost/api/admin/activation-timeline', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer test-admin-token',
          'x-forwarded-for': '10.91.4.3',
        },
      });
    const badReq = () =>
      new NextRequest('http://localhost/api/admin/activation-timeline', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer wrong-token',
          'x-forwarded-for': '10.91.4.3',
        },
      });

    for (let i = 0; i < 20; i++) {
      await GET(goodReq());
    }

    const res = await GET(badReq());
    expect(res.status).toBe(429);
  });
});
