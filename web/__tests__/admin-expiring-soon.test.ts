// Tests for GET /api/admin/expiring-soon
// ?days=N (default 30, max 365), ?plan=monthly|yearly, ?format=csv|json

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, setExpiry, setStatus } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(
    os.tmpdir(),
    `adia-expiring-soon-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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

async function callGet(params: Record<string, string | number> = {}, token = 'test-admin-token') {
  const { GET } = await import('@/app/api/admin/expiring-soon/route');
  const sp = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) sp.set(k, String(v));
  const req = new NextRequest(`http://localhost/api/admin/expiring-soon?${sp}`, {
    method: 'GET',
    headers: authHeader(token),
  });
  return GET(req);
}

function daysFromNow(days: number): string {
  return new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString();
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('GET /api/admin/expiring-soon — auth', () => {
  it('returns 401 with no authorization header', async () => {
    const { GET } = await import('@/app/api/admin/expiring-soon/route');
    const req = new NextRequest('http://localhost/api/admin/expiring-soon');
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callGet({}, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query-param auth', async () => {
    const { GET } = await import('@/app/api/admin/expiring-soon/route');
    const req = new NextRequest('http://localhost/api/admin/expiring-soon?token=test-admin-token');
    const res = await GET(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ───────────────────────────────────────────────────────────────

describe('GET /api/admin/expiring-soon — validation', () => {
  it('returns 400 for days=0', async () => {
    const res = await callGet({ days: 0 });
    expect(res.status).toBe(400);
  });

  it('returns 400 for days=-5', async () => {
    const res = await callGet({ days: -5 });
    expect(res.status).toBe(400);
  });

  it('returns 400 for non-numeric days', async () => {
    const res = await callGet({ days: 'abc' });
    expect(res.status).toBe(400);
  });

  it('clamps days to max 365 silently', async () => {
    const res = await callGet({ days: 9999 });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.days).toBe(365);
  });

  it('returns 400 for invalid plan', async () => {
    const res = await callGet({ plan: 'lifetime' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/plan/i);
  });

  it('returns 400 for invalid format', async () => {
    const res = await callGet({ format: 'xml' });
    expect(res.status).toBe(400);
  });
});

// ─── Core behaviour ──────────────────────────────────────────────────────────

describe('GET /api/admin/expiring-soon — core', () => {
  it('returns empty list when no licenses exist', async () => {
    const res = await callGet({ days: 30 });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(0);
    expect(body.licenses).toEqual([]);
    expect(body.days).toBe(30);
  });

  it('returns license expiring within window', async () => {
    insertLicense({ key: 'ADIA-EXPR-SOON-0001', email: 'e@example.com', plan: 'monthly', expiresAt: daysFromNow(10) });
    const res = await callGet({ days: 30 });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.licenses[0].key).toBe('ADIA-EXPR-SOON-0001');
  });

  it('excludes license expiring outside the window', async () => {
    insertLicense({ key: 'ADIA-EXPR-LATE-0001', email: 'late@example.com', plan: 'monthly', expiresAt: daysFromNow(60) });
    const res = await callGet({ days: 30 });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(0);
  });

  it('excludes lifetime licenses (null expiresAt)', async () => {
    insertLicense({ key: 'ADIA-EXPR-LIFE-0001', email: 'life@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callGet({ days: 365 });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).not.toContain('ADIA-EXPR-LIFE-0001');
  });

  it('excludes already-expired licenses', async () => {
    insertLicense({ key: 'ADIA-EXPR-PAST-0001', email: 'past@example.com', plan: 'monthly', expiresAt: daysFromNow(-5) });
    const res = await callGet({ days: 30 });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).not.toContain('ADIA-EXPR-PAST-0001');
  });

  it('excludes non-active licenses', async () => {
    insertLicense({ key: 'ADIA-EXPR-CNCL-0001', email: 'cncl@example.com', plan: 'monthly', expiresAt: daysFromNow(5) });
    setStatus('ADIA-EXPR-CNCL-0001', 'canceled');
    const res = await callGet({ days: 30 });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).not.toContain('ADIA-EXPR-CNCL-0001');
  });

  it('orders results by expiresAt ascending (soonest first)', async () => {
    insertLicense({ key: 'ADIA-EXPR-ORD-0003', email: 'ord3@example.com', plan: 'monthly', expiresAt: daysFromNow(20) });
    insertLicense({ key: 'ADIA-EXPR-ORD-0001', email: 'ord1@example.com', plan: 'monthly', expiresAt: daysFromNow(5) });
    insertLicense({ key: 'ADIA-EXPR-ORD-0002', email: 'ord2@example.com', plan: 'yearly', expiresAt: daysFromNow(12) });
    const res = await callGet({ days: 30 });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toEqual(['ADIA-EXPR-ORD-0001', 'ADIA-EXPR-ORD-0002', 'ADIA-EXPR-ORD-0003']);
  });

  it('uses default 30 days when days param is omitted', async () => {
    const res = await callGet();
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.days).toBe(30);
  });
});

// ─── Plan filter ──────────────────────────────────────────────────────────────

describe('GET /api/admin/expiring-soon — plan filter', () => {
  it('filters to monthly plan only', async () => {
    insertLicense({ key: 'ADIA-EXPR-PLN-0001', email: 'plnm@example.com', plan: 'monthly', expiresAt: daysFromNow(10) });
    insertLicense({ key: 'ADIA-EXPR-PLN-0002', email: 'plny@example.com', plan: 'yearly', expiresAt: daysFromNow(15) });
    const res = await callGet({ days: 30, plan: 'monthly' });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-EXPR-PLN-0001');
    expect(keys).not.toContain('ADIA-EXPR-PLN-0002');
  });

  it('filters to yearly plan only', async () => {
    insertLicense({ key: 'ADIA-EXPR-YR-0001', email: 'yrm@example.com', plan: 'monthly', expiresAt: daysFromNow(10) });
    insertLicense({ key: 'ADIA-EXPR-YR-0002', email: 'yry@example.com', plan: 'yearly', expiresAt: daysFromNow(15) });
    const res = await callGet({ days: 30, plan: 'yearly' });
    expect(res.status).toBe(200);
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-EXPR-YR-0002');
    expect(keys).not.toContain('ADIA-EXPR-YR-0001');
  });
});

// ─── CSV format ───────────────────────────────────────────────────────────────

describe('GET /api/admin/expiring-soon — CSV', () => {
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
    expect(text.split('\n')[0]).toBe('key,email,plan,status,expiresAt,machineCount,note');
  });

  it('CSV includes a matching row for an expiring license', async () => {
    insertLicense({ key: 'ADIA-EXPR-CSV-0001', email: 'csv@example.com', plan: 'monthly', expiresAt: daysFromNow(5) });
    const res = await callGet({ format: 'csv', days: 30 });
    const text = await res.text();
    expect(text).toContain('ADIA-EXPR-CSV-0001');
    expect(text).toContain('csv@example.com');
  });

  it('CSV escapes commas and quotes in note field', async () => {
    insertLicense({ key: 'ADIA-EXPR-ESC-0001', email: 'esc@example.com', plan: 'monthly', expiresAt: daysFromNow(5) });
    const { setNote } = await import('@/lib/db');
    setNote('ADIA-EXPR-ESC-0001', 'has, comma and "quote"');
    const res = await callGet({ format: 'csv', days: 30 });
    const text = await res.text();
    expect(text).toContain('"has, comma and ""quote"""');
  });
});

// ─── Response shape ──────────────────────────────────────────────────────────

describe('GET /api/admin/expiring-soon — response shape', () => {
  it('response contains licenses, count, and days fields', async () => {
    const res = await callGet({ days: 14 });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('licenses');
    expect(body).toHaveProperty('count');
    expect(body).toHaveProperty('days', 14);
    expect(Array.isArray(body.licenses)).toBe(true);
    expect(typeof body.count).toBe('number');
  });

  it('each license row contains key, email, plan, status, expiresAt, machineCount', async () => {
    insertLicense({ key: 'ADIA-EXPR-SHPE-0001', email: 'shape@example.com', plan: 'yearly', expiresAt: daysFromNow(3) });
    const res = await callGet({ days: 30 });
    const body = await res.json();
    expect(body.count).toBe(1);
    const l = body.licenses[0];
    expect(l).toHaveProperty('key', 'ADIA-EXPR-SHPE-0001');
    expect(l).toHaveProperty('email', 'shape@example.com');
    expect(l).toHaveProperty('plan', 'yearly');
    expect(l).toHaveProperty('status', 'active');
    expect(l).toHaveProperty('expiresAt');
    expect(l).toHaveProperty('machineCount');
  });
});
