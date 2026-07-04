// Tests for POST /api/admin/bulk-set-expiry
// Body: { keys: string[], expiresAt: string | null }

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, findLicense, listAuditLog } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(
    os.tmpdir(),
    `adia-bulk-set-expiry-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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
  const { POST } = await import('@/app/api/admin/bulk-set-expiry/route');
  const req = new NextRequest('http://localhost/api/admin/bulk-set-expiry', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', ...authHeader(token) },
  });
  return POST(req);
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-set-expiry — auth', () => {
  it('returns 401 with no authorization header', async () => {
    const { POST } = await import('@/app/api/admin/bulk-set-expiry/route');
    const req = new NextRequest('http://localhost/api/admin/bulk-set-expiry', {
      method: 'POST',
      body: JSON.stringify({ keys: ['ADIA-XXXX-XXXX-XXXX'], expiresAt: '2030-01-01' }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callPost({ keys: ['ADIA-XXXX-XXXX-XXXX'], expiresAt: '2030-01-01' }, 'wrong');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query param as auth fallback', async () => {
    const key = 'ADIA-BSEQ-TOKN-AAAA';
    insertLicense({ key, email: 'tok@example.com', plan: 'monthly', expiresAt: null });
    const { POST } = await import('@/app/api/admin/bulk-set-expiry/route');
    const req = new NextRequest(
      'http://localhost/api/admin/bulk-set-expiry?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ keys: [key], expiresAt: '2030-01-01' }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
    expect((await res.json()).ok).toBe(true);
  });
});

// ─── Validation ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-set-expiry — validation', () => {
  it('returns 400 when keys is missing', async () => {
    const res = await callPost({ expiresAt: '2030-01-01' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/missing or empty keys/i);
  });

  it('returns 400 when keys is an empty array', async () => {
    const res = await callPost({ keys: [], expiresAt: '2030-01-01' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/missing or empty keys/i);
  });

  it('returns 400 when keys exceeds 100', async () => {
    const keys = Array.from({ length: 101 }, (_, i) => `ADIA-BSEX-${String(i).padStart(4, '0')}-AAAA`);
    const res = await callPost({ keys, expiresAt: '2030-01-01' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/too many keys/i);
  });

  it('returns 400 when expiresAt is missing from body', async () => {
    const res = await callPost({ keys: ['ADIA-XXXX-XXXX-AAAA'] });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/missing expiresAt/i);
  });

  it('returns 400 when expiresAt is not a valid ISO date string', async () => {
    const res = await callPost({ keys: ['ADIA-XXXX-XXXX-AAAA'], expiresAt: 'not-a-date' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/ISO-8601/i);
  });

  it('returns 400 when expiresAt is a number', async () => {
    const res = await callPost({ keys: ['ADIA-XXXX-XXXX-AAAA'], expiresAt: 123456 });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/ISO-8601/i);
  });
});

// ─── Core logic ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-set-expiry — set logic', () => {
  it('sets a future expiresAt on a license with no prior expiry', async () => {
    const key = 'ADIA-BSEA-FUT1-AAAA';
    insertLicense({ key, email: 'fut1@example.com', plan: 'monthly', expiresAt: null });

    const res = await callPost({ keys: [key], expiresAt: '2030-06-30' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.changed).toHaveLength(1);
    expect(body.skipped).toHaveLength(0);

    const result = body.changed[0];
    expect(result.key).toBe(key);
    expect(result.previousExpiresAt).toBeNull();
    expect(new Date(result.newExpiresAt).getFullYear()).toBe(2030);

    const updated = findLicense(key);
    expect(updated?.expiresAt).toBe(result.newExpiresAt);
  });

  it('overwrites an existing future expiresAt', async () => {
    const key = 'ADIA-BSEA-OVW1-AAAA';
    const oldExpiry = '2025-03-01T00:00:00.000Z';
    insertLicense({ key, email: 'ovw1@example.com', plan: 'yearly', expiresAt: oldExpiry });

    const res = await callPost({ keys: [key], expiresAt: '2030-12-31' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed[0].previousExpiresAt).toBe(oldExpiry);
    expect(new Date(body.changed[0].newExpiresAt).getFullYear()).toBe(2030);

    const updated = findLicense(key);
    expect(updated?.expiresAt).toBe(body.changed[0].newExpiresAt);
  });

  it('converts a time-based license to lifetime (expiresAt: null)', async () => {
    const key = 'ADIA-BSEA-LFT1-AAAA';
    const existing = '2026-01-01T00:00:00.000Z';
    insertLicense({ key, email: 'lft1@example.com', plan: 'yearly', expiresAt: existing });

    const res = await callPost({ keys: [key], expiresAt: null });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed[0].previousExpiresAt).toBe(existing);
    expect(body.changed[0].newExpiresAt).toBeNull();

    const updated = findLicense(key);
    expect(updated?.expiresAt ?? null).toBeNull();
  });

  it('sets a past date (immediate expiry)', async () => {
    const key = 'ADIA-BSEA-PST1-AAAA';
    insertLicense({ key, email: 'pst1@example.com', plan: 'monthly', expiresAt: null });

    const res = await callPost({ keys: [key], expiresAt: '2020-01-01' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(new Date(body.changed[0].newExpiresAt).getFullYear()).toBe(2020);

    const updated = findLicense(key);
    expect(new Date(updated?.expiresAt ?? '').getFullYear()).toBe(2020);
  });

  it('skips unknown keys with reason not_found', async () => {
    const res = await callPost({ keys: ['ADIA-BSEN-UNKN-AAAA'], expiresAt: '2030-01-01' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0]).toMatchObject({ key: 'ADIA-BSEN-UNKN-AAAA', reason: 'not_found' });
  });

  it('skips keys whose expiresAt already matches the target value', async () => {
    const key = 'ADIA-BSEA-NOOP-AAAA';
    const expiry = '2030-06-01T00:00:00.000Z';
    insertLicense({ key, email: 'noop@example.com', plan: 'yearly', expiresAt: expiry });

    const res = await callPost({ keys: [key], expiresAt: expiry });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped[0]).toMatchObject({ key, reason: 'already_set' });
  });

  it('skips null→null no-op (already lifetime)', async () => {
    const key = 'ADIA-BSEA-NLTM-AAAA';
    insertLicense({ key, email: 'nltm@example.com', plan: 'lifetime', expiresAt: null });

    const res = await callPost({ keys: [key], expiresAt: null });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped[0]).toMatchObject({ key, reason: 'already_set' });
  });

  it('handles multiple keys with mixed outcomes', async () => {
    const k1 = 'ADIA-BSMK-KEY1-AAAA';
    const k2 = 'ADIA-BSMK-KEY2-AAAA';
    const k3 = 'ADIA-BSMK-UNKN-AAAA';
    insertLicense({ key: k1, email: 'k1@example.com', plan: 'yearly', expiresAt: null });
    insertLicense({ key: k2, email: 'k2@example.com', plan: 'monthly', expiresAt: null });

    const res = await callPost({ keys: [k1, k2, k3], expiresAt: '2031-01-01' });
    const body = await res.json();
    expect(body.changed).toHaveLength(2);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0]).toMatchObject({ key: k3, reason: 'not_found' });

    const k1Updated = findLicense(k1);
    const k2Updated = findLicense(k2);
    expect(k1Updated?.expiresAt).toBeTruthy();
    expect(k2Updated?.expiresAt).toBeTruthy();
  });

  it('normalizes keys to uppercase', async () => {
    const key = 'ADIA-BSUC-CASE-AAAA';
    insertLicense({ key, email: 'case@example.com', plan: 'monthly', expiresAt: null });

    const res = await callPost({ keys: ['adia-bsuc-case-aaaa'], expiresAt: '2030-01-01' });
    const body = await res.json();
    expect(body.changed[0].key).toBe(key);
  });

  it('normalizes date-only expiresAt to full ISO string', async () => {
    const key = 'ADIA-BSNM-DATE-AAAA';
    insertLicense({ key, email: 'date@example.com', plan: 'monthly', expiresAt: null });

    const res = await callPost({ keys: [key], expiresAt: '2030-06-15' });
    const body = await res.json();
    // Should be a full ISO string, not just 'YYYY-MM-DD'
    expect(body.changed[0].newExpiresAt).toMatch(/T/);
    expect(new Date(body.changed[0].newExpiresAt).toISOString()).toBeTruthy();
  });

  it('writes a bulk_set_expiry audit log entry for each changed key', async () => {
    const k1 = 'ADIA-BSAL-LOG1-AAAA';
    const k2 = 'ADIA-BSAL-LOG2-AAAA';
    insertLicense({ key: k1, email: 'log1@example.com', plan: 'yearly', expiresAt: null });
    insertLicense({ key: k2, email: 'log2@example.com', plan: 'monthly', expiresAt: null });

    await callPost({ keys: [k1, k2], expiresAt: '2031-01-01' });

    const log1 = listAuditLog({ licenseKey: k1, limit: 5 });
    expect(log1[0].action).toBe('bulk_set_expiry');
    const detail1 = typeof log1[0].detail === 'string' ? JSON.parse(log1[0].detail) : log1[0].detail;
    expect(detail1).toMatchObject({ bulk: true, newExpiresAt: expect.stringContaining('2031') });

    const log2 = listAuditLog({ licenseKey: k2, limit: 5 });
    expect(log2[0].action).toBe('bulk_set_expiry');
    const detail2 = typeof log2[0].detail === 'string' ? JSON.parse(log2[0].detail) : log2[0].detail;
    expect(detail2).toMatchObject({ bulk: true });
  });

  it('does not write an audit log entry for skipped keys', async () => {
    const key = 'ADIA-BSNS-NLOG-AAAA';
    insertLicense({ key, email: 'nlog@example.com', plan: 'monthly', expiresAt: null });

    // No-op: already lifetime, set to null again
    await callPost({ keys: [key], expiresAt: null });

    const log = listAuditLog({ licenseKey: key, limit: 5 });
    const bulkEntries = log.filter((e) => e.action === 'bulk_set_expiry');
    expect(bulkEntries).toHaveLength(0);
  });
});
