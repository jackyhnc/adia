// Tests for GET /api/admin/search-licenses and resend_payment_failed audit log.

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, listAuditLog, recordActivation } from '@/lib/db';

vi.mock('@/lib/email', () => ({
  sendLicenseEmail: vi.fn().mockResolvedValue(undefined),
  sendPaymentFailedEmail: vi.fn().mockResolvedValue(undefined),
}));

let dbPath: string;

beforeEach(() => {
  dbPath = path.join(
    os.tmpdir(),
    `adia-search-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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

async function callSearch(params: Record<string, string> = {}, token = 'test-admin-token') {
  const { GET } = await import('@/app/api/admin/search-licenses/route');
  const qs = new URLSearchParams(params).toString();
  const req = new NextRequest(`http://localhost/api/admin/search-licenses${qs ? `?${qs}` : ''}`, {
    method: 'GET',
    headers: authHeader(token),
  });
  return GET(req);
}

async function callResendPaymentFailed(body: Record<string, unknown>, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/resend-payment-failed/route');
  const req = new NextRequest('http://localhost/api/admin/resend-payment-failed', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', ...authHeader(token) },
  });
  return POST(req);
}

// ─── search-licenses ──────────────────────────────────────────────────────────

describe('GET /api/admin/search-licenses', () => {
  it('returns 401 without token', async () => {
    const res = await callSearch({ q: 'test' }, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('returns 400 when q is missing', async () => {
    const res = await callSearch({});
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing.*q/i);
  });

  it('returns 400 when q is blank', async () => {
    const res = await callSearch({ q: '   ' });
    expect(res.status).toBe(400);
  });

  it('returns empty results when no licenses match', async () => {
    const res = await callSearch({ q: 'nobody@nowhere.com' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(0);
    expect(body.results).toEqual([]);
  });

  it('matches by email substring', async () => {
    insertLicense({ key: 'ADIA-SRCH-EMAI-AAAA', email: 'alice@acme.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-SRCH-EMAI-BBBB', email: 'bob@other.com', plan: 'yearly', expiresAt: null });
    const res = await callSearch({ q: 'acme' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.results[0].key).toBe('ADIA-SRCH-EMAI-AAAA');
  });

  it('matches by license key substring', async () => {
    insertLicense({ key: 'ADIA-SRCH-KEYY-AAAA', email: 'test@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callSearch({ q: 'KEYY' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.results[0].key).toBe('ADIA-SRCH-KEYY-AAAA');
  });

  it('matches by note substring', async () => {
    insertLicense({ key: 'ADIA-SRCH-NOTE-AAAA', email: 'noted@example.com', plan: 'yearly', expiresAt: null });
    // set note via db directly
    const { setNote } = await import('@/lib/db');
    setNote('ADIA-SRCH-NOTE-AAAA', 'enterprise deal Q3');
    const res = await callSearch({ q: 'enterprise' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.results[0].key).toBe('ADIA-SRCH-NOTE-AAAA');
    expect(body.results[0].note).toBe('enterprise deal Q3');
  });

  it('returns multiple matches', async () => {
    insertLicense({ key: 'ADIA-SRCH-MULT-AAAA', email: 'user1@company.io', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-SRCH-MULT-BBBB', email: 'user2@company.io', plan: 'yearly', expiresAt: null });
    const res = await callSearch({ q: 'company.io' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(2);
  });

  it('respects limit parameter', async () => {
    for (let i = 1; i <= 5; i++) {
      insertLicense({ key: `ADIA-SRCH-LMT-${String(i).padStart(4, '0')}`, email: `lmt${i}@limit.com`, plan: 'monthly', expiresAt: null });
    }
    const res = await callSearch({ q: 'limit.com', limit: '2' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.results.length).toBe(2);
  });

  it('clamps limit to 100 max', async () => {
    const res = await callSearch({ q: 'x', limit: '999' });
    expect(res.status).toBe(200);
  });

  it('returns result fields: key, email, plan, status, issuedAt, expiresAt, note, machineCount', async () => {
    insertLicense({ key: 'ADIA-SRCH-FLDS-AAAA', email: 'fields@test.com', plan: 'lifetime', expiresAt: null });
    const res = await callSearch({ q: 'fields@test.com' });
    const body = await res.json();
    const r = body.results[0];
    expect(r.key).toBe('ADIA-SRCH-FLDS-AAAA');
    expect(r.email).toBe('fields@test.com');
    expect(r.plan).toBe('lifetime');
    expect(r.status).toBe('active');
    expect(r).toHaveProperty('issuedAt');
    expect(r).toHaveProperty('expiresAt');
    expect(r).toHaveProperty('note');
    expect(r).toHaveProperty('machineCount');
  });

  it('returns machineCount 0 when no activations exist', async () => {
    insertLicense({ key: 'ADIA-SRCH-MC0-AAAA', email: 'zero@machines.com', plan: 'monthly', expiresAt: null });
    const res = await callSearch({ q: 'zero@machines.com' });
    const body = await res.json();
    expect(body.results[0].machineCount).toBe(0);
  });

  it('returns machineCount equal to number of activations', async () => {
    insertLicense({ key: 'ADIA-SRCH-MC2-AAAA', email: 'two@machines.com', plan: 'yearly', expiresAt: null });
    recordActivation('ADIA-SRCH-MC2-AAAA', 'hash-machine-1');
    recordActivation('ADIA-SRCH-MC2-AAAA', 'hash-machine-2');
    const res = await callSearch({ q: 'two@machines.com' });
    const body = await res.json();
    expect(body.results[0].machineCount).toBe(2);
  });

  it('machineCount does not bleed across licenses in same search', async () => {
    insertLicense({ key: 'ADIA-SRCH-MCA-AAAA', email: 'multi@group.io', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-SRCH-MCB-BBBB', email: 'multi@group.io', plan: 'yearly', expiresAt: null });
    recordActivation('ADIA-SRCH-MCA-AAAA', 'hash-a-1');
    recordActivation('ADIA-SRCH-MCA-AAAA', 'hash-a-2');
    recordActivation('ADIA-SRCH-MCA-AAAA', 'hash-a-3');
    const res = await callSearch({ q: 'multi@group.io' });
    const body = await res.json();
    const byKey = Object.fromEntries(body.results.map((r: any) => [r.key, r.machineCount]));
    expect(byKey['ADIA-SRCH-MCA-AAAA']).toBe(3);
    expect(byKey['ADIA-SRCH-MCB-BBBB']).toBe(0);
  });

  it('accepts ?token= query param as auth fallback', async () => {
    const { GET } = await import('@/app/api/admin/search-licenses/route');
    const req = new NextRequest(
      'http://localhost/api/admin/search-licenses?q=x&token=test-admin-token',
      { method: 'GET' },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
  });

  // ─── pagination ─────────────────────────────────────────────────────────────

  it('response includes total, hasMore, offset, limit fields', async () => {
    insertLicense({ key: 'ADIA-SRCH-PAG0-AAAA', email: 'pag@page.io', plan: 'monthly', expiresAt: null });
    const res = await callSearch({ q: 'pag@page.io' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('total');
    expect(body).toHaveProperty('hasMore');
    expect(body).toHaveProperty('offset');
    expect(body).toHaveProperty('limit');
    expect(body.offset).toBe(0);
    expect(body.limit).toBe(20);
  });

  it('total reflects all matching records regardless of limit', async () => {
    for (let i = 1; i <= 5; i++) {
      insertLicense({ key: `ADIA-SRCH-TOT-${String(i).padStart(4, '0')}`, email: `tot${i}@total.dev`, plan: 'monthly', expiresAt: null });
    }
    const res = await callSearch({ q: 'total.dev', limit: '2' });
    const body = await res.json();
    expect(body.total).toBe(5);
    expect(body.count).toBe(2);
    expect(body.hasMore).toBe(true);
  });

  it('offset skips earlier results and returns the next page', async () => {
    for (let i = 1; i <= 6; i++) {
      insertLicense({ key: `ADIA-SRCH-OFF-${String(i).padStart(4, '0')}`, email: `off${i}@offset.dev`, plan: 'monthly', expiresAt: null });
    }
    const page1 = await (await callSearch({ q: 'offset.dev', limit: '4' })).json();
    const page2 = await (await callSearch({ q: 'offset.dev', limit: '4', offset: '4' })).json();
    expect(page1.results.length).toBe(4);
    expect(page2.results.length).toBe(2);
    expect(page2.hasMore).toBe(false);
    // No key overlap between pages
    const keys1 = new Set(page1.results.map((r: any) => r.key));
    const keys2 = new Set(page2.results.map((r: any) => r.key));
    for (const k of keys2) expect(keys1.has(k)).toBe(false);
  });

  it('hasMore is false on the last page', async () => {
    for (let i = 1; i <= 3; i++) {
      insertLicense({ key: `ADIA-SRCH-LAST-${String(i).padStart(4, '0')}`, email: `last${i}@lastpage.dev`, plan: 'yearly', expiresAt: null });
    }
    const res = await callSearch({ q: 'lastpage.dev', limit: '3', offset: '0' });
    const body = await res.json();
    expect(body.hasMore).toBe(false);
    expect(body.total).toBe(3);
    expect(body.count).toBe(3);
  });

  it('offset beyond total returns empty results with hasMore false', async () => {
    insertLicense({ key: 'ADIA-SRCH-OVFL-AAAA', email: 'ovfl@overflow.dev', plan: 'lifetime', expiresAt: null });
    const res = await callSearch({ q: 'overflow.dev', limit: '20', offset: '999' });
    const body = await res.json();
    expect(body.results).toEqual([]);
    expect(body.count).toBe(0);
    expect(body.total).toBe(1);
    expect(body.hasMore).toBe(false);
  });

  it('offset defaults to 0 when not provided', async () => {
    insertLicense({ key: 'ADIA-SRCH-DEF0-AAAA', email: 'def@default0.dev', plan: 'monthly', expiresAt: null });
    const res = await callSearch({ q: 'default0.dev' });
    const body = await res.json();
    expect(body.offset).toBe(0);
  });
});

// ─── resend_payment_failed audit log ─────────────────────────────────────────

describe('resend_payment_failed audit log', () => {
  it('records audit entry on successful resend (force=true)', async () => {
    insertLicense({ key: 'ADIA-RPFA-AUDI-AAAA', email: 'rpfa@example.com', plan: 'monthly', expiresAt: null });
    const res = await callResendPaymentFailed({ key: 'ADIA-RPFA-AUDI-AAAA', force: true });
    expect(res.status).toBe(200);
    const entries = listAuditLog({ licenseKey: 'ADIA-RPFA-AUDI-AAAA' });
    expect(entries.length).toBe(1);
    expect(entries[0].action).toBe('resend_payment_failed');
    const detail = JSON.parse(entries[0].detail ?? '{}');
    expect(detail.to).toBe('rpfa@example.com');
    expect(detail.force).toBe(true);
  });

  it('records audit entry for past_due license without force', async () => {
    const { setStatus } = await import('@/lib/db');
    insertLicense({ key: 'ADIA-RPFA-PDUE-AAAA', email: 'pdue@example.com', plan: 'monthly', expiresAt: null });
    setStatus('ADIA-RPFA-PDUE-AAAA', 'past_due');
    const res = await callResendPaymentFailed({ key: 'ADIA-RPFA-PDUE-AAAA' });
    expect(res.status).toBe(200);
    const entries = listAuditLog({ licenseKey: 'ADIA-RPFA-PDUE-AAAA' });
    expect(entries.length).toBe(1);
    expect(entries[0].action).toBe('resend_payment_failed');
  });

  it('does NOT record audit entry when 422 (not past_due, no force)', async () => {
    insertLicense({ key: 'ADIA-RPFA-SKIP-AAAA', email: 'skip@example.com', plan: 'monthly', expiresAt: null });
    const res = await callResendPaymentFailed({ key: 'ADIA-RPFA-SKIP-AAAA' });
    expect(res.status).toBe(422);
    const entries = listAuditLog({ licenseKey: 'ADIA-RPFA-SKIP-AAAA' });
    expect(entries.length).toBe(0);
  });

  it('does NOT record audit entry on 404 unknown key', async () => {
    const res = await callResendPaymentFailed({ key: 'ADIA-RPFA-UNKN-ZZZZ', force: true });
    expect(res.status).toBe(404);
    const entries = listAuditLog({ licenseKey: 'ADIA-RPFA-UNKN-ZZZZ' });
    expect(entries.length).toBe(0);
  });
});

// ─── lookup now returns { license, recentAudit } ────────────────────────────

describe('GET /api/admin/lookup includes recentAudit', () => {
  it('returns recentAudit array (empty when no audit entries)', async () => {
    insertLicense({ key: 'ADIA-LKPA-NAUD-AAAA', email: 'naud@example.com', plan: 'monthly', expiresAt: null });
    const { GET } = await import('@/app/api/admin/lookup/route');
    const req = new NextRequest('http://localhost/api/admin/lookup?key=ADIA-LKPA-NAUD-AAAA', {
      method: 'GET',
      headers: authHeader(),
    });
    const res = await GET(req);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.license.key).toBe('ADIA-LKPA-NAUD-AAAA');
    expect(body.recentAudit).toBeInstanceOf(Array);
    expect(body.recentAudit.length).toBe(0);
  });

  it('returns up to 5 most recent audit entries for the key', async () => {
    const { insertAuditLog } = await import('@/lib/db');
    insertLicense({ key: 'ADIA-LKPA-WAUD-AAAA', email: 'waud@example.com', plan: 'yearly', expiresAt: null });
    for (let i = 1; i <= 7; i++) {
      insertAuditLog({ licenseKey: 'ADIA-LKPA-WAUD-AAAA', action: `action_${i}` });
    }
    const { GET } = await import('@/app/api/admin/lookup/route');
    const req = new NextRequest('http://localhost/api/admin/lookup?key=ADIA-LKPA-WAUD-AAAA', {
      method: 'GET',
      headers: authHeader(),
    });
    const res = await GET(req);
    const body = await res.json();
    expect(body.recentAudit.length).toBe(5);
    // Should be newest-first
    expect(body.recentAudit[0].action).toBe('action_7');
  });
});
