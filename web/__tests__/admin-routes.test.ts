// Tests for admin routes:
//   GET/DELETE /api/admin/activations
//   POST       /api/admin/revoke
//   GET        /api/admin/lookup
//   GET        /api/admin/licenses-by-email
//   POST       /api/admin/resend-payment-failed
//   POST       /api/admin/resend-license
//
// All routes require ADMIN_TOKEN; SQLite DB is reset per test.

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, recordActivation, findLicense } from '@/lib/db';

vi.mock('@/lib/email', () => ({
  sendLicenseEmail: vi.fn().mockResolvedValue(undefined),
  sendPaymentFailedEmail: vi.fn().mockResolvedValue(undefined),
}));

import { sendPaymentFailedEmail, sendLicenseEmail } from '@/lib/email';
const mockSendPaymentFailedEmail = vi.mocked(sendPaymentFailedEmail);
const mockSendLicenseEmail = vi.mocked(sendLicenseEmail);

let dbPath: string;

beforeEach(() => {
  dbPath = path.join(
    os.tmpdir(),
    `adia-admin-routes-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
  );
  resetDbForTesting(dbPath);
  process.env.ADMIN_TOKEN = 'test-admin-token';
  mockSendPaymentFailedEmail.mockReset();
  mockSendPaymentFailedEmail.mockResolvedValue(undefined);
  mockSendLicenseEmail.mockReset();
  mockSendLicenseEmail.mockResolvedValue(undefined);
});

afterEach(() => {
  resetDbForTesting();
  delete process.env.ADMIN_TOKEN;
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

function authHeader(token = 'test-admin-token') {
  return { Authorization: `Bearer ${token}` };
}

async function callActivationsGet(key: string, token = 'test-admin-token') {
  const { GET } = await import('@/app/api/admin/activations/route');
  const req = new NextRequest(
    `http://localhost/api/admin/activations?key=${encodeURIComponent(key)}`,
    { method: 'GET', headers: authHeader(token) },
  );
  return GET(req);
}

async function callActivationsDelete(key: string, machine: string, token = 'test-admin-token') {
  const { DELETE } = await import('@/app/api/admin/activations/route');
  const req = new NextRequest(
    `http://localhost/api/admin/activations?key=${encodeURIComponent(key)}&machine=${encodeURIComponent(machine)}`,
    { method: 'DELETE', headers: authHeader(token) },
  );
  return DELETE(req);
}

async function callRevoke(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/revoke/route');
  const req = new NextRequest('http://localhost/api/admin/revoke', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', ...authHeader(token) },
  });
  return POST(req);
}

async function callLookup(key: string, token = 'test-admin-token') {
  const { GET } = await import('@/app/api/admin/lookup/route');
  const req = new NextRequest(
    `http://localhost/api/admin/lookup?key=${encodeURIComponent(key)}`,
    { method: 'GET', headers: authHeader(token) },
  );
  return GET(req);
}

async function callLicensesByEmail(email: string, token = 'test-admin-token') {
  const { GET } = await import('@/app/api/admin/licenses-by-email/route');
  const req = new NextRequest(
    `http://localhost/api/admin/licenses-by-email?email=${encodeURIComponent(email)}`,
    { method: 'GET', headers: authHeader(token) },
  );
  return GET(req);
}

// ─── /api/admin/activations GET ──────────────────────────────────────────────

