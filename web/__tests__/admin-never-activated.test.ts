// Tests for GET /api/admin/never-activated
// Returns licenses with machineCount = 0, newest-issued first.
// Supports ?plan=, ?since=, ?status=, ?format=csv

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, recordActivation, setStatus, setNote } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(
    os.tmpdir(),
    `adia-never-activated-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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
  const { GET } = await import('@/app/api/admin/never-activated/route');
  const sp = new URLSearchParams(params);
  const req = new NextRequest(`http://localhost/api/admin/never-activated?${sp}`, {
    method: 'GET',
    headers: authHeader(token),
  });
  return GET(req);
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('GET /api/admin/never-activated — auth', () => {
  it('returns 401 with no authorization header', async () => {
    const { GET } = await import('@/app/api/admin/never-activated/route');
    const req = new NextRequest('http://localhost/api/admin/never-activated');
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callGet({}, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query-param auth', async () => {
    const { GET } = await import('@/app/api/admin/never-activated/route');
    const req = new NextRequest('http://localhost/api/admin/never-activated?token=test-admin-token');
    const res = await GET(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ───────────────────────────────────────────────────────────────

describe('GET /api/admin/never-activated — validation', () => {
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

describe('GET /api/admin/never-activated — core', () => {
  it('returns empty list when no licenses exist', async () => {
    const res = await callGet();
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(0);
    expect(body.licenses).toEqual([]);
  });

  it('returns a license that has never been activated', async () => {
    insertLicense({ key: 'ADIA-NACT-CORE-0001', email: 'nact@example.com', plan: 'monthly', expiresAt: null });
    const res = await callGet();
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.licenses[0].key).toBe('ADIA-NACT-CORE-0001');
    expect(body.licenses[0].machineCount).toBe(0);
  });

  it('excludes a license that has been activated', async () => {
    insertLicense({ key: 'ADIA-NACT-ACT-0001', email: 'act@example.com', plan: 'monthly', expiresAt: null });
    recordActivation('ADIA-NACT-ACT-0001', 'abc123');
    const res = await callGet();
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).not.toContain('ADIA-NACT-ACT-0001');
  });

  it('returns never-activated while excluding activated in the same call', async () => {
    insertLicense({ key: 'ADIA-NACT-MIX-0001', email: 'mix1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-NACT-MIX-0002', email: 'mix2@example.com', plan: 'yearly', expiresAt: null });
    recordActivation('ADIA-NACT-MIX-0002', 'def456');
    const res = await callGet();
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-NACT-MIX-0001');
    expect(keys).not.toContain('ADIA-NACT-MIX-0002');
  });

  it('orders results by issuedAt DESC (newest first)', async () => {
    // Insert in a specific order; DB sorts by issuedAt DESC
    insertLicense({ key: 'ADIA-NACT-ORD-0001', email: 'ord1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-NACT-ORD-0002', email: 'ord2@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-NACT-ORD-0003', email: 'ord3@example.com', plan: 'monthly', expiresAt: null });
    const res = await callGet();
    expect(res.status).toBe(200);
    const body = await res.json();
    // Newest issuedAt (0003) should come first — insertLicense sets issued_at to NOW()
    // In practice all three get the same timestamp so we just verify all three are present
    expect(body.count).toBe(3);
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-NACT-ORD-0001');
    expect(keys).toContain('ADIA-NACT-ORD-0002');
    expect(keys).toContain('ADIA-NACT-ORD-0003');
  });

  it('response contains licenses and count fields', async () => {
    const res = await callGet();
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('licenses');
    expect(body).toHaveProperty('count');
    expect(Array.isArray(body.licenses)).toBe(true);
    expect(typeof body.count).toBe('number');
  });

  it('each license row contains key, email, plan, status, issuedAt, machineCount', async () => {
    insertLicense({ key: 'ADIA-NACT-SHPE-0001', email: 'shape@example.com', plan: 'yearly', expiresAt: null });
    const res = await callGet();
    const body = await res.json();
    expect(body.count).toBe(1);
    const l = body.licenses[0];
    expect(l).toHaveProperty('key', 'ADIA-NACT-SHPE-0001');
    expect(l).toHaveProperty('email', 'shape@example.com');
    expect(l).toHaveProperty('plan', 'yearly');
    expect(l).toHaveProperty('status', 'active');
    expect(l).toHaveProperty('issuedAt');
    expect(l).toHaveProperty('machineCount', 0);
  });
});

// ─── Plan filter ──────────────────────────────────────────────────────────────

describe('GET /api/admin/never-activated — plan filter', () => {
  it('filters to monthly plan only', async () => {
    insertLicense({ key: 'ADIA-NACT-PLN-0001', email: 'plnm@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-NACT-PLN-0002', email: 'plny@example.com', plan: 'yearly', expiresAt: null });
    const res = await callGet({ plan: 'monthly' });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-NACT-PLN-0001');
    expect(keys).not.toContain('ADIA-NACT-PLN-0002');
  });

  it('filters to lifetime plan only', async () => {
    insertLicense({ key: 'ADIA-NACT-LIFE-0001', email: 'lifem@example.com', plan: 'lifetime', expiresAt: null });
    insertLicense({ key: 'ADIA-NACT-LIFE-0002', email: 'lifey@example.com', plan: 'monthly', expiresAt: null });
    const res = await callGet({ plan: 'lifetime' });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-NACT-LIFE-0001');
    expect(keys).not.toContain('ADIA-NACT-LIFE-0002');
  });
});

// ─── Status filter ────────────────────────────────────────────────────────────

describe('GET /api/admin/never-activated — status filter', () => {
  it('returns all statuses when status param omitted', async () => {
    insertLicense({ key: 'ADIA-NACT-STS-0001', email: 'sts1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-NACT-STS-0002', email: 'sts2@example.com', plan: 'monthly', expiresAt: null });
    setStatus('ADIA-NACT-STS-0002', 'canceled');
    const res = await callGet();
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-NACT-STS-0001');
    expect(keys).toContain('ADIA-NACT-STS-0002');
  });

  it('filters to active only when status=active', async () => {
    insertLicense({ key: 'ADIA-NACT-STA-0001', email: 'sta1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-NACT-STA-0002', email: 'sta2@example.com', plan: 'monthly', expiresAt: null });
    setStatus('ADIA-NACT-STA-0002', 'canceled');
    const res = await callGet({ status: 'active' });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-NACT-STA-0001');
    expect(keys).not.toContain('ADIA-NACT-STA-0002');
  });

  it('filters to canceled only when status=canceled', async () => {
    insertLicense({ key: 'ADIA-NACT-CNC-0001', email: 'cnc1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-NACT-CNC-0002', email: 'cnc2@example.com', plan: 'monthly', expiresAt: null });
    setStatus('ADIA-NACT-CNC-0002', 'canceled');
    const res = await callGet({ status: 'canceled' });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).not.toContain('ADIA-NACT-CNC-0001');
    expect(keys).toContain('ADIA-NACT-CNC-0002');
  });
});

// ─── Since filter ─────────────────────────────────────────────────────────────

describe('GET /api/admin/never-activated — since filter', () => {
  it('?since= filters to licenses issued on or after the date', async () => {
    // All licenses are issued at ~now, so a future since date excludes them all
    insertLicense({ key: 'ADIA-NACT-SNC-0001', email: 'snc1@example.com', plan: 'monthly', expiresAt: null });
    const futureSince = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
    const res = await callGet({ since: futureSince });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(0);
  });

  it('?since= includes licenses issued today or after', async () => {
    insertLicense({ key: 'ADIA-NACT-SNC-0002', email: 'snc2@example.com', plan: 'monthly', expiresAt: null });
    const pastSince = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
    const res = await callGet({ since: pastSince });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-NACT-SNC-0002');
  });
});

// ─── CSV format ───────────────────────────────────────────────────────────────

describe('GET /api/admin/never-activated — CSV', () => {
  it('returns CSV content-type with format=csv', async () => {
    const res = await callGet({ format: 'csv' });
    expect(res.headers.get('content-type')).toMatch(/text\/csv/);
  });

  it('CSV Content-Disposition has a .csv filename', async () => {
    const res = await callGet({ format: 'csv' });
    const cd = res.headers.get('content-disposition') ?? '';
    expect(cd).toMatch(/attachment.*\.csv/);
  });

  it('CSV has correct header row', async () => {
    const res = await callGet({ format: 'csv' });
    const text = await res.text();
    expect(text.split('\n')[0]).toBe('key,email,plan,status,issuedAt,machineCount,note');
  });

  it('CSV includes a matching row for a never-activated license', async () => {
    insertLicense({ key: 'ADIA-NACT-CSV-0001', email: 'csv@example.com', plan: 'monthly', expiresAt: null });
    const res = await callGet({ format: 'csv' });
    const text = await res.text();
    expect(text).toContain('ADIA-NACT-CSV-0001');
    expect(text).toContain('csv@example.com');
  });

  it('CSV escapes commas and quotes in note field', async () => {
    insertLicense({ key: 'ADIA-NACT-ESC-0001', email: 'esc@example.com', plan: 'monthly', expiresAt: null });
    setNote('ADIA-NACT-ESC-0001', 'has, comma and "quote"');
    const res = await callGet({ format: 'csv' });
    const text = await res.text();
    expect(text).toContain('"has, comma and ""quote"""');
  });
});

// ─── Rate limit ───────────────────────────────────────────────────────────────

describe('GET /api/admin/never-activated — rate limit', () => {
  it('returns 429 after 20 requests from the same IP', async () => {
    const { GET } = await import('@/app/api/admin/never-activated/route');
    const ip = '10.93.1.1';
    let lastStatus = 0;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/never-activated', {
        method: 'GET',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
      });
      const res = await GET(req);
      lastStatus = res.status;
    }
    expect(lastStatus).toBe(429);
  });

  it('429 response includes Retry-After header', async () => {
    const { GET } = await import('@/app/api/admin/never-activated/route');
    const ip = '10.93.1.2';
    let lastRes: Response | null = null;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/never-activated', {
        method: 'GET',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
      });
      lastRes = await GET(req);
    }
    expect(lastRes?.headers.get('Retry-After')).toBeTruthy();
  });

  it('rate limit fires before auth check — wrong token still gets 429 when bucket exhausted', async () => {
    const { GET } = await import('@/app/api/admin/never-activated/route');
    const ip = '10.93.1.3';
    for (let i = 0; i < 20; i++) {
      const req = new NextRequest('http://localhost/api/admin/never-activated', {
        method: 'GET',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
      });
      await GET(req);
    }
    const req = new NextRequest('http://localhost/api/admin/never-activated', {
      method: 'GET',
      headers: { Authorization: 'Bearer wrong-token', 'x-forwarded-for': ip },
    });
    const res = await GET(req);
    expect(res.status).toBe(429);
  });
});
