import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, findLicense } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(os.tmpdir(), `adia-admin-issue-${Date.now()}-${Math.random().toString(36).slice(2)}.db`);
  resetDbForTesting(dbPath);
  process.env.ADMIN_TOKEN = 'test-admin-token';
});

afterEach(() => {
  resetDbForTesting();
  delete process.env.ADMIN_TOKEN;
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

async function callIssue(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/issue/route');
  const req = new NextRequest('http://localhost/api/admin/issue', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });
  return POST(req);
}

describe('POST /api/admin/issue — auth', () => {
  it('returns 401 with no token', async () => {
    const { POST } = await import('@/app/api/admin/issue/route');
    const req = new NextRequest('http://localhost/api/admin/issue', {
      method: 'POST',
      body: JSON.stringify({ email: 'a@b.com', plan: 'lifetime' }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callIssue({ email: 'a@b.com', plan: 'lifetime' }, 'wrong-token');
    expect(res.status).toBe(401);
  });
});

describe('POST /api/admin/issue — validation', () => {
  it('returns 400 when email is missing', async () => {
    const res = await callIssue({ plan: 'lifetime' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/email/);
  });

  it('returns 400 when plan is missing', async () => {
    const res = await callIssue({ email: 'a@b.com' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/plan/);
  });

  it('returns 400 for invalid plan value', async () => {
    const res = await callIssue({ email: 'a@b.com', plan: 'enterprise' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/plan/);
  });
});

describe('POST /api/admin/issue — lifetime license', () => {
  it('issues a lifetime license and returns the key', async () => {
    const res = await callIssue({ email: 'comp@example.com', plan: 'lifetime' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.key).toMatch(/^ADIA-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/);
    expect(body.email).toBe('comp@example.com');
    expect(body.plan).toBe('lifetime');
    expect(body.expiresAt).toBeNull();
  });

  it('persists the issued license to the database', async () => {
    const res = await callIssue({ email: 'persist@example.com', plan: 'lifetime' });
    const { key } = await res.json();
    const stored = findLicense(key);
    expect(stored).not.toBeNull();
    expect(stored!.email).toBe('persist@example.com');
    expect(stored!.plan).toBe('lifetime');
    expect(stored!.status).toBe('active');
    expect(stored!.expiresAt).toBeNull();
  });

  it('normalizes email to lowercase', async () => {
    const res = await callIssue({ email: 'User@EXAMPLE.COM', plan: 'lifetime' });
    const { key, email } = await res.json();
    expect(email).toBe('user@example.com');
    const stored = findLicense(key);
    expect(stored!.email).toBe('user@example.com');
  });
});

describe('POST /api/admin/issue — monthly/yearly expiry', () => {
  it('issues a monthly license with a non-null expiresAt', async () => {
    const before = new Date();
    const res = await callIssue({ email: 'monthly@example.com', plan: 'monthly' });
    const body = await res.json();
    expect(body.plan).toBe('monthly');
    expect(body.expiresAt).not.toBeNull();
    // Should expire roughly 31 days from now
    const expiresAt = new Date(body.expiresAt);
    const diffMs = expiresAt.getTime() - before.getTime();
    expect(diffMs).toBeGreaterThan(30 * 24 * 60 * 60 * 1000);
    expect(diffMs).toBeLessThan(32 * 24 * 60 * 60 * 1000);
  });

  it('issues a yearly license with a non-null expiresAt', async () => {
    const before = new Date();
    const res = await callIssue({ email: 'yearly@example.com', plan: 'yearly' });
    const body = await res.json();
    expect(body.plan).toBe('yearly');
    expect(body.expiresAt).not.toBeNull();
    const expiresAt = new Date(body.expiresAt);
    const diffMs = expiresAt.getTime() - before.getTime();
    expect(diffMs).toBeGreaterThan(365 * 24 * 60 * 60 * 1000);
    expect(diffMs).toBeLessThan(367 * 24 * 60 * 60 * 1000);
  });
});

describe('POST /api/admin/issue — optional note field', () => {
  it('echoes back the note when provided', async () => {
    const res = await callIssue({ email: 'noted@example.com', plan: 'lifetime', note: 'speaker comp' });
    const body = await res.json();
    expect(body.note).toBe('speaker comp');
  });

  it('returns null note when omitted', async () => {
    const res = await callIssue({ email: 'nonote@example.com', plan: 'lifetime' });
    const body = await res.json();
    expect(body.note).toBeNull();
  });
});

describe('POST /api/admin/issue — each call generates a unique key', () => {
  it('generates different keys for successive calls', async () => {
    const [r1, r2] = await Promise.all([
      callIssue({ email: 'u1@example.com', plan: 'lifetime' }),
      callIssue({ email: 'u2@example.com', plan: 'lifetime' }),
    ]);
    const b1 = await r1.json();
    const b2 = await r2.json();
    expect(b1.key).not.toBe(b2.key);
  });
});
