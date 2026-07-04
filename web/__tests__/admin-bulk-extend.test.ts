// Tests for POST /api/admin/bulk-extend
// Body: { keys: string[], days: number }

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, findLicense, listAuditLog } from '@/lib/db';

let dbPath: string;

beforeEach(() => {
  dbPath = path.join(
    os.tmpdir(),
    `adia-bulk-extend-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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

async function callPost(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/bulk-extend/route');
  const req = new NextRequest('http://localhost/api/admin/bulk-extend', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', ...authHeader(token) },
  });
  return POST(req);
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-extend — auth', () => {
  it('returns 401 with no authorization header', async () => {
    const { POST } = await import('@/app/api/admin/bulk-extend/route');
    const req = new NextRequest('http://localhost/api/admin/bulk-extend', {
      method: 'POST',
      body: JSON.stringify({ keys: ['ADIA-XXXX-XXXX-XXXX'], days: 7 }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callPost({ keys: ['ADIA-XXXX-XXXX-XXXX'], days: 7 }, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query param as auth fallback', async () => {
    const key = 'ADIA-BETK-TOKN-AAAA';
    insertLicense({ key, email: 'tok@example.com', plan: 'monthly', expiresAt: null });
    const { POST } = await import('@/app/api/admin/bulk-extend/route');
    const req = new NextRequest(
      'http://localhost/api/admin/bulk-extend?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ keys: [key], days: 30 }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
    expect((await res.json()).ok).toBe(true);
  });
});

// ─── Validation ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-extend — validation', () => {
  it('returns 400 when keys is missing', async () => {
    const res = await callPost({ days: 7 });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/missing or empty keys/i);
  });

  it('returns 400 when keys is an empty array', async () => {
    const res = await callPost({ keys: [], days: 7 });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/missing or empty keys/i);
  });

  it('returns 400 when keys exceeds 100', async () => {
    const keys = Array.from({ length: 101 }, (_, i) => `ADIA-BEXT-${String(i).padStart(4, '0')}-AAAA`);
    const res = await callPost({ keys, days: 7 });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/too many keys/i);
  });

  it('returns 400 when days is missing', async () => {
    const res = await callPost({ keys: ['ADIA-XXXX-XXXX-AAAA'] });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/missing days/i);
  });

  it('returns 400 when days is zero', async () => {
    const res = await callPost({ keys: ['ADIA-XXXX-XXXX-AAAA'], days: 0 });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/positive integer/i);
  });

  it('returns 400 when days is negative', async () => {
    const res = await callPost({ keys: ['ADIA-XXXX-XXXX-AAAA'], days: -5 });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/positive integer/i);
  });

  it('returns 400 when days is not an integer', async () => {
    const res = await callPost({ keys: ['ADIA-XXXX-XXXX-AAAA'], days: 1.5 });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/positive integer/i);
  });

  it('returns 400 when days exceeds 3650', async () => {
    const res = await callPost({ keys: ['ADIA-XXXX-XXXX-AAAA'], days: 3651 });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/3650/);
  });
});

// ─── Core logic ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-extend — extend logic', () => {
  it('extends a future expiresAt by the given days', async () => {
    const key = 'ADIA-BEXT-FUT1-AAAA';
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 10);
    const futureDateStr = futureDate.toISOString();
    insertLicense({ key, email: 'fut1@example.com', plan: 'yearly', expiresAt: futureDateStr });

    const res = await callPost({ keys: [key], days: 30 });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.changed).toHaveLength(1);
    expect(body.skipped).toHaveLength(0);

    const result = body.changed[0];
    expect(result.key).toBe(key);
    expect(result.previousExpiresAt).toBe(futureDateStr);
    expect(result.days).toBe(30);

    // New expiry should be ~40 days from now (10 remaining + 30 added)
    const newDate = new Date(result.newExpiresAt);
    const diffDays = (newDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24);
    expect(diffDays).toBeGreaterThan(38);
    expect(diffDays).toBeLessThan(42);

    // DB updated
    const updated = findLicense(key);
    expect(updated?.expiresAt).toBe(result.newExpiresAt);
  });

  it('extends a null (lifetime) expiresAt from now', async () => {
    const key = 'ADIA-BEXT-LFT1-AAAA';
    insertLicense({ key, email: 'lft1@example.com', plan: 'lifetime', expiresAt: null });

    const before = Date.now();
    const res = await callPost({ keys: [key], days: 14 });
    const after = Date.now();

    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed[0].previousExpiresAt).toBeNull();

    const newDate = new Date(body.changed[0].newExpiresAt).getTime();
    // Should be approximately 14 days from now
    const diffDays = (newDate - before) / (1000 * 60 * 60 * 24);
    expect(diffDays).toBeGreaterThan(13);
    expect(diffDays).toBeLessThan(15);
    expect(newDate).toBeLessThanOrEqual(after + 14 * 24 * 60 * 60 * 1000 + 5000);
  });

  it('extends a past expiresAt from now (not from the past date)', async () => {
    const key = 'ADIA-BEXT-PST1-AAAA';
    const pastDate = new Date();
    pastDate.setDate(pastDate.getDate() - 5);
    insertLicense({ key, email: 'pst1@example.com', plan: 'monthly', expiresAt: pastDate.toISOString() });

    const res = await callPost({ keys: [key], days: 30 });
    expect(res.status).toBe(200);
    const body = await res.json();

    const newDate = new Date(body.changed[0].newExpiresAt);
    // Should be ~30 days from now, NOT ~25 days from now (past date + 30)
    const diffDays = (newDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24);
    expect(diffDays).toBeGreaterThan(28);
    expect(diffDays).toBeLessThan(32);
  });

  it('skips unknown keys with reason not_found', async () => {
    const res = await callPost({ keys: ['ADIA-BENF-UNKN-AAAA'], days: 7 });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0]).toMatchObject({ key: 'ADIA-BENF-UNKN-AAAA', reason: 'not_found' });
  });

  it('handles multiple keys with mixed outcomes', async () => {
    const k1 = 'ADIA-BEMK-KEY1-AAAA';
    const k2 = 'ADIA-BEMK-KEY2-AAAA';
    const k3 = 'ADIA-BEMK-UNKN-AAAA';
    const future = new Date();
    future.setDate(future.getDate() + 20);
    insertLicense({ key: k1, email: 'k1@example.com', plan: 'yearly', expiresAt: future.toISOString() });
    insertLicense({ key: k2, email: 'k2@example.com', plan: 'monthly', expiresAt: null });

    const res = await callPost({ keys: [k1, k2, k3], days: 7 });
    const body = await res.json();
    expect(body.changed).toHaveLength(2);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0]).toMatchObject({ key: k3, reason: 'not_found' });
    // Both changed keys have new expiry set
    const k1Updated = findLicense(k1);
    const k2Updated = findLicense(k2);
    expect(k1Updated?.expiresAt).toBeTruthy();
    expect(k2Updated?.expiresAt).toBeTruthy();
  });

  it('normalizes keys to uppercase', async () => {
    const key = 'ADIA-BEUC-CASE-AAAA';
    insertLicense({ key, email: 'case@example.com', plan: 'monthly', expiresAt: null });

    const res = await callPost({ keys: ['adia-beuc-case-aaaa'], days: 7 });
    const body = await res.json();
    expect(body.changed[0].key).toBe(key);
  });

  it('writes a bulk_extend audit log entry for each changed key', async () => {
    const k1 = 'ADIA-BEAL-LOG1-AAAA';
    const k2 = 'ADIA-BEAL-LOG2-AAAA';
    insertLicense({ key: k1, email: 'log1@example.com', plan: 'yearly', expiresAt: null });
    insertLicense({ key: k2, email: 'log2@example.com', plan: 'monthly', expiresAt: null });

    await callPost({ keys: [k1, k2], days: 10 });

    const log1 = listAuditLog({ licenseKey: k1, limit: 5 });
    expect(log1[0].action).toBe('bulk_extend');
    const detail1 = typeof log1[0].detail === 'string' ? JSON.parse(log1[0].detail) : log1[0].detail;
    expect(detail1).toMatchObject({ days: 10, bulk: true });

    const log2 = listAuditLog({ licenseKey: k2, limit: 5 });
    expect(log2[0].action).toBe('bulk_extend');
    const detail2 = typeof log2[0].detail === 'string' ? JSON.parse(log2[0].detail) : log2[0].detail;
    expect(detail2).toMatchObject({ days: 10, bulk: true });
  });
});
