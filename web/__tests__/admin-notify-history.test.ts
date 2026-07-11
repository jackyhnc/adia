// Tests for GET /api/admin/notify-history?email=...
// Returns all 'notify' audit log entries for all license keys belonging to an email.

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, insertAuditLog } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(
    os.tmpdir(),
    `adia-notify-history-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
  );
  resetDbForTesting(dbPath);
  process.env.ADMIN_TOKEN = 'test-admin-token';
});

afterEach(() => {
  resetDbForTesting();
  delete process.env.ADMIN_TOKEN;
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

async function callNotifyHistory(
  params: Record<string, string>,
  token = 'test-admin-token',
) {
  const { GET } = await import('@/app/api/admin/notify-history/route');
  const qs = new URLSearchParams(params).toString();
  const req = new NextRequest(`http://localhost/api/admin/notify-history?${qs}`, {
    method: 'GET',
    headers: { Authorization: `Bearer ${token}` },
  });
  return GET(req);
}

function seedLicense(key: string, email: string, plan: 'monthly' | 'yearly' | 'lifetime' = 'lifetime') {
  insertLicense({ key, email, plan, expiresAt: null });
}

function seedNotify(key: string, to: string, subject: string) {
  insertAuditLog({ licenseKey: key, action: 'notify', detail: { to, subject } });
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('GET /api/admin/notify-history — auth', () => {
  it('returns 401 with no token', async () => {
    const { GET } = await import('@/app/api/admin/notify-history/route');
    const req = new NextRequest(
      'http://localhost/api/admin/notify-history?email=x@x.com',
      { method: 'GET' },
    );
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callNotifyHistory({ email: 'x@x.com' }, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query param', async () => {
    const { GET } = await import('@/app/api/admin/notify-history/route');
    const req = new NextRequest(
      'http://localhost/api/admin/notify-history?email=x%40x.com&token=test-admin-token',
      { method: 'GET' },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ───────────────────────────────────────────────────────────────

describe('GET /api/admin/notify-history — validation', () => {
  it('returns 400 when ?email= is missing', async () => {
    const { GET } = await import('@/app/api/admin/notify-history/route');
    const req = new NextRequest('http://localhost/api/admin/notify-history', {
      method: 'GET',
      headers: { Authorization: 'Bearer test-admin-token' },
    });
    const res = await GET(req);
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/email/);
  });

  it('returns 400 when ?email= is blank', async () => {
    const res = await callNotifyHistory({ email: '   ' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/email/);
  });
});

// ─── Core behavior ────────────────────────────────────────────────────────────

describe('GET /api/admin/notify-history — core behavior', () => {
  it('returns empty entries for an email with no notify history', async () => {
    seedLicense('ADIA-NHX-EMPTY-0001', 'empty@example.com');
    const res = await callNotifyHistory({ email: 'empty@example.com' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(0);
    expect(body.entries).toHaveLength(0);
    expect(body.hasMore).toBe(false);
  });

  it('returns empty entries for an unknown email', async () => {
    const res = await callNotifyHistory({ email: 'ghost@example.com' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(0);
    expect(body.entries).toHaveLength(0);
  });

  it('returns notify entries for an email with one license key', async () => {
    seedLicense('ADIA-NHX-ONE-0001', 'one@example.com');
    seedNotify('ADIA-NHX-ONE-0001', 'one@example.com', 'Hello from Adia');
    const res = await callNotifyHistory({ email: 'one@example.com' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.entries).toHaveLength(1);
    expect(body.entries[0].action).toBe('notify');
    expect(body.entries[0].licenseKey).toBe('ADIA-NHX-ONE-0001');
  });

  it('detail field contains to and subject', async () => {
    seedLicense('ADIA-NHX-DTL-0001', 'detail@example.com');
    seedNotify('ADIA-NHX-DTL-0001', 'detail@example.com', 'Your account update');
    const res = await callNotifyHistory({ email: 'detail@example.com' });
    const body = await res.json();
    const detail = JSON.parse(body.entries[0].detail);
    expect(detail.to).toBe('detail@example.com');
    expect(detail.subject).toBe('Your account update');
  });

  it('normalizes email to lowercase when querying', async () => {
    seedLicense('ADIA-NHX-CAS-0001', 'case@example.com');
    seedNotify('ADIA-NHX-CAS-0001', 'case@example.com', 'Case test');
    const res = await callNotifyHistory({ email: 'CASE@EXAMPLE.COM' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.email).toBe('case@example.com');
  });

  it('response echoes email normalized to lowercase', async () => {
    const res = await callNotifyHistory({ email: 'UPPER@EXAMPLE.COM' });
    const body = await res.json();
    expect(body.email).toBe('upper@example.com');
  });

  it('aggregates notify entries across multiple license keys for the same email', async () => {
    seedLicense('ADIA-NHX-MULTI-0001', 'multi@example.com');
    seedLicense('ADIA-NHX-MULTI-0002', 'multi@example.com');
    seedNotify('ADIA-NHX-MULTI-0001', 'multi@example.com', 'First key email');
    seedNotify('ADIA-NHX-MULTI-0002', 'multi@example.com', 'Second key email');
    const res = await callNotifyHistory({ email: 'multi@example.com' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(2);
    expect(body.entries).toHaveLength(2);
  });

  it('does not include non-notify audit log entries', async () => {
    seedLicense('ADIA-NHX-NONLY-0001', 'nonly@example.com');
    insertAuditLog({ licenseKey: 'ADIA-NHX-NONLY-0001', action: 'activate' });
    insertAuditLog({ licenseKey: 'ADIA-NHX-NONLY-0001', action: 'revoke' });
    seedNotify('ADIA-NHX-NONLY-0001', 'nonly@example.com', 'Only this one');
    const res = await callNotifyHistory({ email: 'nonly@example.com' });
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.entries[0].action).toBe('notify');
  });

  it('does not bleed entries across different customer emails', async () => {
    seedLicense('ADIA-NHX-BLDA-0001', 'bleed-a@example.com');
    seedLicense('ADIA-NHX-BLDB-0001', 'bleed-b@example.com');
    seedNotify('ADIA-NHX-BLDA-0001', 'bleed-a@example.com', 'Email for A');
    seedNotify('ADIA-NHX-BLDA-0001', 'bleed-a@example.com', 'Another for A');
    seedNotify('ADIA-NHX-BLDB-0001', 'bleed-b@example.com', 'Email for B');
    const resA = await callNotifyHistory({ email: 'bleed-a@example.com' });
    const resB = await callNotifyHistory({ email: 'bleed-b@example.com' });
    const bodyA = await resA.json();
    const bodyB = await resB.json();
    expect(bodyA.count).toBe(2);
    expect(bodyB.count).toBe(1);
  });

  it('returns entries ordered newest-first', async () => {
    seedLicense('ADIA-NHX-ORD-0001', 'order@example.com');
    seedNotify('ADIA-NHX-ORD-0001', 'order@example.com', 'First sent');
    seedNotify('ADIA-NHX-ORD-0001', 'order@example.com', 'Second sent');
    seedNotify('ADIA-NHX-ORD-0001', 'order@example.com', 'Third sent');
    const res = await callNotifyHistory({ email: 'order@example.com' });
    const body = await res.json();
    const subjects = body.entries.map((e: any) => JSON.parse(e.detail).subject);
    expect(subjects[0]).toBe('Third sent');
    expect(subjects[2]).toBe('First sent');
  });
});

// ─── Pagination ───────────────────────────────────────────────────────────────

describe('GET /api/admin/notify-history — pagination', () => {
  it('returns hasMore=false and offset=0 when all results fit on one page', async () => {
    seedLicense('ADIA-NHX-PG1-0001', 'pg1@example.com');
    seedNotify('ADIA-NHX-PG1-0001', 'pg1@example.com', 'Msg 1');
    seedNotify('ADIA-NHX-PG1-0001', 'pg1@example.com', 'Msg 2');
    const res = await callNotifyHistory({ email: 'pg1@example.com' });
    const body = await res.json();
    expect(body.hasMore).toBe(false);
    expect(body.offset).toBe(0);
    expect(body.entries).toHaveLength(2);
  });

  it('count reflects total even when limit caps the page', async () => {
    seedLicense('ADIA-NHX-PG2-0001', 'pg2@example.com');
    for (let i = 0; i < 5; i++) {
      seedNotify('ADIA-NHX-PG2-0001', 'pg2@example.com', `Msg ${i}`);
    }
    const res = await callNotifyHistory({ email: 'pg2@example.com', limit: '2', offset: '0' });
    const body = await res.json();
    expect(body.count).toBe(5);
    expect(body.entries).toHaveLength(2);
    expect(body.hasMore).toBe(true);
  });

  it('offset skips earlier records and returns the next page', async () => {
    seedLicense('ADIA-NHX-PG3-0001', 'pg3@example.com');
    for (let i = 0; i < 4; i++) {
      seedNotify('ADIA-NHX-PG3-0001', 'pg3@example.com', `Msg ${i}`);
    }
    const res = await callNotifyHistory({ email: 'pg3@example.com', limit: '2', offset: '2' });
    const body = await res.json();
    expect(body.count).toBe(4);
    expect(body.entries).toHaveLength(2);
    expect(body.hasMore).toBe(false);
  });

  it('limit exceeding MAX_LIMIT (100) is capped to 100', async () => {
    seedLicense('ADIA-NHX-PG4-0001', 'pg4@example.com');
    seedNotify('ADIA-NHX-PG4-0001', 'pg4@example.com', 'Solo');
    const res = await callNotifyHistory({ email: 'pg4@example.com', limit: '999' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.entries).toHaveLength(1);
    expect(body.limit).toBe(100);
  });

  it('invalid limit falls back to default (20)', async () => {
    seedLicense('ADIA-NHX-PG5-0001', 'pg5@example.com');
    seedNotify('ADIA-NHX-PG5-0001', 'pg5@example.com', 'Solo');
    const res = await callNotifyHistory({ email: 'pg5@example.com', limit: 'abc' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.limit).toBe(20);
    expect(body.entries).toHaveLength(1);
  });
});

// ─── Rate limit ───────────────────────────────────────────────────────────────

describe('GET /api/admin/notify-history — rate limit', () => {
  it('returns 429 after 20 requests from the same IP', async () => {
    const { GET } = await import('@/app/api/admin/notify-history/route');
    const ip = '10.96.1.1';
    let lastStatus = 0;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/notify-history?email=x@example.com', {
        method: 'GET',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
      });
      const res = await GET(req);
      lastStatus = res.status;
    }
    expect(lastStatus).toBe(429);
  });

  it('429 response includes Retry-After header', async () => {
    const { GET } = await import('@/app/api/admin/notify-history/route');
    const ip = '10.96.1.2';
    let lastRes: Response | null = null;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/notify-history?email=x@example.com', {
        method: 'GET',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
      });
      lastRes = await GET(req);
    }
    expect(lastRes?.headers.get('Retry-After')).toBeTruthy();
  });

  it('rate limit fires before auth check — wrong token still gets 429 when bucket exhausted', async () => {
    const { GET } = await import('@/app/api/admin/notify-history/route');
    const ip = '10.96.1.3';
    for (let i = 0; i < 20; i++) {
      const req = new NextRequest('http://localhost/api/admin/notify-history?email=x@example.com', {
        method: 'GET',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
      });
      await GET(req);
    }
    const req = new NextRequest('http://localhost/api/admin/notify-history?email=x@example.com', {
      method: 'GET',
      headers: { Authorization: 'Bearer wrong-token', 'x-forwarded-for': ip },
    });
    const res = await GET(req);
    expect(res.status).toBe(429);
  });
});