describe('GET /api/admin/activations', () => {
  it('returns 401 with no token', async () => {
    const { GET } = await import('@/app/api/admin/activations/route');
    const req = new NextRequest('http://localhost/api/admin/activations?key=ADIA-XXXX-XXXX-XXXX', {
      method: 'GET',
    });
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callActivationsGet('ADIA-XXXX-XXXX-XXXX', 'bad-token');
    expect(res.status).toBe(401);
  });

  it('returns 400 when key param is missing', async () => {
    const { GET } = await import('@/app/api/admin/activations/route');
    const req = new NextRequest('http://localhost/api/admin/activations', {
      method: 'GET',
      headers: authHeader(),
    });
    const res = await GET(req);
    expect(res.status).toBe(400);
  });

  it('returns 404 for unknown key', async () => {
    const res = await callActivationsGet('ADIA-UNKN-UNKN-UNKN');
    expect(res.status).toBe(404);
  });

  it('returns empty activations list for a key with no activations', async () => {
    insertLicense({ key: 'ADIA-NOAC-TVNS-AAAA', email: 'noact@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callActivationsGet('ADIA-NOAC-TVNS-AAAA');
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.key).toBe('ADIA-NOAC-TVNS-AAAA');
    expect(body.seatCount).toBe(0);
    expect(body.activations).toEqual([]);
  });

  it('returns activations with correct seat count', async () => {
    insertLicense({ key: 'ADIA-ACNT-LIST-AAAA', email: 'listed@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation('ADIA-ACNT-LIST-AAAA', 'machine-alpha');
    recordActivation('ADIA-ACNT-LIST-AAAA', 'machine-beta');

    const res = await callActivationsGet('ADIA-ACNT-LIST-AAAA');
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.seatCount).toBe(2);
    expect(body.activations).toHaveLength(2);
    const hashes = body.activations.map((a: any) => a.machineHash);
    expect(hashes).toContain('machine-alpha');
    expect(hashes).toContain('machine-beta');
  });

  it('returns license metadata alongside activations', async () => {
    insertLicense({ key: 'ADIA-META-CHCK-AAAA', email: 'meta@example.com', plan: 'yearly', expiresAt: '2027-01-01T00:00:00.000Z' });
    const res = await callActivationsGet('ADIA-META-CHCK-AAAA');
    const body = await res.json();
    expect(body.email).toBe('meta@example.com');
    expect(body.plan).toBe('yearly');
    expect(body.status).toBe('active');
  });
});

// ─── /api/admin/activations DELETE ───────────────────────────────────────────

describe('DELETE /api/admin/activations', () => {
  it('returns 401 with no token', async () => {
    const { DELETE } = await import('@/app/api/admin/activations/route');
    const req = new NextRequest(
      'http://localhost/api/admin/activations?key=ADIA-XXXX-XXXX-XXXX&machine=m1',
      { method: 'DELETE' },
    );
    const res = await DELETE(req);
    expect(res.status).toBe(401);
  });

  it('returns 400 when key is missing', async () => {
    const { DELETE } = await import('@/app/api/admin/activations/route');
    const req = new NextRequest('http://localhost/api/admin/activations?machine=m1', {
      method: 'DELETE',
      headers: authHeader(),
    });
    const res = await DELETE(req);
    expect(res.status).toBe(400);
  });

  it('returns 400 when machine is missing', async () => {
    const { DELETE } = await import('@/app/api/admin/activations/route');
    const req = new NextRequest('http://localhost/api/admin/activations?key=ADIA-XXXX-XXXX-XXXX', {
      method: 'DELETE',
      headers: authHeader(),
    });
    const res = await DELETE(req);
    expect(res.status).toBe(400);
  });

  it('returns 404 for unknown license key', async () => {
    const res = await callActivationsDelete('ADIA-UNKN-UNKN-UNKN', 'machine-x');
    expect(res.status).toBe(404);
  });

  it('removes a machine activation and returns updated seat count', async () => {
    insertLicense({ key: 'ADIA-RMVD-MACH-AAAA', email: 'rm@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation('ADIA-RMVD-MACH-AAAA', 'machine-to-remove');
    recordActivation('ADIA-RMVD-MACH-AAAA', 'machine-to-keep');

    const res = await callActivationsDelete('ADIA-RMVD-MACH-AAAA', 'machine-to-remove');
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.seatsNow).toBe(1);
  });

  it('deleting a non-existent machine is a no-op (idempotent)', async () => {
    insertLicense({ key: 'ADIA-NOOP-MACH-AAAA', email: 'noop@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation('ADIA-NOOP-MACH-AAAA', 'machine-existing');

    const res = await callActivationsDelete('ADIA-NOOP-MACH-AAAA', 'machine-ghost');
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.seatsNow).toBe(1); // existing machine still there
  });
});

// ─── /api/admin/revoke ────────────────────────────────────────────────────────

describe('POST /api/admin/revoke', () => {
  it('returns 401 with no token', async () => {
    const { POST } = await import('@/app/api/admin/revoke/route');
    const req = new NextRequest('http://localhost/api/admin/revoke', {
      method: 'POST',
      body: JSON.stringify({ key: 'ADIA-XXXX-XXXX-XXXX' }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callRevoke({ key: 'ADIA-XXXX-XXXX-XXXX' }, 'bad-token');
    expect(res.status).toBe(401);
  });

  it('returns 400 when key is missing from body', async () => {
    const res = await callRevoke({});
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing key/i);
  });

  it('returns 404 for unknown key', async () => {
    const res = await callRevoke({ key: 'ADIA-UNKN-UNKN-UNKN' });
    expect(res.status).toBe(404);
  });

  it('revokes an active license and returns previousStatus', async () => {
    insertLicense({ key: 'ADIA-RVKE-LIVE-AAAA', email: 'revoke@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callRevoke({ key: 'ADIA-RVKE-LIVE-AAAA' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.previousStatus).toBe('active');
    expect(body.newStatus).toBe('canceled');
  });

  it('persists canceled status to the database', async () => {
    insertLicense({ key: 'ADIA-RVKE-DBCK-AAAA', email: 'revokedb@example.com', plan: 'monthly', expiresAt: null });
    await callRevoke({ key: 'ADIA-RVKE-DBCK-AAAA' });
    const license = findLicense('ADIA-RVKE-DBCK-AAAA');
    expect(license!.status).toBe('canceled');
  });

  it('normalizes key to uppercase before lookup', async () => {
    insertLicense({ key: 'ADIA-CASE-NORM-AAAA', email: 'casetest@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callRevoke({ key: 'adia-case-norm-aaaa' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.key).toBe('ADIA-CASE-NORM-AAAA');
  });

  it('revoking an already-canceled license still returns 200', async () => {
    insertLicense({ key: 'ADIA-DBLS-RVKE-AAAA', email: 'double@example.com', plan: 'lifetime', expiresAt: null });
    await callRevoke({ key: 'ADIA-DBLS-RVKE-AAAA' });
    const res2 = await callRevoke({ key: 'ADIA-DBLS-RVKE-AAAA' });
    expect(res2.status).toBe(200);
    const body = await res2.json();
    expect(body.newStatus).toBe('canceled');
  });
});

// ─── /api/admin/lookup ───────────────────────────────────────────────────────

describe('GET /api/admin/lookup', () => {
  it('returns 401 with no token', async () => {
    const { GET } = await import('@/app/api/admin/lookup/route');
    const req = new NextRequest('http://localhost/api/admin/lookup?key=ADIA-XXXX-XXXX-XXXX', {
      method: 'GET',
    });
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callLookup('ADIA-XXXX-XXXX-XXXX', 'bad-token');
    expect(res.status).toBe(401);
  });

  it('returns 400 when key param is missing', async () => {
    const { GET } = await import('@/app/api/admin/lookup/route');
    const req = new NextRequest('http://localhost/api/admin/lookup', {
      method: 'GET',
      headers: authHeader(),
    });
    const res = await GET(req);
    expect(res.status).toBe(400);
  });

  it('returns 404 for unknown key', async () => {
    const res = await callLookup('ADIA-UNKN-UNKN-UNKN');
    expect(res.status).toBe(404);
  });

  it('returns license data for a known key', async () => {
    insertLicense({ key: 'ADIA-LKUP-HPPY-AAAA', email: 'lookup@example.com', plan: 'yearly', expiresAt: '2027-07-01T00:00:00.000Z' });
    const res = await callLookup('ADIA-LKUP-HPPY-AAAA');
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.key).toBe('ADIA-LKUP-HPPY-AAAA');
    expect(body.email).toBe('lookup@example.com');
    expect(body.plan).toBe('yearly');
    expect(body.status).toBe('active');
  });

  it('accepts ?token= query param as auth fallback', async () => {
    insertLicense({ key: 'ADIA-LKUP-QPTN-AAAA', email: 'qtoken@example.com', plan: 'lifetime', expiresAt: null });
    const { GET } = await import('@/app/api/admin/lookup/route');
    const req = new NextRequest(
      'http://localhost/api/admin/lookup?key=ADIA-LKUP-QPTN-AAAA&token=test-admin-token',
      { method: 'GET' },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
  });
});

// ─── /api/admin/licenses-by-email ────────────────────────────────────────────

describe('GET /api/admin/licenses-by-email', () => {
  it('returns 401 with no token', async () => {
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=x@x.com',
      { method: 'GET' },
    );
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callLicensesByEmail('x@x.com', 'bad-token');
    expect(res.status).toBe(401);
  });

  it('returns 400 when email param is missing', async () => {
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest('http://localhost/api/admin/licenses-by-email', {
      method: 'GET',
      headers: authHeader(),
    });
    const res = await GET(req);
    expect(res.status).toBe(400);
  });

  it('returns empty list for unknown email', async () => {
    const res = await callLicensesByEmail('nobody@example.com');
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(0);
    expect(body.licenses).toEqual([]);
  });

  it('returns all licenses for a given email ordered newest-first', async () => {
    insertLicense({ key: 'ADIA-BYEM-FRST-AAAA', email: 'multi@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-BYEM-SCND-BBBB', email: 'multi@example.com', plan: 'yearly', expiresAt: null });
    const res = await callLicensesByEmail('multi@example.com');
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(2);
    expect(body.licenses).toHaveLength(2);
    const keys = body.licenses.map((l: any) => l.key);
    expect(keys).toContain('ADIA-BYEM-FRST-AAAA');
    expect(keys).toContain('ADIA-BYEM-SCND-BBBB');
  });

  it('normalizes email to lowercase in response', async () => {
    insertLicense({ key: 'ADIA-BYEM-CASE-AAAA', email: 'cased@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callLicensesByEmail('CASED@EXAMPLE.COM');
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.email).toBe('cased@example.com');
    expect(body.count).toBe(1);
  });

  it('does not cross-contaminate licenses across emails', async () => {
    insertLicense({ key: 'ADIA-BYEM-USER-AAAA', email: 'user1@example.com', plan: 'lifetime', expiresAt: null });
    insertLicense({ key: 'ADIA-BYEM-OTHR-BBBB', email: 'user2@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callLicensesByEmail('user1@example.com');
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.licenses[0].key).toBe('ADIA-BYEM-USER-AAAA');
  });
});

// ─── POST /api/admin/resend-payment-failed ─────────────────────────────────

async function callResendPaymentFailed(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/resend-payment-failed/route');
  const req = new NextRequest('http://localhost/api/admin/resend-payment-failed', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
  });
  return POST(req);
}

describe('POST /api/admin/resend-payment-failed', () => {
  it('returns 401 without a token', async () => {
    const { POST } = await import('@/app/api/admin/resend-payment-failed/route');
    const req = new NextRequest('http://localhost/api/admin/resend-payment-failed', {
      method: 'POST',
      body: JSON.stringify({ key: 'ADIA-RFPF-NOAU-AAAA' }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callResendPaymentFailed({ key: 'ADIA-RFPF-WRNG-AAAA' }, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('returns 400 when key is missing from body', async () => {
    const res = await callResendPaymentFailed({});
    expect(res.status).toBe(400);
  });

  it('returns 404 for unknown key', async () => {
    const res = await callResendPaymentFailed({ key: 'ADIA-RFPF-UNKN-ZZZZ' });
    expect(res.status).toBe(404);
  });

  it('returns 422 when license is not past_due', async () => {
    insertLicense({ key: 'ADIA-RFPF-ACTV-AAAA', email: 'active@example.com', plan: 'monthly', expiresAt: null });
    const res = await callResendPaymentFailed({ key: 'ADIA-RFPF-ACTV-AAAA' });
    expect(res.status).toBe(422);
    const body = await res.json();
    expect(body.status).toBe('active');
    expect(mockSendPaymentFailedEmail).not.toHaveBeenCalled();
  });

  it('sends email and returns 200 for a past_due license', async () => {
    insertLicense({ key: 'ADIA-RFPF-PDUS-AAAA', email: 'pastdue@example.com', plan: 'yearly', expiresAt: null });
    // Manually set status to past_due via the DB helper
    const { setStatus } = await import('@/lib/db');
    setStatus('ADIA-RFPF-PDUS-AAAA', 'past_due');

    const res = await callResendPaymentFailed({ key: 'ADIA-RFPF-PDUS-AAAA' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.to).toBe('pastdue@example.com');
    expect(body.key).toBe('ADIA-RFPF-PDUS-AAAA');
    expect(body.plan).toBe('yearly');
    expect(mockSendPaymentFailedEmail).toHaveBeenCalledOnce();
    expect(mockSendPaymentFailedEmail).toHaveBeenCalledWith(
      'pastdue@example.com',
      'ADIA-RFPF-PDUS-AAAA',
      'yearly',
    );
  });

  it('sends email with force:true even when license is active', async () => {
    insertLicense({ key: 'ADIA-RFPF-FORC-AAAA', email: 'force@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callResendPaymentFailed({ key: 'ADIA-RFPF-FORC-AAAA', force: true });
    expect(res.status).toBe(200);
    expect(mockSendPaymentFailedEmail).toHaveBeenCalledWith(
      'force@example.com',
      'ADIA-RFPF-FORC-AAAA',
      'lifetime',
    );
  });

  it('normalizes key to uppercase', async () => {
    insertLicense({ key: 'ADIA-RFPF-CASE-AAAA', email: 'casekey@example.com', plan: 'monthly', expiresAt: null });
    const { setStatus } = await import('@/lib/db');
    setStatus('ADIA-RFPF-CASE-AAAA', 'past_due');
    const res = await callResendPaymentFailed({ key: 'adia-rfpf-case-aaaa' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.key).toBe('ADIA-RFPF-CASE-AAAA');
  });

  it('accepts ?token= query param auth', async () => {
    insertLicense({ key: 'ADIA-RFPF-TOKN-AAAA', email: 'qpauth@example.com', plan: 'monthly', expiresAt: null });
    const { setStatus } = await import('@/lib/db');
    setStatus('ADIA-RFPF-TOKN-AAAA', 'past_due');
    const { POST } = await import('@/app/api/admin/resend-payment-failed/route');
    const req = new NextRequest(
      'http://localhost/api/admin/resend-payment-failed?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ key: 'ADIA-RFPF-TOKN-AAAA' }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
    expect(mockSendPaymentFailedEmail).toHaveBeenCalledOnce();
  });
});

// ─── POST /api/admin/resend-license ───────────────────────────────────────────

async function callResendLicense(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/resend-license/route');
  const req = new NextRequest('http://localhost/api/admin/resend-license', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
  });
  return POST(req);
}

describe('POST /api/admin/resend-license', () => {
  it('returns 401 without a token', async () => {
    const { POST } = await import('@/app/api/admin/resend-license/route');
    const req = new NextRequest('http://localhost/api/admin/resend-license', {
      method: 'POST',
      body: JSON.stringify({ key: 'ADIA-RLSE-NOAU-AAAA' }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callResendLicense({ key: 'ADIA-RLSE-WRNG-AAAA' }, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('returns 400 when neither key nor email is in the body', async () => {
    const res = await callResendLicense({});
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing/i);
  });

  it('returns 404 for unknown key', async () => {
    const res = await callResendLicense({ key: 'ADIA-RLSE-UNKN-ZZZZ' });
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body.error).toMatch(/unknown license key/i);
  });

  it('returns 404 when no licenses exist for the email', async () => {
    const res = await callResendLicense({ email: 'ghost@example.com' });
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body.error).toMatch(/no licenses found/i);
  });

  it('sends welcome email by key and returns 200', async () => {
    insertLicense({ key: 'ADIA-RLSE-BYKY-AAAA', email: 'bykey@example.com', plan: 'yearly', expiresAt: null });

    const res = await callResendLicense({ key: 'ADIA-RLSE-BYKY-AAAA' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.to).toBe('bykey@example.com');
    expect(body.key).toBe('ADIA-RLSE-BYKY-AAAA');
    expect(body.plan).toBe('yearly');

    expect(mockSendLicenseEmail).toHaveBeenCalledOnce();
    expect(mockSendLicenseEmail).toHaveBeenCalledWith('bykey@example.com', 'ADIA-RLSE-BYKY-AAAA', 'yearly');
  });

  it('sends welcome email by email address and returns 200', async () => {
    insertLicense({ key: 'ADIA-RLSE-BYEM-AAAA', email: 'byemail@example.com', plan: 'lifetime', expiresAt: null });

    const res = await callResendLicense({ email: 'byemail@example.com' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.to).toBe('byemail@example.com');
    expect(body.key).toBe('ADIA-RLSE-BYEM-AAAA');

    expect(mockSendLicenseEmail).toHaveBeenCalledOnce();
  });

  it('prefers key over email when both are supplied', async () => {
    insertLicense({ key: 'ADIA-RLSE-KOV1-AAAA', email: 'primary@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-RLSE-KOV2-BBBB', email: 'secondary@example.com', plan: 'lifetime', expiresAt: null });

    const res = await callResendLicense({ key: 'ADIA-RLSE-KOV1-AAAA', email: 'secondary@example.com' });
    expect(res.status).toBe(200);
    const body = await res.json();
    // key took precedence — primary@example.com, not secondary
    expect(body.key).toBe('ADIA-RLSE-KOV1-AAAA');
    expect(body.to).toBe('primary@example.com');
  });

  it('picks the most recent active license when email has multiple', async () => {
    // Insert older license first (issuedAt ordering)
    insertLicense({ key: 'ADIA-RLSE-MUL1-AAAA', email: 'multi@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-RLSE-MUL2-BBBB', email: 'multi@example.com', plan: 'yearly', expiresAt: null });

    const res = await callResendLicense({ email: 'multi@example.com' });
    expect(res.status).toBe(200);
    const body = await res.json();
    // Second (newer) license should be picked
    expect(body.key).toBe('ADIA-RLSE-MUL2-BBBB');
    expect(body.plan).toBe('yearly');
  });

  it('normalizes key to uppercase', async () => {
    insertLicense({ key: 'ADIA-RLSE-CASE-AAAA', email: 'casekey2@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callResendLicense({ key: 'adia-rlse-case-aaaa' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.key).toBe('ADIA-RLSE-CASE-AAAA');
  });

  it('accepts ?token= query param auth', async () => {
    insertLicense({ key: 'ADIA-RLSE-TOKN-AAAA', email: 'qpauth2@example.com', plan: 'lifetime', expiresAt: null });
    const { POST } = await import('@/app/api/admin/resend-license/route');
    const req = new NextRequest(
      'http://localhost/api/admin/resend-license?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ key: 'ADIA-RLSE-TOKN-AAAA' }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
    expect(mockSendLicenseEmail).toHaveBeenCalledOnce();
  });

  it('sends email regardless of license status', async () => {
    insertLicense({ key: 'ADIA-RLSE-CNCL-AAAA', email: 'canceled@example.com', plan: 'monthly', expiresAt: null });
    const { setStatus } = await import('@/lib/db');
    setStatus('ADIA-RLSE-CNCL-AAAA', 'canceled');

    // Even a canceled license gets the email (admin knows what they're doing).
    const res = await callResendLicense({ key: 'ADIA-RLSE-CNCL-AAAA' });
    expect(res.status).toBe(200);
    expect(mockSendLicenseEmail).toHaveBeenCalledOnce();
  });
});
