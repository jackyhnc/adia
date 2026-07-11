import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, findLicense, listAuditLog } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(os.tmpdir(), `adia-bulk-issue-${Date.now()}-${Math.random().toString(36).slice(2)}.db`);
  resetDbForTesting(dbPath);
  process.env.ADMIN_TOKEN = 'test-admin-token';
});

afterEach(() => {
  resetDbForTesting();
  delete process.env.ADMIN_TOKEN;
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

async function callBulkIssue(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/bulk-issue/route');
  const req = new NextRequest('http://localhost/api/admin/bulk-issue', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });
  return POST(req);
}

// ─── Auth ────────────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-issue — auth', () => {
  it('returns 401 with no token', async () => {
    const { POST } = await import('@/app/api/admin/bulk-issue/route');
    const req = new NextRequest('http://localhost/api/admin/bulk-issue', {
      method: 'POST',
      body: JSON.stringify({ count: 1, plan: 'lifetime' }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callBulkIssue({ count: 1, plan: 'lifetime' }, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query param', async () => {
    const { POST } = await import('@/app/api/admin/bulk-issue/route');
    const req = new NextRequest(
      `http://localhost/api/admin/bulk-issue?token=test-admin-token`,
      {
        method: 'POST',
        body: JSON.stringify({ count: 1, plan: 'lifetime' }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ──────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-issue — validation', () => {
  it('returns 400 when count is missing', async () => {
    const res = await callBulkIssue({ plan: 'lifetime' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/count/);
  });

  it('returns 400 when count is zero', async () => {
    const res = await callBulkIssue({ count: 0, plan: 'lifetime' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/count/);
  });

  it('returns 400 when count is negative', async () => {
    const res = await callBulkIssue({ count: -5, plan: 'lifetime' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/count/);
  });

  it('returns 400 when count is fractional', async () => {
    const res = await callBulkIssue({ count: 2.5, plan: 'lifetime' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/count/);
  });

  it('returns 400 when count exceeds 50', async () => {
    const res = await callBulkIssue({ count: 51, plan: 'lifetime' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/≤ 50/);
  });

  it('returns 400 when plan is missing', async () => {
    const res = await callBulkIssue({ count: 3 });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/plan/);
  });

  it('returns 400 for invalid plan value', async () => {
    const res = await callBulkIssue({ count: 3, plan: 'enterprise' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/plan/);
  });

  it('returns 400 for invalid expiresAt string', async () => {
    const res = await callBulkIssue({ count: 1, plan: 'lifetime', expiresAt: 'not-a-date' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/expiresAt/);
  });

  it('returns 400 for numeric expiresAt', async () => {
    const res = await callBulkIssue({ count: 1, plan: 'lifetime', expiresAt: 12345 });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/expiresAt/);
  });
});

// ─── Core behavior ───────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-issue — core behavior', () => {
  it('generates exactly the requested number of keys', async () => {
    const res = await callBulkIssue({ count: 5, plan: 'lifetime' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.keys).toHaveLength(5);
    expect(body.count).toBe(5);
  });

  it('generates unique keys', async () => {
    const res = await callBulkIssue({ count: 10, plan: 'lifetime' });
    const { keys } = await res.json();
    expect(new Set(keys).size).toBe(10);
  });

  it('all keys match ADIA-XXXX-XXXX-XXXX pattern', async () => {
    const res = await callBulkIssue({ count: 3, plan: 'lifetime' });
    const { keys } = await res.json();
    for (const k of keys) {
      expect(k).toMatch(/^ADIA-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/);
    }
  });

  it('uses provided email (normalized to lowercase)', async () => {
    const res = await callBulkIssue({ count: 2, plan: 'lifetime', email: 'BATCH@EXAMPLE.COM' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.email).toBe('batch@example.com');
    for (const key of body.keys) {
      expect(findLicense(key)?.email).toBe('batch@example.com');
    }
  });

  it('defaults email to bulk@admin when omitted', async () => {
    const res = await callBulkIssue({ count: 2, plan: 'lifetime' });
    const body = await res.json();
    expect(body.email).toBe('bulk@admin');
    for (const key of body.keys) {
      expect(findLicense(key)?.email).toBe('bulk@admin');
    }
  });

  it('applies note to all generated keys', async () => {
    const res = await callBulkIssue({ count: 3, plan: 'lifetime', note: 'conference giveaway' });
    expect(res.status).toBe(200);
    const { keys } = await res.json();
    for (const key of keys) {
      const stored = findLicense(key);
      expect(stored?.note).toBe('conference giveaway');
    }
  });

  it('returns null note when omitted', async () => {
    const res = await callBulkIssue({ count: 1, plan: 'lifetime' });
    const body = await res.json();
    expect(body.note).toBeNull();
  });

  it('all generated keys are persisted in the database', async () => {
    const res = await callBulkIssue({ count: 4, plan: 'lifetime' });
    const { keys } = await res.json();
    for (const key of keys) {
      const stored = findLicense(key);
      expect(stored).not.toBeNull();
      expect(stored?.status).toBe('active');
      expect(stored?.plan).toBe('lifetime');
    }
  });

  it('writes one audit log entry per key with action=issued_bulk', async () => {
    const res = await callBulkIssue({ count: 3, plan: 'lifetime' });
    const { keys } = await res.json();
    for (const key of keys) {
      const logs = listAuditLog({ licenseKey: key });
      expect(logs).toHaveLength(1);
      expect(logs[0].action).toBe('issued_bulk');
    }
  });
});

// ─── Plan expiry ─────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-issue — expiry', () => {
  it('lifetime plan → null expiresAt', async () => {
    const res = await callBulkIssue({ count: 1, plan: 'lifetime' });
    const body = await res.json();
    expect(body.expiresAt).toBeNull();
    expect(findLicense(body.keys[0])?.expiresAt).toBeNull();
  });

  it('monthly plan → non-null expiresAt ~31 days out', async () => {
    const before = new Date();
    const res = await callBulkIssue({ count: 1, plan: 'monthly' });
    const body = await res.json();
    expect(body.expiresAt).not.toBeNull();
    const diff = new Date(body.expiresAt).getTime() - before.getTime();
    expect(diff).toBeGreaterThan(30 * 24 * 60 * 60 * 1000);
    expect(diff).toBeLessThan(32 * 24 * 60 * 60 * 1000);
  });

  it('yearly plan → non-null expiresAt ~366 days out', async () => {
    const before = new Date();
    const res = await callBulkIssue({ count: 1, plan: 'yearly' });
    const body = await res.json();
    expect(body.expiresAt).not.toBeNull();
    const diff = new Date(body.expiresAt).getTime() - before.getTime();
    expect(diff).toBeGreaterThan(365 * 24 * 60 * 60 * 1000);
    expect(diff).toBeLessThan(367 * 24 * 60 * 60 * 1000);
  });

  it('expiresAt=null override forces lifetime regardless of plan', async () => {
    const res = await callBulkIssue({ count: 2, plan: 'monthly', expiresAt: null });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.expiresAt).toBeNull();
    for (const key of body.keys) {
      expect(findLicense(key)?.expiresAt).toBeNull();
    }
  });

  it('expiresAt string override is stored on all keys', async () => {
    const future = '2032-12-31';
    const res = await callBulkIssue({ count: 2, plan: 'lifetime', expiresAt: future });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.expiresAt).toContain('2032-12-31');
    for (const key of body.keys) {
      expect(findLicense(key)?.expiresAt).toContain('2032-12-31');
    }
  });
});

// ─── Rate limit ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-issue — rate limit', () => {
  it('returns 429 after 20 requests from the same IP', async () => {
    const { POST } = await import('@/app/api/admin/bulk-issue/route');
    const ip = '10.98.5.1';
    let lastStatus = 0;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-issue', {
        method: 'POST',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
        body: JSON.stringify({}),
      });
      const res = await POST(req);
      lastStatus = res.status;
    }
    expect(lastStatus).toBe(429);
  });

  it('429 response includes Retry-After header', async () => {
    const { POST } = await import('@/app/api/admin/bulk-issue/route');
    const ip = '10.98.5.2';
    let lastRes: Response | null = null;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-issue', {
        method: 'POST',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
        body: JSON.stringify({}),
      });
      lastRes = await POST(req);
    }
    expect(lastRes?.headers.get('Retry-After')).toBeTruthy();
  });

  it('rate limit fires before auth check — wrong token still gets 429 when bucket exhausted', async () => {
    const { POST } = await import('@/app/api/admin/bulk-issue/route');
    const ip = '10.98.5.3';
    for (let i = 0; i < 20; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-issue', {
        method: 'POST',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
        body: JSON.stringify({}),
      });
      await POST(req);
    }
    const req = new NextRequest('http://localhost/api/admin/bulk-issue', {
      method: 'POST',
      headers: { Authorization: 'Bearer wrong-token', 'x-forwarded-for': ip },
      body: JSON.stringify({}),
    });
    const res = await POST(req);
    expect(res.status).toBe(429);
  });
});
