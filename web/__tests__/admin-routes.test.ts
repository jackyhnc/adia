// Tests for admin routes:
//   GET/DELETE /api/admin/activations
//   POST       /api/admin/revoke
//   GET        /api/admin/lookup
//   GET        /api/admin/licenses-by-email
//   POST       /api/admin/resend-payment-failed
//   POST       /api/admin/resend-license
//   POST       /api/admin/change-email
//
// All routes require ADMIN_TOKEN; SQLite DB is reset per test.

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, recordActivation, findLicense, insertAuditLog, setIssuedAt, setStatus } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

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
  resetRateLimit();
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

async function callLicensesByEmailCsv(email: string, token = 'test-admin-token') {
  const { GET } = await import('@/app/api/admin/licenses-by-email/route');
  const req = new NextRequest(
    `http://localhost/api/admin/licenses-by-email?email=${encodeURIComponent(email)}&format=csv`,
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
    // Response is now { license, recentAudit } — check top-level shape
    expect(body.license).toBeDefined();
    expect(body.recentAudit).toBeInstanceOf(Array);
    expect(body.license.key).toBe('ADIA-LKUP-HPPY-AAAA');
    expect(body.license.email).toBe('lookup@example.com');
    expect(body.license.plan).toBe('yearly');
    expect(body.license.status).toBe('active');
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
    // BBBB was inserted second (higher rowid) so it should appear first
    expect(body.licenses[0].key).toBe('ADIA-BYEM-SCND-BBBB');
    expect(body.licenses[1].key).toBe('ADIA-BYEM-FRST-AAAA');
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

  it('machineCount is 0 when no activations', async () => {
    insertLicense({ key: 'ADIA-BYEM-MC0-AAAA', email: 'mc0@example.com', plan: 'monthly', expiresAt: null });
    const res = await callLicensesByEmail('mc0@example.com');
    const body = await res.json();
    expect(body.licenses[0].machineCount).toBe(0);
  });

  it('machineCount equals number of distinct activated machines', async () => {
    insertLicense({ key: 'ADIA-BYEM-MC2-AAAA', email: 'mc2@example.com', plan: 'monthly', expiresAt: null });
    recordActivation('ADIA-BYEM-MC2-AAAA', 'hash-m1');
    recordActivation('ADIA-BYEM-MC2-AAAA', 'hash-m2');
    const res = await callLicensesByEmail('mc2@example.com');
    const body = await res.json();
    expect(body.licenses[0].machineCount).toBe(2);
  });

  it('machineCount does not bleed across licenses for same email', async () => {
    insertLicense({ key: 'ADIA-BYEM-BLA-AAAA', email: 'bleed@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-BYEM-BLB-BBBB', email: 'bleed@example.com', plan: 'yearly', expiresAt: null });
    recordActivation('ADIA-BYEM-BLA-AAAA', 'hash-bleed-1');
    recordActivation('ADIA-BYEM-BLA-AAAA', 'hash-bleed-2');
    recordActivation('ADIA-BYEM-BLA-AAAA', 'hash-bleed-3');
    const res = await callLicensesByEmail('bleed@example.com');
    const body = await res.json();
    const a = body.licenses.find((l: any) => l.key === 'ADIA-BYEM-BLA-AAAA');
    const b = body.licenses.find((l: any) => l.key === 'ADIA-BYEM-BLB-BBBB');
    expect(a.machineCount).toBe(3);
    expect(b.machineCount).toBe(0);
  });

  it('returns lastAction null when no audit entries exist', async () => {
    insertLicense({ key: 'ADIA-BYEM-LAX-AAAA', email: 'lax@auditless.dev', plan: 'monthly', expiresAt: null });
    const res = await callLicensesByEmail('lax@auditless.dev');
    const body = await res.json();
    expect(body.licenses[0].lastAction).toBeNull();
    expect(body.licenses[0].lastActionAt).toBeNull();
  });

  it('returns lastAction with the most recent audit action', async () => {
    insertLicense({ key: 'ADIA-BYEM-LAY-AAAA', email: 'lay@audited.dev', plan: 'yearly', expiresAt: null });
    insertAuditLog({ licenseKey: 'ADIA-BYEM-LAY-AAAA', action: 'activate' });
    insertAuditLog({ licenseKey: 'ADIA-BYEM-LAY-AAAA', action: 'validate' });
    const res = await callLicensesByEmail('lay@audited.dev');
    const body = await res.json();
    expect(body.licenses[0].lastAction).toBe('validate');
    expect(body.licenses[0].lastActionAt).toBeTruthy();
  });

  it('lastAction does not bleed across licenses for the same email', async () => {
    insertLicense({ key: 'ADIA-BYEM-LBA-AAAA', email: 'lbleed@test.dev', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-BYEM-LBB-BBBB', email: 'lbleed@test.dev', plan: 'yearly', expiresAt: null });
    insertAuditLog({ licenseKey: 'ADIA-BYEM-LBA-AAAA', action: 'revoke' });
    const res = await callLicensesByEmail('lbleed@test.dev');
    const body = await res.json();
    const a = body.licenses.find((l: any) => l.key === 'ADIA-BYEM-LBA-AAAA');
    const b = body.licenses.find((l: any) => l.key === 'ADIA-BYEM-LBB-BBBB');
    expect(a.lastAction).toBe('revoke');
    expect(b.lastAction).toBeNull();
  });

  // ── CSV export ────────────────────────────────────────────────────────────

  it('format=csv returns 401 without a token', async () => {
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=x@x.com&format=csv',
      { method: 'GET' },
    );
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('format=csv returns 400 when email param is missing', async () => {
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?format=csv',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    expect(res.status).toBe(400);
  });

  it('format=csv responds with text/csv content-type', async () => {
    insertLicense({ key: 'ADIA-CSV-CT1-AAAA', email: 'csvct@example.com', plan: 'monthly', expiresAt: null });
    const res = await callLicensesByEmailCsv('csvct@example.com');
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toContain('text/csv');
  });

  it('format=csv includes a Content-Disposition attachment header', async () => {
    insertLicense({ key: 'ADIA-CSV-CD1-AAAA', email: 'csvcd@example.com', plan: 'monthly', expiresAt: null });
    const res = await callLicensesByEmailCsv('csvcd@example.com');
    const cd = res.headers.get('content-disposition') ?? '';
    expect(cd).toContain('attachment');
    expect(cd).toContain('csvcd@example.com');
    expect(cd).toContain('.csv');
  });

  it('format=csv body starts with the expected header row', async () => {
    insertLicense({ key: 'ADIA-CSV-HD1-AAAA', email: 'csvhd@example.com', plan: 'yearly', expiresAt: null });
    const res = await callLicensesByEmailCsv('csvhd@example.com');
    const text = await res.text();
    const firstLine = text.split('\r\n')[0];
    expect(firstLine).toBe('key,plan,status,machineCount,issuedAt,expiresAt,note,lastAction,lastActionAt');
  });

  it('format=csv includes one data row per license', async () => {
    insertLicense({ key: 'ADIA-CSV-R1A-AAAA', email: 'csvrows@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-CSV-R1B-BBBB', email: 'csvrows@example.com', plan: 'yearly', expiresAt: null });
    const res = await callLicensesByEmailCsv('csvrows@example.com');
    const text = await res.text();
    const lines = text.split('\r\n').filter(Boolean);
    expect(lines).toHaveLength(3);
    expect(lines.some(l => l.includes('ADIA-CSV-R1A-AAAA'))).toBe(true);
    expect(lines.some(l => l.includes('ADIA-CSV-R1B-BBBB'))).toBe(true);
  });

  it('format=csv data row contains correct key, plan, and status fields', async () => {
    insertLicense({ key: 'ADIA-CSV-F1A-AAAA', email: 'csvfields@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callLicensesByEmailCsv('csvfields@example.com');
    const text = await res.text();
    const dataRow = text.split('\r\n')[1];
    expect(dataRow).toContain('ADIA-CSV-F1A-AAAA');
    expect(dataRow).toContain('lifetime');
    expect(dataRow).toContain('active');
  });

  it('format=csv returns header-only body for unknown email', async () => {
    const res = await callLicensesByEmailCsv('nobody-csv@example.com');
    expect(res.status).toBe(200);
    const text = await res.text();
    const lines = text.split('\r\n').filter(Boolean);
    expect(lines).toHaveLength(1);
    expect(lines[0]).toBe('key,plan,status,machineCount,issuedAt,expiresAt,note,lastAction,lastActionAt');
  });

  it('format=csv cells with commas are quoted per RFC 4180', async () => {
    insertLicense({ key: 'ADIA-CSV-QU1-AAAA', email: 'csvquote@example.com', plan: 'monthly', expiresAt: null });
    const { setNote } = await import('@/lib/db');
    setNote('ADIA-CSV-QU1-AAAA', 'a note, with comma');
    const res = await callLicensesByEmailCsv('csvquote@example.com');
    const text = await res.text();
    expect(text).toContain('"a note, with comma"');
  });

  it('format=csv ?token= query-param auth works', async () => {
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    insertLicense({ key: 'ADIA-CSV-TK1-AAAA', email: 'csvtk@example.com', plan: 'monthly', expiresAt: null });
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=csvtk%40example.com&format=csv&token=test-admin-token',
      { method: 'GET' },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toContain('text/csv');
  });

  // ── Pagination ───────────────────────────────────────────────────────────

  it('returns hasMore=false and offset=0 when all results fit on one page', async () => {
    insertLicense({ key: 'ADIA-PG1-ONE-AAAA', email: 'pg1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-PG1-TWO-BBBB', email: 'pg1@example.com', plan: 'yearly', expiresAt: null });
    const res = await callLicensesByEmail('pg1@example.com');
    const body = await res.json();
    expect(body.hasMore).toBe(false);
    expect(body.offset).toBe(0);
    expect(body.licenses).toHaveLength(2);
  });

  it('count reflects total records even when limit caps the page', async () => {
    for (let i = 0; i < 5; i++) {
      insertLicense({ key: `ADIA-PG2-K${i}${i}${i}-AAAA`, email: 'pg2@example.com', plan: 'monthly', expiresAt: null });
    }
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=pg2%40example.com&limit=2&offset=0',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    const body = await res.json();
    expect(body.count).toBe(5);
    expect(body.licenses).toHaveLength(2);
    expect(body.hasMore).toBe(true);
    expect(body.offset).toBe(0);
  });

  it('limit=2 returns the first two records ordered newest-first', async () => {
    for (let i = 0; i < 4; i++) {
      insertLicense({ key: `ADIA-PG3-K${i}${i}${i}-AAAA`, email: 'pg3@example.com', plan: 'monthly', expiresAt: null });
    }
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=pg3%40example.com&limit=2&offset=0',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    const body = await res.json();
    // Newest-first: rowid 3, then 2 (0-indexed inserts)
    expect(body.licenses[0].key).toBe('ADIA-PG3-K333-AAAA');
    expect(body.licenses[1].key).toBe('ADIA-PG3-K222-AAAA');
  });

  it('offset skips earlier records and returns the next page', async () => {
    for (let i = 0; i < 4; i++) {
      insertLicense({ key: `ADIA-PG4-K${i}${i}${i}-AAAA`, email: 'pg4@example.com', plan: 'monthly', expiresAt: null });
    }
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=pg4%40example.com&limit=2&offset=2',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    const body = await res.json();
    expect(body.count).toBe(4);
    expect(body.licenses).toHaveLength(2);
    expect(body.hasMore).toBe(false);
    expect(body.licenses[0].key).toBe('ADIA-PG4-K111-AAAA');
    expect(body.licenses[1].key).toBe('ADIA-PG4-K000-AAAA');
  });

  it('hasMore is true when there are more records beyond the current page', async () => {
    for (let i = 0; i < 3; i++) {
      insertLicense({ key: `ADIA-PG5-K${i}${i}${i}-AAAA`, email: 'pg5@example.com', plan: 'monthly', expiresAt: null });
    }
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=pg5%40example.com&limit=2&offset=0',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    const body = await res.json();
    expect(body.hasMore).toBe(true);
    expect(body.licenses).toHaveLength(2);
  });

  it('limit exceeding MAX_LIMIT (100) is capped to 100', async () => {
    insertLicense({ key: 'ADIA-PG6-CAP-AAAA', email: 'pg6@example.com', plan: 'monthly', expiresAt: null });
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=pg6%40example.com&limit=999',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
    const body = await res.json();
    // Only 1 record — important check is the server didn't crash with limit=999
    expect(body.licenses).toHaveLength(1);
    expect(body.hasMore).toBe(false);
  });

  it('invalid limit falls back to default (20) and returns successfully', async () => {
    insertLicense({ key: 'ADIA-PG7-INV-AAAA', email: 'pg7@example.com', plan: 'monthly', expiresAt: null });
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=pg7%40example.com&limit=abc',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.licenses).toHaveLength(1);
  });

  // ── ?since= filter ────────────────────────────────────────────────────────

  it('returns 400 for invalid ?since= format', async () => {
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=x%40x.com&since=not-a-date',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/since/i);
  });

  it('since=far-past returns all licenses', async () => {
    insertLicense({ key: 'ADIA-SNC-OLD-AAAA', email: 'snc@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-SNC-NEW-BBBB', email: 'snc@example.com', plan: 'yearly', expiresAt: null });
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=snc%40example.com&since=2000-01-01',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(2);
    expect(body.since).toBe('2000-01-01');
  });

  it('since=far-future returns zero licenses', async () => {
    insertLicense({ key: 'ADIA-SNC-ZRO-AAAA', email: 'snczero@example.com', plan: 'monthly', expiresAt: null });
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=snczero%40example.com&since=2099-01-01',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(0);
    expect(body.licenses).toHaveLength(0);
  });

  it('since filter excludes licenses issued before the cutoff date', async () => {
    insertLicense({ key: 'ADIA-SNC-PRE-AAAA', email: 'snccut@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-SNC-PST-BBBB', email: 'snccut@example.com', plan: 'yearly', expiresAt: null });
    setIssuedAt('ADIA-SNC-PRE-AAAA', '2022-06-01T00:00:00.000Z');
    setIssuedAt('ADIA-SNC-PST-BBBB', '2024-01-15T00:00:00.000Z');
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=snccut%40example.com&since=2023-01-01',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.licenses[0].key).toBe('ADIA-SNC-PST-BBBB');
  });

  // ── ?status= filter ───────────────────────────────────────────────────────

  it('returns 400 for unknown ?status= value', async () => {
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=x%40x.com&status=bogus',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/status/i);
  });

  it('status=active returns only active licenses', async () => {
    insertLicense({ key: 'ADIA-STS-ACT-AAAA', email: 'sts@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-STS-CAN-BBBB', email: 'sts@example.com', plan: 'yearly', expiresAt: null });
    setStatus('ADIA-STS-CAN-BBBB', 'canceled');
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=sts%40example.com&status=active',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.licenses[0].key).toBe('ADIA-STS-ACT-AAAA');
    expect(body.status).toBe('active');
  });

  it('status=canceled returns only canceled licenses', async () => {
    insertLicense({ key: 'ADIA-STS-CA2-AAAA', email: 'stsc@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-STS-CA3-BBBB', email: 'stsc@example.com', plan: 'yearly', expiresAt: null });
    setStatus('ADIA-STS-CA2-AAAA', 'canceled');
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=stsc%40example.com&status=canceled',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.licenses[0].key).toBe('ADIA-STS-CA2-AAAA');
  });

  it('status filter returns empty list when no licenses match', async () => {
    insertLicense({ key: 'ADIA-STS-EMP-AAAA', email: 'stse@example.com', plan: 'monthly', expiresAt: null });
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=stse%40example.com&status=expired',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(0);
    expect(body.licenses).toHaveLength(0);
  });

  // ── combined since + status ───────────────────────────────────────────────

  it('since and status filters can be combined', async () => {
    insertLicense({ key: 'ADIA-CMB-OLD-AAAA', email: 'cmb@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-CMB-NEW-BBBB', email: 'cmb@example.com', plan: 'yearly', expiresAt: null });
    insertLicense({ key: 'ADIA-CMB-CAN-CCCC', email: 'cmb@example.com', plan: 'lifetime', expiresAt: null });
    setIssuedAt('ADIA-CMB-OLD-AAAA', '2021-01-01T00:00:00.000Z');
    setIssuedAt('ADIA-CMB-NEW-BBBB', '2024-06-01T00:00:00.000Z');
    setIssuedAt('ADIA-CMB-CAN-CCCC', '2024-09-01T00:00:00.000Z');
    setStatus('ADIA-CMB-CAN-CCCC', 'canceled');
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    // since=2023-01-01 + status=active → should match only BBBB (new, active)
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=cmb%40example.com&since=2023-01-01&status=active',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.licenses[0].key).toBe('ADIA-CMB-NEW-BBBB');
  });

  // ── ?plan= filter ─────────────────────────────────────────────────────────

  it('returns 400 for unknown ?plan= value', async () => {
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=x%40x.com&plan=enterprise',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/plan/i);
  });

  it('plan=monthly returns only monthly licenses', async () => {
    insertLicense({ key: 'ADIA-PLN-M-AAAA', email: 'pln@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-PLN-Y-BBBB', email: 'pln@example.com', plan: 'yearly', expiresAt: null });
    insertLicense({ key: 'ADIA-PLN-L-CCCC', email: 'pln@example.com', plan: 'lifetime', expiresAt: null });
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=pln%40example.com&plan=monthly',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.licenses[0].key).toBe('ADIA-PLN-M-AAAA');
    expect(body.plan).toBe('monthly');
  });

  it('plan=yearly returns only yearly licenses', async () => {
    insertLicense({ key: 'ADIA-PLN2-M-AAAA', email: 'pln2@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-PLN2-Y-BBBB', email: 'pln2@example.com', plan: 'yearly', expiresAt: null });
    insertLicense({ key: 'ADIA-PLN2-L-CCCC', email: 'pln2@example.com', plan: 'lifetime', expiresAt: null });
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=pln2%40example.com&plan=yearly',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.licenses[0].key).toBe('ADIA-PLN2-Y-BBBB');
  });

  it('plan filter returns empty list when no licenses match that plan', async () => {
    insertLicense({ key: 'ADIA-PLNE-M-AAAA', email: 'plne@example.com', plan: 'monthly', expiresAt: null });
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=plne%40example.com&plan=lifetime',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(0);
    expect(body.licenses).toHaveLength(0);
  });

  it('plan filter does not bleed across emails', async () => {
    insertLicense({ key: 'ADIA-PLNB-A-1111', email: 'plnbleed-a@example.com', plan: 'lifetime', expiresAt: null });
    insertLicense({ key: 'ADIA-PLNB-B-2222', email: 'plnbleed-b@example.com', plan: 'monthly', expiresAt: null });
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=plnbleed-a%40example.com&plan=lifetime',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.licenses[0].key).toBe('ADIA-PLNB-A-1111');
  });

  it('plan and status filters can be combined', async () => {
    insertLicense({ key: 'ADIA-PSC-MY-AAAA', email: 'psc@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-PSC-YA-BBBB', email: 'psc@example.com', plan: 'yearly', expiresAt: null });
    insertLicense({ key: 'ADIA-PSC-YC-CCCC', email: 'psc@example.com', plan: 'yearly', expiresAt: null });
    setStatus('ADIA-PSC-YC-CCCC', 'canceled');
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    // plan=yearly + status=active → only BBBB
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=psc%40example.com&plan=yearly&status=active',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.licenses[0].key).toBe('ADIA-PSC-YA-BBBB');
  });

  it('CSV export respects combined plan + status filters', async () => {
    insertLicense({ key: 'ADIA-CSVC-MY-AAAA', email: 'csvcomb@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-CSVC-YA-BBBB', email: 'csvcomb@example.com', plan: 'yearly', expiresAt: null });
    insertLicense({ key: 'ADIA-CSVC-YC-CCCC', email: 'csvcomb@example.com', plan: 'yearly', expiresAt: null });
    setStatus('ADIA-CSVC-YC-CCCC', 'canceled');
    const { GET } = await import('@/app/api/admin/licenses-by-email/route');
    // plan=yearly + status=active + format=csv → only BBBB row (not monthly AAAA, not canceled CCCC)
    const req = new NextRequest(
      'http://localhost/api/admin/licenses-by-email?email=csvcomb%40example.com&plan=yearly&status=active&format=csv',
      { method: 'GET', headers: authHeader() },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toMatch(/text\/csv/);
    const text = await res.text();
    const lines = text.trim().split(/\r?\n/);
    // header + exactly one data row
    expect(lines).toHaveLength(2);
    expect(text).toContain('ADIA-CSVC-YA-BBBB');
    expect(text).not.toContain('ADIA-CSVC-MY-AAAA');
    expect(text).not.toContain('ADIA-CSVC-YC-CCCC');
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

  it('returns 429 after exceeding 20 requests per minute from the same IP', async () => {
    insertLicense({ key: 'ADIA-RLSE-RLMT-AAAA', email: 'ratelimit@example.com', plan: 'monthly', expiresAt: null });
    const { POST } = await import('@/app/api/admin/resend-license/route');
    const makeReq = () =>
      new NextRequest('http://localhost/api/admin/resend-license', {
        method: 'POST',
        body: JSON.stringify({ key: 'ADIA-RLSE-RLMT-AAAA' }),
        headers: {
          'Content-Type': 'application/json',
          Authorization: 'Bearer test-admin-token',
          'x-forwarded-for': '10.0.0.1',
        },
      });

    // First 20 requests succeed.
    for (let i = 0; i < 20; i++) {
      const res = await POST(makeReq());
      expect(res.status).toBe(200);
    }

    // 21st request is rejected.
    const res = await POST(makeReq());
    expect(res.status).toBe(429);
    const body = await res.json();
    expect(body.error).toMatch(/too many requests/i);
    expect(res.headers.get('Retry-After')).toBeTruthy();
  });

  it('rate limit is per IP — a different IP is not affected', async () => {
    insertLicense({ key: 'ADIA-RLSE-RLIP-AAAA', email: 'rlip@example.com', plan: 'lifetime', expiresAt: null });
    const { POST } = await import('@/app/api/admin/resend-license/route');

    const makeReq = (ip: string) =>
      new NextRequest('http://localhost/api/admin/resend-license', {
        method: 'POST',
        body: JSON.stringify({ key: 'ADIA-RLSE-RLIP-AAAA' }),
        headers: {
          'Content-Type': 'application/json',
          Authorization: 'Bearer test-admin-token',
          'x-forwarded-for': ip,
        },
      });

    // Exhaust the bucket for 10.0.0.2.
    for (let i = 0; i < 20; i++) {
      await POST(makeReq('10.0.0.2'));
    }
    const blocked = await POST(makeReq('10.0.0.2'));
    expect(blocked.status).toBe(429);

    // A different IP (10.0.0.3) still gets through.
    const allowed = await POST(makeReq('10.0.0.3'));
    expect(allowed.status).toBe(200);
  });
});

// ─── POST /api/admin/change-email ─────────────────────────────────────────────

async function callChangeEmail(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/change-email/route');
  const req = new NextRequest('http://localhost/api/admin/change-email', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
  });
  return POST(req);
}

describe('POST /api/admin/change-email', () => {
  it('returns 401 without a token', async () => {
    const { POST } = await import('@/app/api/admin/change-email/route');
    const req = new NextRequest('http://localhost/api/admin/change-email', {
      method: 'POST',
      body: JSON.stringify({ key: 'ADIA-CHGE-NOAU-AAAA', newEmail: 'new@example.com' }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callChangeEmail(
      { key: 'ADIA-CHGE-WRNG-AAAA', newEmail: 'new@example.com' },
      'wrong-token',
    );
    expect(res.status).toBe(401);
  });

  it('returns 400 when key is missing', async () => {
    const res = await callChangeEmail({ newEmail: 'new@example.com' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing key/i);
  });

  it('returns 400 when newEmail is missing', async () => {
    const res = await callChangeEmail({ key: 'ADIA-CHGE-NOME-AAAA' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing newEmail/i);
  });

  it('returns 400 when newEmail is not a valid email', async () => {
    const res = await callChangeEmail({ key: 'ADIA-CHGE-BDEM-AAAA', newEmail: 'notanemail' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/not a valid email/i);
  });

  it('returns 404 for unknown license key', async () => {
    const res = await callChangeEmail({ key: 'ADIA-CHGE-UNKN-ZZZZ', newEmail: 'new@example.com' });
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body.error).toMatch(/unknown license key/i);
  });

  it('returns 422 when newEmail is the same as the current email', async () => {
    insertLicense({ key: 'ADIA-CHGE-SAME-AAAA', email: 'same@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callChangeEmail({ key: 'ADIA-CHGE-SAME-AAAA', newEmail: 'same@example.com' });
    expect(res.status).toBe(422);
    const body = await res.json();
    expect(body.error).toMatch(/same as the current email/i);
  });

  it('changes email and returns ok with old and new email', async () => {
    insertLicense({ key: 'ADIA-CHGE-GOOD-AAAA', email: 'old@example.com', plan: 'yearly', expiresAt: null });

    const res = await callChangeEmail({ key: 'ADIA-CHGE-GOOD-AAAA', newEmail: 'new@example.com' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.key).toBe('ADIA-CHGE-GOOD-AAAA');
    expect(body.oldEmail).toBe('old@example.com');
    expect(body.newEmail).toBe('new@example.com');
    expect(body.plan).toBe('yearly');
  });

  it('persists the new email in the database', async () => {
    insertLicense({ key: 'ADIA-CHGE-PRST-AAAA', email: 'before@example.com', plan: 'monthly', expiresAt: null });

    await callChangeEmail({ key: 'ADIA-CHGE-PRST-AAAA', newEmail: 'after@example.com' });

    const { findLicense: findLicenseDb } = await import('@/lib/db');
    const lic = findLicenseDb('ADIA-CHGE-PRST-AAAA');
    expect(lic?.email).toBe('after@example.com');
  });

  it('normalizes key to uppercase before lookup', async () => {
    insertLicense({ key: 'ADIA-CHGE-CASE-AAAA', email: 'caseold@example.com', plan: 'lifetime', expiresAt: null });

    const res = await callChangeEmail({ key: 'adia-chge-case-aaaa', newEmail: 'casenew@example.com' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.key).toBe('ADIA-CHGE-CASE-AAAA');
  });

  it('normalizes newEmail to lowercase', async () => {
    insertLicense({ key: 'ADIA-CHGE-LCAS-AAAA', email: 'lcold@example.com', plan: 'lifetime', expiresAt: null });

    const res = await callChangeEmail({ key: 'ADIA-CHGE-LCAS-AAAA', newEmail: 'LCNEW@EXAMPLE.COM' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.newEmail).toBe('lcnew@example.com');

    const { findLicense: findLicenseDb } = await import('@/lib/db');
    const lic = findLicenseDb('ADIA-CHGE-LCAS-AAAA');
    expect(lic?.email).toBe('lcnew@example.com');
  });

  it('accepts ?token= query param auth', async () => {
    insertLicense({ key: 'ADIA-CHGE-TOKN-AAAA', email: 'tokold@example.com', plan: 'lifetime', expiresAt: null });
    const { POST } = await import('@/app/api/admin/change-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/change-email?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ key: 'ADIA-CHGE-TOKN-AAAA', newEmail: 'toknew@example.com' }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
  });

  it('works for a canceled license — admin can update email regardless of status', async () => {
    insertLicense({ key: 'ADIA-CHGE-CNCL-AAAA', email: 'cncold@example.com', plan: 'monthly', expiresAt: null });
    const { setStatus } = await import('@/lib/db');
    setStatus('ADIA-CHGE-CNCL-AAAA', 'canceled');

    const res = await callChangeEmail({ key: 'ADIA-CHGE-CNCL-AAAA', newEmail: 'cncnew@example.com' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.newEmail).toBe('cncnew@example.com');
  });
});

// ─── POST /api/admin/reactivate ───────────────────────────────────────────────

async function callReactivate(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/reactivate/route');
  const req = new NextRequest('http://localhost/api/admin/reactivate', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', ...authHeader(token) },
  });
  return POST(req);
}

describe('POST /api/admin/reactivate', () => {
  it('returns 401 without a token', async () => {
    const { POST } = await import('@/app/api/admin/reactivate/route');
    const req = new NextRequest('http://localhost/api/admin/reactivate', {
      method: 'POST',
      body: JSON.stringify({ key: 'ADIA-XXXX-XXXX-XXXX' }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callReactivate({ key: 'ADIA-XXXX-XXXX-XXXX' }, 'bad-token');
    expect(res.status).toBe(401);
  });

  it('returns 400 when key is missing from body', async () => {
    const res = await callReactivate({});
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing key/i);
  });

  it('returns 404 for unknown key', async () => {
    const res = await callReactivate({ key: 'ADIA-UNKN-UNKN-UNKN' });
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body.error).toMatch(/unknown key/i);
  });

  it('returns 422 when license is already active', async () => {
    insertLicense({ key: 'ADIA-REAC-ALRD-AAAA', email: 'alreadyactive@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callReactivate({ key: 'ADIA-REAC-ALRD-AAAA' });
    expect(res.status).toBe(422);
    const body = await res.json();
    expect(body.error).toMatch(/already active/i);
  });

  it('reactivates a canceled license and returns previousStatus', async () => {
    insertLicense({ key: 'ADIA-REAC-CNCL-AAAA', email: 'canceled@example.com', plan: 'monthly', expiresAt: null });
    const { setStatus } = await import('@/lib/db');
    setStatus('ADIA-REAC-CNCL-AAAA', 'canceled');

    const res = await callReactivate({ key: 'ADIA-REAC-CNCL-AAAA' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.key).toBe('ADIA-REAC-CNCL-AAAA');
    expect(body.previousStatus).toBe('canceled');
    expect(body.newStatus).toBe('active');
  });

  it('reactivates a past_due license', async () => {
    insertLicense({ key: 'ADIA-REAC-PDUE-AAAA', email: 'pastdue@example.com', plan: 'yearly', expiresAt: null });
    const { setStatus } = await import('@/lib/db');
    setStatus('ADIA-REAC-PDUE-AAAA', 'past_due');

    const res = await callReactivate({ key: 'ADIA-REAC-PDUE-AAAA' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.previousStatus).toBe('past_due');
    expect(body.newStatus).toBe('active');
  });

  it('reactivates an expired license', async () => {
    insertLicense({ key: 'ADIA-REAC-XPRD-AAAA', email: 'expired@example.com', plan: 'monthly', expiresAt: '2024-01-01T00:00:00.000Z' });
    const { setStatus } = await import('@/lib/db');
    setStatus('ADIA-REAC-XPRD-AAAA', 'expired');

    const res = await callReactivate({ key: 'ADIA-REAC-XPRD-AAAA' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.previousStatus).toBe('expired');
    expect(body.newStatus).toBe('active');
  });

  it('persists the active status to the database', async () => {
    insertLicense({ key: 'ADIA-REAC-PERS-AAAA', email: 'persist@example.com', plan: 'lifetime', expiresAt: null });
    const { setStatus } = await import('@/lib/db');
    setStatus('ADIA-REAC-PERS-AAAA', 'canceled');

    await callReactivate({ key: 'ADIA-REAC-PERS-AAAA' });
    const updated = findLicense('ADIA-REAC-PERS-AAAA');
    expect(updated?.status).toBe('active');
  });

  it('normalizes key to uppercase before lookup', async () => {
    insertLicense({ key: 'ADIA-REAC-NORM-AAAA', email: 'norm@example.com', plan: 'lifetime', expiresAt: null });
    const { setStatus } = await import('@/lib/db');
    setStatus('ADIA-REAC-NORM-AAAA', 'canceled');

    const res = await callReactivate({ key: 'adia-reac-norm-aaaa' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.key).toBe('ADIA-REAC-NORM-AAAA');
  });

  it('accepts ?token= query param auth', async () => {
    insertLicense({ key: 'ADIA-REAC-TOKN-AAAA', email: 'tokn@example.com', plan: 'lifetime', expiresAt: null });
    const { setStatus } = await import('@/lib/db');
    setStatus('ADIA-REAC-TOKN-AAAA', 'canceled');

    const { POST } = await import('@/app/api/admin/reactivate/route');
    const req = new NextRequest(
      'http://localhost/api/admin/reactivate?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ key: 'ADIA-REAC-TOKN-AAAA' }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
  });
});

// ─── POST /api/admin/extend ───────────────────────────────────────────────────

async function callExtend(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/extend/route');
  const req = new NextRequest('http://localhost/api/admin/extend', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', ...authHeader(token) },
  });
  return POST(req);
}

describe('POST /api/admin/extend', () => {
  it('returns 401 without a token', async () => {
    const { POST } = await import('@/app/api/admin/extend/route');
    const req = new NextRequest('http://localhost/api/admin/extend', {
      method: 'POST',
      body: JSON.stringify({ key: 'ADIA-XXXX-XXXX-XXXX', days: 30 }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callExtend({ key: 'ADIA-XXXX-XXXX-XXXX', days: 30 }, 'bad-token');
    expect(res.status).toBe(401);
  });

  it('returns 400 when key is missing', async () => {
    const res = await callExtend({ days: 30 });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing key/i);
  });

  it('returns 400 when days is missing', async () => {
    const res = await callExtend({ key: 'ADIA-EXTN-NODY-AAAA' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing days/i);
  });

  it('returns 400 when days is zero', async () => {
    const res = await callExtend({ key: 'ADIA-EXTN-ZERO-AAAA', days: 0 });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/positive integer/i);
  });

  it('returns 400 when days is negative', async () => {
    const res = await callExtend({ key: 'ADIA-EXTN-NEGV-AAAA', days: -7 });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/positive integer/i);
  });

  it('returns 400 when days is fractional', async () => {
    const res = await callExtend({ key: 'ADIA-EXTN-FRAC-AAAA', days: 1.5 });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/positive integer/i);
  });

  it('returns 400 when days exceeds 3650', async () => {
    const res = await callExtend({ key: 'ADIA-EXTN-MXDY-AAAA', days: 3651 });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/3650/);
  });

  it('returns 404 for unknown key', async () => {
    const res = await callExtend({ key: 'ADIA-EXTN-UNKN-XXXX', days: 30 });
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body.error).toMatch(/unknown key/i);
  });

  it('extends a license with an existing future expiresAt', async () => {
    const futureExpiry = new Date(Date.now() + 30 * 86400 * 1000).toISOString();
    insertLicense({ key: 'ADIA-EXTN-FUTR-AAAA', email: 'future@example.com', plan: 'monthly', expiresAt: futureExpiry });

    const res = await callExtend({ key: 'ADIA-EXTN-FUTR-AAAA', days: 14 });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.key).toBe('ADIA-EXTN-FUTR-AAAA');
    expect(body.previousExpiresAt).toBe(futureExpiry);
    expect(body.days).toBe(14);

    // New expiry is ~44 days from now (30 future + 14 added).
    const newExpiry = new Date(body.newExpiresAt);
    const expected = new Date(futureExpiry);
    expected.setDate(expected.getDate() + 14);
    // Allow 5s clock drift in the test environment.
    expect(Math.abs(newExpiry.getTime() - expected.getTime())).toBeLessThan(5000);
  });

  it('extends a license with a past expiresAt from now (not from the expired date)', async () => {
    const pastExpiry = '2024-01-01T00:00:00.000Z';
    insertLicense({ key: 'ADIA-EXTN-PAST-AAAA', email: 'past@example.com', plan: 'yearly', expiresAt: pastExpiry });

    const before = Date.now();
    const res = await callExtend({ key: 'ADIA-EXTN-PAST-AAAA', days: 30 });
    const after = Date.now();

    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.previousExpiresAt).toBe(pastExpiry);
    // New expiry must be in the future, approximately now + 30 days.
    const newExpiry = new Date(body.newExpiresAt).getTime();
    const expectedMin = before + 30 * 86400 * 1000 - 5000;
    const expectedMax = after + 30 * 86400 * 1000 + 5000;
    expect(newExpiry).toBeGreaterThanOrEqual(expectedMin);
    expect(newExpiry).toBeLessThanOrEqual(expectedMax);
  });

  it('extends a lifetime license (null expiresAt) from now', async () => {
    insertLicense({ key: 'ADIA-EXTN-LIFE-AAAA', email: 'lifetime@example.com', plan: 'lifetime', expiresAt: null });

    const before = Date.now();
    const res = await callExtend({ key: 'ADIA-EXTN-LIFE-AAAA', days: 7 });
    const after = Date.now();

    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.previousExpiresAt).toBeNull();
    const newExpiry = new Date(body.newExpiresAt).getTime();
    const expectedMin = before + 7 * 86400 * 1000 - 5000;
    const expectedMax = after + 7 * 86400 * 1000 + 5000;
    expect(newExpiry).toBeGreaterThanOrEqual(expectedMin);
    expect(newExpiry).toBeLessThanOrEqual(expectedMax);
  });

  it('persists the new expiresAt to the database', async () => {
    const futureExpiry = new Date(Date.now() + 60 * 86400 * 1000).toISOString();
    insertLicense({ key: 'ADIA-EXTN-PERS-AAAA', email: 'persist@example.com', plan: 'monthly', expiresAt: futureExpiry });

    const res = await callExtend({ key: 'ADIA-EXTN-PERS-AAAA', days: 30 });
    expect(res.status).toBe(200);
    const body = await res.json();

    const updated = findLicense('ADIA-EXTN-PERS-AAAA');
    expect(updated?.expiresAt).toBe(body.newExpiresAt);
  });

  it('normalizes key to uppercase before lookup', async () => {
    const futureExpiry = new Date(Date.now() + 30 * 86400 * 1000).toISOString();
    insertLicense({ key: 'ADIA-EXTN-NORM-AAAA', email: 'norm@example.com', plan: 'yearly', expiresAt: futureExpiry });

    const res = await callExtend({ key: 'adia-extn-norm-aaaa', days: 5 });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.key).toBe('ADIA-EXTN-NORM-AAAA');
  });

  it('accepts ?token= query param auth', async () => {
    const futureExpiry = new Date(Date.now() + 30 * 86400 * 1000).toISOString();
    insertLicense({ key: 'ADIA-EXTN-TOKN-AAAA', email: 'tokn@example.com', plan: 'monthly', expiresAt: futureExpiry });

    const { POST } = await import('@/app/api/admin/extend/route');
    const req = new NextRequest(
      'http://localhost/api/admin/extend?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ key: 'ADIA-EXTN-TOKN-AAAA', days: 10 }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
  });

  it('returns days in the response body', async () => {
    const futureExpiry = new Date(Date.now() + 30 * 86400 * 1000).toISOString();
    insertLicense({ key: 'ADIA-EXTN-DAYS-AAAA', email: 'days@example.com', plan: 'yearly', expiresAt: futureExpiry });

    const res = await callExtend({ key: 'ADIA-EXTN-DAYS-AAAA', days: 90 });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.days).toBe(90);
  });

  it('allows extending a canceled license (no status gate)', async () => {
    const futureExpiry = new Date(Date.now() + 30 * 86400 * 1000).toISOString();
    insertLicense({ key: 'ADIA-EXTN-CNCL-AAAA', email: 'canceled@example.com', plan: 'monthly', expiresAt: futureExpiry });
    const { setStatus } = await import('@/lib/db');
    setStatus('ADIA-EXTN-CNCL-AAAA', 'canceled');

    const res = await callExtend({ key: 'ADIA-EXTN-CNCL-AAAA', days: 30 });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
  });
});

// ─── POST /api/admin/change-plan ─────────────────────────────────────────────

async function callChangePlan(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/change-plan/route');
  const req = new NextRequest('http://localhost/api/admin/change-plan', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', ...authHeader(token) },
  });
  return POST(req);
}

describe('POST /api/admin/change-plan', () => {
  it('returns 401 without a token', async () => {
    const { POST } = await import('@/app/api/admin/change-plan/route');
    const req = new NextRequest('http://localhost/api/admin/change-plan', {
      method: 'POST',
      body: JSON.stringify({ key: 'ADIA-XXXX-XXXX-XXXX', plan: 'lifetime' }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callChangePlan({ key: 'ADIA-XXXX-XXXX-XXXX', plan: 'lifetime' }, 'bad-token');
    expect(res.status).toBe(401);
  });

  it('returns 400 when key is missing from body', async () => {
    const res = await callChangePlan({ plan: 'lifetime' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing key/i);
  });

  it('returns 400 when plan is missing from body', async () => {
    const res = await callChangePlan({ key: 'ADIA-CHPL-NOPL-AAAA' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing plan/i);
  });

  it('returns 400 when plan is not a valid value', async () => {
    const res = await callChangePlan({ key: 'ADIA-CHPL-BADP-AAAA', plan: 'enterprise' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/invalid plan/i);
  });

  it('returns 404 for unknown key', async () => {
    const res = await callChangePlan({ key: 'ADIA-CHPL-UNKN-XXXX', plan: 'yearly' });
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body.error).toMatch(/unknown key/i);
  });

  it('returns 422 when plan is already the same', async () => {
    insertLicense({ key: 'ADIA-CHPL-SAME-AAAA', email: 'same@example.com', plan: 'monthly', expiresAt: null });
    const res = await callChangePlan({ key: 'ADIA-CHPL-SAME-AAAA', plan: 'monthly' });
    expect(res.status).toBe(422);
    const body = await res.json();
    expect(body.error).toMatch(/already on the monthly plan/i);
  });

  it('changes plan from monthly to yearly and returns previousPlan', async () => {
    insertLicense({ key: 'ADIA-CHPL-M2Y-AAAA', email: 'm2y@example.com', plan: 'monthly', expiresAt: null });

    const res = await callChangePlan({ key: 'ADIA-CHPL-M2Y-AAAA', plan: 'yearly' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.key).toBe('ADIA-CHPL-M2Y-AAAA');
    expect(body.previousPlan).toBe('monthly');
    expect(body.newPlan).toBe('yearly');
  });

  it('changes plan from yearly to lifetime', async () => {
    insertLicense({ key: 'ADIA-CHPL-Y2L-AAAA', email: 'y2l@example.com', plan: 'yearly', expiresAt: '2027-01-01T00:00:00.000Z' });

    const res = await callChangePlan({ key: 'ADIA-CHPL-Y2L-AAAA', plan: 'lifetime' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.previousPlan).toBe('yearly');
    expect(body.newPlan).toBe('lifetime');
  });

  it('changes plan from lifetime to monthly', async () => {
    insertLicense({ key: 'ADIA-CHPL-L2M-AAAA', email: 'l2m@example.com', plan: 'lifetime', expiresAt: null });

    const res = await callChangePlan({ key: 'ADIA-CHPL-L2M-AAAA', plan: 'monthly' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.previousPlan).toBe('lifetime');
    expect(body.newPlan).toBe('monthly');
  });

  it('persists the new plan to the database', async () => {
    insertLicense({ key: 'ADIA-CHPL-PERS-AAAA', email: 'persist@example.com', plan: 'monthly', expiresAt: null });

    await callChangePlan({ key: 'ADIA-CHPL-PERS-AAAA', plan: 'lifetime' });

    const updated = findLicense('ADIA-CHPL-PERS-AAAA');
    expect(updated?.plan).toBe('lifetime');
  });

  it('normalizes key to uppercase before lookup', async () => {
    insertLicense({ key: 'ADIA-CHPL-NORM-AAAA', email: 'norm@example.com', plan: 'monthly', expiresAt: null });

    const res = await callChangePlan({ key: 'adia-chpl-norm-aaaa', plan: 'yearly' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.key).toBe('ADIA-CHPL-NORM-AAAA');
  });

  it('accepts ?token= query param auth', async () => {
    insertLicense({ key: 'ADIA-CHPL-TOKN-AAAA', email: 'tokn@example.com', plan: 'monthly', expiresAt: null });

    const { POST } = await import('@/app/api/admin/change-plan/route');
    const req = new NextRequest(
      'http://localhost/api/admin/change-plan?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ key: 'ADIA-CHPL-TOKN-AAAA', plan: 'yearly' }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
  });

  it('allows changing plan of a canceled license — no status gate', async () => {
    insertLicense({ key: 'ADIA-CHPL-CNCL-AAAA', email: 'cncl@example.com', plan: 'monthly', expiresAt: null });
    const { setStatus } = await import('@/lib/db');
    setStatus('ADIA-CHPL-CNCL-AAAA', 'canceled');

    const res = await callChangePlan({ key: 'ADIA-CHPL-CNCL-AAAA', plan: 'lifetime' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.newPlan).toBe('lifetime');
  });
});

// ─── POST /api/admin/bulk-change-plan ────────────────────────────────────────

async function callBulkChangePlan(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/bulk-change-plan/route');
  const req = new NextRequest('http://localhost/api/admin/bulk-change-plan', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
  });
  return POST(req);
}

describe('POST /api/admin/bulk-change-plan', () => {
  it('returns 401 without a token', async () => {
    const { POST } = await import('@/app/api/admin/bulk-change-plan/route');
    const req = new NextRequest('http://localhost/api/admin/bulk-change-plan', {
      method: 'POST',
      body: JSON.stringify({ keys: ['ADIA-BKPL-NOAU-AAAA'], plan: 'yearly' }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callBulkChangePlan({ keys: ['ADIA-BKPL-WRNG-AAAA'], plan: 'yearly' }, 'bad-token');
    expect(res.status).toBe(401);
  });

  it('returns 400 when keys is missing', async () => {
    const res = await callBulkChangePlan({ plan: 'yearly' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing.*keys/i);
  });

  it('returns 400 when keys is an empty array', async () => {
    const res = await callBulkChangePlan({ keys: [], plan: 'yearly' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing.*keys|empty/i);
  });

  it('returns 400 when keys exceeds 100 items', async () => {
    const keys = Array.from({ length: 101 }, (_, i) => `ADIA-BKPL-OVFL-${String(i).padStart(4, '0')}`);
    const res = await callBulkChangePlan({ keys, plan: 'yearly' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/too many/i);
  });

  it('returns 400 when plan is missing', async () => {
    const res = await callBulkChangePlan({ keys: ['ADIA-BKPL-NOPLN-AA'] });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing plan/i);
  });

  it('returns 400 when plan is invalid', async () => {
    const res = await callBulkChangePlan({ keys: ['ADIA-BKPL-INVPLN-A'], plan: 'enterprise' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/invalid plan/i);
  });

  it('changes plan for a single key and returns changed array', async () => {
    insertLicense({ key: 'ADIA-BKPL-SING-AAAA', email: 'bulk1@example.com', plan: 'monthly', expiresAt: null });

    const res = await callBulkChangePlan({ keys: ['ADIA-BKPL-SING-AAAA'], plan: 'yearly' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.plan).toBe('yearly');
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0]).toMatchObject({ key: 'ADIA-BKPL-SING-AAAA', previousPlan: 'monthly' });
    expect(body.skipped).toHaveLength(0);
  });

  it('changes plan for multiple keys in one request', async () => {
    insertLicense({ key: 'ADIA-BKPL-MUL1-AAAA', email: 'bkmul1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-BKPL-MUL2-BBBB', email: 'bkmul2@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-BKPL-MUL3-CCCC', email: 'bkmul3@example.com', plan: 'monthly', expiresAt: null });

    const res = await callBulkChangePlan({
      keys: ['ADIA-BKPL-MUL1-AAAA', 'ADIA-BKPL-MUL2-BBBB', 'ADIA-BKPL-MUL3-CCCC'],
      plan: 'lifetime',
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(3);
    expect(body.skipped).toHaveLength(0);
    // All three should have previousPlan=monthly and show up in changed.
    const changedKeys = body.changed.map((c: { key: string }) => c.key);
    expect(changedKeys).toContain('ADIA-BKPL-MUL1-AAAA');
    expect(changedKeys).toContain('ADIA-BKPL-MUL2-BBBB');
    expect(changedKeys).toContain('ADIA-BKPL-MUL3-CCCC');
  });

  it('skips keys already on the target plan with reason=already_on_plan', async () => {
    insertLicense({ key: 'ADIA-BKPL-SKIP-AAAA', email: 'bkskip@example.com', plan: 'yearly', expiresAt: null });

    const res = await callBulkChangePlan({ keys: ['ADIA-BKPL-SKIP-AAAA'], plan: 'yearly' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0]).toMatchObject({ key: 'ADIA-BKPL-SKIP-AAAA', reason: 'already_on_plan' });
  });

  it('skips unknown keys with reason=not_found', async () => {
    const res = await callBulkChangePlan({ keys: ['ADIA-BKPL-UNKN-ZZZZ'], plan: 'monthly' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0]).toMatchObject({ key: 'ADIA-BKPL-UNKN-ZZZZ', reason: 'not_found' });
  });

  it('mixes changed and skipped in the same batch', async () => {
    insertLicense({ key: 'ADIA-BKPL-MIX1-AAAA', email: 'bkmix1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-BKPL-MIX2-BBBB', email: 'bkmix2@example.com', plan: 'yearly', expiresAt: null });
    // MIX3 does not exist.

    const res = await callBulkChangePlan({
      keys: ['ADIA-BKPL-MIX1-AAAA', 'ADIA-BKPL-MIX2-BBBB', 'ADIA-BKPL-MIX3-CCCC'],
      plan: 'yearly',
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BKPL-MIX1-AAAA');
    expect(body.skipped).toHaveLength(2);
    const skippedReasons = Object.fromEntries(
      body.skipped.map((s: { key: string; reason: string }) => [s.key, s.reason]),
    );
    expect(skippedReasons['ADIA-BKPL-MIX2-BBBB']).toBe('already_on_plan');
    expect(skippedReasons['ADIA-BKPL-MIX3-CCCC']).toBe('not_found');
  });

  it('normalizes keys to uppercase', async () => {
    insertLicense({ key: 'ADIA-BKPL-CASE-AAAA', email: 'bkcase@example.com', plan: 'monthly', expiresAt: null });

    const res = await callBulkChangePlan({ keys: ['adia-bkpl-case-aaaa'], plan: 'lifetime' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BKPL-CASE-AAAA');
  });

  it('persists the new plan to the database', async () => {
    insertLicense({ key: 'ADIA-BKPL-PRST-AAAA', email: 'bkprst@example.com', plan: 'monthly', expiresAt: null });

    await callBulkChangePlan({ keys: ['ADIA-BKPL-PRST-AAAA'], plan: 'lifetime' });

    const { findLicense: fl } = await import('@/lib/db');
    const license = fl('ADIA-BKPL-PRST-AAAA');
    expect(license?.plan).toBe('lifetime');
  });

  it('accepts ?token= query param auth', async () => {
    insertLicense({ key: 'ADIA-BKPL-TOKN-AAAA', email: 'bktokn@example.com', plan: 'monthly', expiresAt: null });
    const { POST } = await import('@/app/api/admin/bulk-change-plan/route');
    const req = new NextRequest(
      'http://localhost/api/admin/bulk-change-plan?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ keys: ['ADIA-BKPL-TOKN-AAAA'], plan: 'yearly' }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
  });
});

// ─── POST /api/admin/bulk-revoke ─────────────────────────────────────────────

async function callBulkRevoke(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/bulk-revoke/route');
  const req = new NextRequest('http://localhost/api/admin/bulk-revoke', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
  });
  return POST(req);
}

describe('POST /api/admin/bulk-revoke', () => {
  it('returns 401 without a token', async () => {
    delete process.env.ADMIN_TOKEN;
    const { POST } = await import('@/app/api/admin/bulk-revoke/route');
    const req = new NextRequest('http://localhost/api/admin/bulk-revoke', {
      method: 'POST',
      body: JSON.stringify({ keys: ['ADIA-BKRV-NTKN-AAAA'] }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callBulkRevoke({ keys: ['ADIA-BKRV-WTKN-AAAA'] }, 'bad-token');
    expect(res.status).toBe(401);
  });

  it('returns 400 when keys is missing', async () => {
    const res = await callBulkRevoke({});
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing or empty keys/i);
  });

  it('returns 400 when keys is an empty array', async () => {
    const res = await callBulkRevoke({ keys: [] });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing or empty keys/i);
  });

  it('returns 400 when keys array exceeds 100', async () => {
    const keys = Array.from({ length: 101 }, (_, i) => `ADIA-BKRV-TOO${i}-AAAA`);
    const res = await callBulkRevoke({ keys });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/too many keys/i);
    expect(body.error).toMatch(/100/);
  });

  it('revokes a single active license', async () => {
    insertLicense({ key: 'ADIA-BKRV-SING-AAAA', email: 'bkrvsing@example.com', plan: 'monthly', expiresAt: null });

    const res = await callBulkRevoke({ keys: ['ADIA-BKRV-SING-AAAA'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BKRV-SING-AAAA');
    expect(body.changed[0].previousStatus).toBe('active');
    expect(body.skipped).toHaveLength(0);
  });

  it('revokes multiple active licenses in one call', async () => {
    insertLicense({ key: 'ADIA-BKRV-MUL1-AAAA', email: 'bkrvmul1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-BKRV-MUL2-BBBB', email: 'bkrvmul2@example.com', plan: 'yearly', expiresAt: null });
    insertLicense({ key: 'ADIA-BKRV-MUL3-CCCC', email: 'bkrvmul3@example.com', plan: 'lifetime', expiresAt: null });

    const res = await callBulkRevoke({ keys: ['ADIA-BKRV-MUL1-AAAA', 'ADIA-BKRV-MUL2-BBBB', 'ADIA-BKRV-MUL3-CCCC'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(3);
    expect(body.skipped).toHaveLength(0);
  });

  it('skips already-canceled licenses with reason "already_revoked"', async () => {
    insertLicense({ key: 'ADIA-BKRV-SKIP-AAAA', email: 'bkrvskip@example.com', plan: 'monthly', expiresAt: null });
    const { setStatus: ss } = await import('@/lib/db');
    ss('ADIA-BKRV-SKIP-AAAA', 'canceled');

    const res = await callBulkRevoke({ keys: ['ADIA-BKRV-SKIP-AAAA'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0].key).toBe('ADIA-BKRV-SKIP-AAAA');
    expect(body.skipped[0].reason).toBe('already_revoked');
  });

  it('skips unknown keys with reason "not_found"', async () => {
    const res = await callBulkRevoke({ keys: ['ADIA-BKRV-UNKN-ZZZZ'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0].key).toBe('ADIA-BKRV-UNKN-ZZZZ');
    expect(body.skipped[0].reason).toBe('not_found');
  });

  it('handles a mixed batch of active, already-canceled, and not-found keys', async () => {
    insertLicense({ key: 'ADIA-BKRV-MIX1-AAAA', email: 'bkrvmix1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-BKRV-MIX2-BBBB', email: 'bkrvmix2@example.com', plan: 'yearly', expiresAt: null });
    const { setStatus: ss } = await import('@/lib/db');
    ss('ADIA-BKRV-MIX2-BBBB', 'canceled');

    const res = await callBulkRevoke({
      keys: ['ADIA-BKRV-MIX1-AAAA', 'ADIA-BKRV-MIX2-BBBB', 'ADIA-BKRV-NOPE-ZZZZ'],
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BKRV-MIX1-AAAA');
    expect(body.skipped).toHaveLength(2);
    const reasons = body.skipped.map((s: any) => s.reason);
    expect(reasons).toContain('already_revoked');
    expect(reasons).toContain('not_found');
  });

  it('normalizes keys to uppercase', async () => {
    insertLicense({ key: 'ADIA-BKRV-CASE-AAAA', email: 'bkrvcase@example.com', plan: 'monthly', expiresAt: null });

    const res = await callBulkRevoke({ keys: ['adia-bkrv-case-aaaa'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BKRV-CASE-AAAA');
  });

  it('persists the canceled status to the database', async () => {
    insertLicense({ key: 'ADIA-BKRV-PRST-AAAA', email: 'bkrvprst@example.com', plan: 'monthly', expiresAt: null });

    await callBulkRevoke({ keys: ['ADIA-BKRV-PRST-AAAA'] });

    const { findLicense: fl } = await import('@/lib/db');
    const license = fl('ADIA-BKRV-PRST-AAAA');
    expect(license?.status).toBe('canceled');
  });

  it('accepts ?token= query param auth', async () => {
    insertLicense({ key: 'ADIA-BKRV-TOKN-AAAA', email: 'bkrvtokn@example.com', plan: 'monthly', expiresAt: null });
    const { POST } = await import('@/app/api/admin/bulk-revoke/route');
    const req = new NextRequest(
      'http://localhost/api/admin/bulk-revoke?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ keys: ['ADIA-BKRV-TOKN-AAAA'] }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
  });
});

// ─── GET /api/admin/stats ─────────────────────────────────────────────────────

async function callStats(token = 'test-admin-token') {
  const { GET } = await import('@/app/api/admin/stats/route');
  const req = new NextRequest('http://localhost/api/admin/stats', {
    method: 'GET',
    headers: { Authorization: `Bearer ${token}` },
  });
  return GET(req);
}

describe('GET /api/admin/stats', () => {
  it('returns 401 without a token', async () => {
    delete process.env.ADMIN_TOKEN;
    const { GET } = await import('@/app/api/admin/stats/route');
    const req = new NextRequest('http://localhost/api/admin/stats', { method: 'GET' });
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callStats('bad-token');
    expect(res.status).toBe(401);
  });

  it('returns zeroed stats for an empty database', async () => {
    const res = await callStats();
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.total).toBe(0);
    expect(body.byStatus).toEqual({});
    expect(body.byPlan).toEqual({});
    expect(body.newLast7Days).toBe(0);
    expect(body.newLast30Days).toBe(0);
    expect(body.activatedMachines).toBe(0);
  });

  it('counts total licenses correctly', async () => {
    insertLicense({ key: 'ADIA-STAT-TOT1-AAAA', email: 'a@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-STAT-TOT2-BBBB', email: 'b@example.com', plan: 'yearly', expiresAt: null });
    const res = await callStats();
    const body = await res.json();
    expect(body.total).toBe(2);
  });

  it('breaks down counts by plan', async () => {
    insertLicense({ key: 'ADIA-STAT-PLN1-AAAA', email: 'p1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-STAT-PLN2-BBBB', email: 'p2@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-STAT-PLN3-CCCC', email: 'p3@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callStats();
    const body = await res.json();
    expect(body.byPlan).toMatchObject({ monthly: 2, lifetime: 1 });
    expect(body.byPlan.yearly).toBeUndefined();
  });

  it('breaks down counts by status', async () => {
    insertLicense({ key: 'ADIA-STAT-ST1A-AAAA', email: 's1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-STAT-ST2B-BBBB', email: 's2@example.com', plan: 'yearly', expiresAt: null });
    const { setStatus } = await import('@/lib/db');
    setStatus('ADIA-STAT-ST2B-BBBB', 'canceled');
    const res = await callStats();
    const body = await res.json();
    expect(body.byStatus).toMatchObject({ active: 1, canceled: 1 });
  });

  it('counts new licenses in the last 7 and 30 days', async () => {
    insertLicense({ key: 'ADIA-STAT-NEW1-AAAA', email: 'n1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-STAT-NEW2-BBBB', email: 'n2@example.com', plan: 'yearly', expiresAt: null });
    const res = await callStats();
    const body = await res.json();
    expect(body.newLast7Days).toBe(2);
    expect(body.newLast30Days).toBe(2);
  });

  it('counts activated machines across all licenses', async () => {
    insertLicense({ key: 'ADIA-STAT-MCH1-AAAA', email: 'm1@example.com', plan: 'monthly', expiresAt: null });
    recordActivation('ADIA-STAT-MCH1-AAAA', 'machine-hash-one');
    recordActivation('ADIA-STAT-MCH1-AAAA', 'machine-hash-two');
    const res = await callStats();
    const body = await res.json();
    expect(body.activatedMachines).toBe(2);
  });

  it('accepts ?token= query param auth', async () => {
    const { GET } = await import('@/app/api/admin/stats/route');
    const req = new NextRequest(
      'http://localhost/api/admin/stats?token=test-admin-token',
      { method: 'GET' },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
  });

  it('expiringIn30Days is 0 when no licenses are expiring', async () => {
    const res = await callStats();
    const body = await res.json();
    expect(body.expiringIn30Days).toBe(0);
  });

  it('expiringIn30Days counts active licenses whose expiresAt is within 30 days', async () => {
    const { setIssuedAt } = await import('@/lib/db');
    const soon = new Date(Date.now() + 10 * 24 * 60 * 60 * 1000).toISOString();
    const late = new Date(Date.now() + 60 * 24 * 60 * 60 * 1000).toISOString();
    insertLicense({ key: 'ADIA-STAT-EX10-AAAA', email: 'ex10@example.com', plan: 'monthly', expiresAt: soon });
    insertLicense({ key: 'ADIA-STAT-EX60-BBBB', email: 'ex60@example.com', plan: 'monthly', expiresAt: late });
    const res = await callStats();
    const body = await res.json();
    expect(body.expiringIn30Days).toBe(1);
  });

  it('expiringIn30Days excludes lifetime licenses', async () => {
    insertLicense({ key: 'ADIA-STAT-EXLF-AAAA', email: 'exlf@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callStats();
    const body = await res.json();
    expect(body.expiringIn30Days).toBe(0);
  });

  it('expiringIn30Days excludes already-expired licenses', async () => {
    const past = new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString();
    insertLicense({ key: 'ADIA-STAT-EXPS-AAAA', email: 'exps@example.com', plan: 'monthly', expiresAt: past });
    const res = await callStats();
    const body = await res.json();
    expect(body.expiringIn30Days).toBe(0);
  });

  it('expiringIn30Days excludes non-active licenses', async () => {
    const { setStatus } = await import('@/lib/db');
    const soon = new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toISOString();
    insertLicense({ key: 'ADIA-STAT-EXCA-AAAA', email: 'exca@example.com', plan: 'monthly', expiresAt: soon });
    setStatus('ADIA-STAT-EXCA-AAAA', 'canceled');
    const res = await callStats();
    const body = await res.json();
    expect(body.expiringIn30Days).toBe(0);
  });
});

// ─── POST /api/admin/bulk-reactivate ─────────────────────────────────────────

async function callBulkReactivate(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/bulk-reactivate/route');
  const req = new NextRequest('http://localhost/api/admin/bulk-reactivate', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
  });
  return POST(req);
}

describe('POST /api/admin/bulk-reactivate', () => {
  it('returns 401 without a token', async () => {
    delete process.env.ADMIN_TOKEN;
    const { POST } = await import('@/app/api/admin/bulk-reactivate/route');
    const req = new NextRequest('http://localhost/api/admin/bulk-reactivate', {
      method: 'POST',
      body: JSON.stringify({ keys: ['ADIA-BKRA-NTKN-AAAA'] }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callBulkReactivate({ keys: ['ADIA-BKRA-WTKN-AAAA'] }, 'bad-token');
    expect(res.status).toBe(401);
  });

  it('returns 400 when keys is missing', async () => {
    const res = await callBulkReactivate({});
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing or empty keys/i);
  });

  it('returns 400 when keys is an empty array', async () => {
    const res = await callBulkReactivate({ keys: [] });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing or empty keys/i);
  });

  it('returns 400 when keys array exceeds 100', async () => {
    const keys = Array.from({ length: 101 }, (_, i) => `ADIA-BKRA-TOO${i}-AAAA`);
    const res = await callBulkReactivate({ keys });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/too many keys/i);
    expect(body.error).toMatch(/100/);
  });

  it('reactivates a single canceled license', async () => {
    insertLicense({ key: 'ADIA-BKRA-SING-AAAA', email: 'bkrasing@example.com', plan: 'monthly', expiresAt: null });
    setStatus('ADIA-BKRA-SING-AAAA', 'canceled');

    const res = await callBulkReactivate({ keys: ['ADIA-BKRA-SING-AAAA'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BKRA-SING-AAAA');
    expect(body.changed[0].previousStatus).toBe('canceled');
    expect(body.skipped).toHaveLength(0);
  });

  it('reactivates multiple canceled licenses in one call', async () => {
    insertLicense({ key: 'ADIA-BKRA-MUL1-AAAA', email: 'bkramul1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-BKRA-MUL2-BBBB', email: 'bkramul2@example.com', plan: 'yearly', expiresAt: null });
    insertLicense({ key: 'ADIA-BKRA-MUL3-CCCC', email: 'bkramul3@example.com', plan: 'lifetime', expiresAt: null });
    setStatus('ADIA-BKRA-MUL1-AAAA', 'canceled');
    setStatus('ADIA-BKRA-MUL2-BBBB', 'expired');
    setStatus('ADIA-BKRA-MUL3-CCCC', 'past_due');

    const res = await callBulkReactivate({ keys: ['ADIA-BKRA-MUL1-AAAA', 'ADIA-BKRA-MUL2-BBBB', 'ADIA-BKRA-MUL3-CCCC'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(3);
    expect(body.skipped).toHaveLength(0);
  });

  it('skips already-active licenses with reason "already_active"', async () => {
    insertLicense({ key: 'ADIA-BKRA-SKIP-AAAA', email: 'bkraskip@example.com', plan: 'monthly', expiresAt: null });

    const res = await callBulkReactivate({ keys: ['ADIA-BKRA-SKIP-AAAA'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0].key).toBe('ADIA-BKRA-SKIP-AAAA');
    expect(body.skipped[0].reason).toBe('already_active');
  });

  it('skips unknown keys with reason "not_found"', async () => {
    const res = await callBulkReactivate({ keys: ['ADIA-BKRA-UNKN-ZZZZ'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0].key).toBe('ADIA-BKRA-UNKN-ZZZZ');
    expect(body.skipped[0].reason).toBe('not_found');
  });

  it('handles a mixed batch of canceled, already-active, and not-found keys', async () => {
    insertLicense({ key: 'ADIA-BKRA-MIX1-AAAA', email: 'bkramix1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-BKRA-MIX2-BBBB', email: 'bkramix2@example.com', plan: 'yearly', expiresAt: null });
    setStatus('ADIA-BKRA-MIX1-AAAA', 'canceled');

    const res = await callBulkReactivate({
      keys: ['ADIA-BKRA-MIX1-AAAA', 'ADIA-BKRA-MIX2-BBBB', 'ADIA-BKRA-NOPE-ZZZZ'],
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BKRA-MIX1-AAAA');
    expect(body.skipped).toHaveLength(2);
    const reasons = body.skipped.map((s: any) => s.reason);
    expect(reasons).toContain('already_active');
    expect(reasons).toContain('not_found');
  });

  it('normalizes keys to uppercase', async () => {
    insertLicense({ key: 'ADIA-BKRA-CASE-AAAA', email: 'bkracase@example.com', plan: 'monthly', expiresAt: null });
    setStatus('ADIA-BKRA-CASE-AAAA', 'canceled');

    const res = await callBulkReactivate({ keys: ['adia-bkra-case-aaaa'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BKRA-CASE-AAAA');
  });

  it('persists the active status to the database', async () => {
    insertLicense({ key: 'ADIA-BKRA-PRST-AAAA', email: 'bkraprst@example.com', plan: 'monthly', expiresAt: null });
    setStatus('ADIA-BKRA-PRST-AAAA', 'canceled');

    await callBulkReactivate({ keys: ['ADIA-BKRA-PRST-AAAA'] });

    const { findLicense: fl } = await import('@/lib/db');
    const license = fl('ADIA-BKRA-PRST-AAAA');
    expect(license?.status).toBe('active');
  });

  it('writes an audit log entry for each reactivated key', async () => {
    insertLicense({ key: 'ADIA-BKRA-AUDT-AAAA', email: 'bkraaudt@example.com', plan: 'monthly', expiresAt: null });
    setStatus('ADIA-BKRA-AUDT-AAAA', 'expired');

    await callBulkReactivate({ keys: ['ADIA-BKRA-AUDT-AAAA'] });

    const { listAuditLog } = await import('@/lib/db');
    const logs = listAuditLog({ licenseKey: 'ADIA-BKRA-AUDT-AAAA' });
    const reactivateLog = logs.find((l) => l.action === 'reactivate');
    expect(reactivateLog).toBeDefined();
    const detail = JSON.parse(reactivateLog!.detail ?? '{}');
    expect(detail.bulk).toBe(true);
    expect(detail.previousStatus).toBe('expired');
    expect(detail.newStatus).toBe('active');
  });

  it('does not write an audit log for skipped keys', async () => {
    insertLicense({ key: 'ADIA-BKRA-NSKP-AAAA', email: 'bkranskp@example.com', plan: 'monthly', expiresAt: null });

    await callBulkReactivate({ keys: ['ADIA-BKRA-NSKP-AAAA'] });

    const { listAuditLog } = await import('@/lib/db');
    const logs = listAuditLog({ licenseKey: 'ADIA-BKRA-NSKP-AAAA' });
    const reactivateLog = logs.find((l) => l.action === 'reactivate');
    expect(reactivateLog).toBeUndefined();
  });

  it('accepts ?token= query param auth', async () => {
    insertLicense({ key: 'ADIA-BKRA-TOKN-AAAA', email: 'bkratokn@example.com', plan: 'monthly', expiresAt: null });
    setStatus('ADIA-BKRA-TOKN-AAAA', 'canceled');
    const { POST } = await import('@/app/api/admin/bulk-reactivate/route');
    const req = new NextRequest(
      'http://localhost/api/admin/bulk-reactivate?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ keys: ['ADIA-BKRA-TOKN-AAAA'] }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
  });
}); // end bulk-reactivate

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/admin/bulk-set-status
// ─────────────────────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-set-status', () => {
  async function callBulkSetStatus(body: unknown, token = 'test-admin-token') {
    const { POST } = await import('@/app/api/admin/bulk-set-status/route');
    const req = new NextRequest('http://localhost/api/admin/bulk-set-status', {
      method: 'POST',
      body: JSON.stringify(body),
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    });
    return POST(req);
  }

  it('returns 401 with no token', async () => {
    const res = await callBulkSetStatus({ keys: ['ADIA-BKSS-AUTH-AAAA'], status: 'canceled' }, '');
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callBulkSetStatus({ keys: ['ADIA-BKSS-AUTH-BBBB'], status: 'canceled' }, 'wrong');
    expect(res.status).toBe(401);
  });

  it('returns 400 when keys is missing', async () => {
    const res = await callBulkSetStatus({ status: 'canceled' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing or empty/);
  });

  it('returns 400 when keys is empty array', async () => {
    const res = await callBulkSetStatus({ keys: [], status: 'canceled' });
    expect(res.status).toBe(400);
  });

  it('returns 400 when more than 100 keys are provided', async () => {
    const keys = Array.from({ length: 101 }, (_, i) => `ADIA-BKSS-MANY-${String(i).padStart(4, '0')}`);
    const res = await callBulkSetStatus({ keys, status: 'canceled' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/100/);
  });

  it('returns 400 when status is invalid', async () => {
    insertLicense({ key: 'ADIA-BKSS-INVS-AAAA', email: 'bkssInvs@example.com', plan: 'monthly', expiresAt: null });
    const res = await callBulkSetStatus({ keys: ['ADIA-BKSS-INVS-AAAA'], status: 'banned' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/invalid status/);
  });

  it('returns 400 when status is missing', async () => {
    insertLicense({ key: 'ADIA-BKSS-NSTS-AAAA', email: 'bkssNsts@example.com', plan: 'monthly', expiresAt: null });
    const res = await callBulkSetStatus({ keys: ['ADIA-BKSS-NSTS-AAAA'] });
    expect(res.status).toBe(400);
  });

  it('sets a single active license to canceled', async () => {
    insertLicense({ key: 'ADIA-BKSS-SNGL-AAAA', email: 'bkssSingle@example.com', plan: 'monthly', expiresAt: null });
    const res = await callBulkSetStatus({ keys: ['ADIA-BKSS-SNGL-AAAA'], status: 'canceled' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BKSS-SNGL-AAAA');
    expect(body.changed[0].previousStatus).toBe('active');
    expect(body.skipped).toHaveLength(0);
  });

  it('sets a canceled license to expired', async () => {
    insertLicense({ key: 'ADIA-BKSS-C2E-AAAA', email: 'bkssC2e@example.com', plan: 'monthly', expiresAt: null });
    setStatus('ADIA-BKSS-C2E-AAAA', 'canceled');
    const res = await callBulkSetStatus({ keys: ['ADIA-BKSS-C2E-AAAA'], status: 'expired' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed[0].previousStatus).toBe('canceled');
  });

  it('sets a batch of 3 licenses to past_due', async () => {
    insertLicense({ key: 'ADIA-BKSS-BAT-AAAA', email: 'bkssA@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-BKSS-BAT-BBBB', email: 'bkssB@example.com', plan: 'yearly', expiresAt: null });
    insertLicense({ key: 'ADIA-BKSS-BAT-CCCC', email: 'bkssC@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callBulkSetStatus({
      keys: ['ADIA-BKSS-BAT-AAAA', 'ADIA-BKSS-BAT-BBBB', 'ADIA-BKSS-BAT-CCCC'],
      status: 'past_due',
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(3);
    expect(body.skipped).toHaveLength(0);
  });

  it('skips licenses already at the target status with reason already_set', async () => {
    insertLicense({ key: 'ADIA-BKSS-ALRD-AAAA', email: 'bkssAlrd@example.com', plan: 'monthly', expiresAt: null });
    const res = await callBulkSetStatus({ keys: ['ADIA-BKSS-ALRD-AAAA'], status: 'active' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0].reason).toBe('already_set');
  });

  it('skips unknown keys with reason not_found', async () => {
    const res = await callBulkSetStatus({ keys: ['ADIA-BKSS-UNKN-ZZZZ'], status: 'canceled' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0].reason).toBe('not_found');
  });

  it('handles mixed batch: 1 changed, 1 already_set, 1 not_found', async () => {
    insertLicense({ key: 'ADIA-BKSS-MIX-AAAA', email: 'bkssMixA@example.com', plan: 'monthly', expiresAt: null });
    setStatus('ADIA-BKSS-MIX-AAAA', 'expired');
    insertLicense({ key: 'ADIA-BKSS-MIX-BBBB', email: 'bkssMixB@example.com', plan: 'monthly', expiresAt: null });
    const res = await callBulkSetStatus({
      keys: ['ADIA-BKSS-MIX-AAAA', 'ADIA-BKSS-MIX-BBBB', 'ADIA-BKSS-UNKN-MXZZ'],
      status: 'active',
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BKSS-MIX-AAAA');
    expect(body.skipped).toHaveLength(2);
    const reasons = body.skipped.map((s: { reason: string }) => s.reason);
    expect(reasons).toContain('already_set');
    expect(reasons).toContain('not_found');
  });

  it('normalizes keys to uppercase', async () => {
    insertLicense({ key: 'ADIA-BKSS-CASE-AAAA', email: 'bkssCase@example.com', plan: 'monthly', expiresAt: null });
    setStatus('ADIA-BKSS-CASE-AAAA', 'canceled');
    const res = await callBulkSetStatus({ keys: ['adia-bkss-case-aaaa'], status: 'active' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BKSS-CASE-AAAA');
  });

  it('persists the new status to the database', async () => {
    insertLicense({ key: 'ADIA-BKSS-PRST-AAAA', email: 'bkssPrst@example.com', plan: 'monthly', expiresAt: null });
    await callBulkSetStatus({ keys: ['ADIA-BKSS-PRST-AAAA'], status: 'expired' });
    const { findLicense: fl } = await import('@/lib/db');
    const license = fl('ADIA-BKSS-PRST-AAAA');
    expect(license?.status).toBe('expired');
  });

  it('writes an audit log entry with bulk:true for each changed key', async () => {
    insertLicense({ key: 'ADIA-BKSS-AUDT-AAAA', email: 'bkssAudt@example.com', plan: 'monthly', expiresAt: null });
    await callBulkSetStatus({ keys: ['ADIA-BKSS-AUDT-AAAA'], status: 'past_due' });
    const { listAuditLog } = await import('@/lib/db');
    const logs = listAuditLog({ licenseKey: 'ADIA-BKSS-AUDT-AAAA' });
    const setLog = logs.find((l) => l.action === 'set_status');
    expect(setLog).toBeDefined();
    const detail = JSON.parse(setLog!.detail ?? '{}');
    expect(detail.bulk).toBe(true);
    expect(detail.previousStatus).toBe('active');
    expect(detail.newStatus).toBe('past_due');
  });

  it('does not write an audit log for skipped keys', async () => {
    insertLicense({ key: 'ADIA-BKSS-NSKP-AAAA', email: 'bkssNskp@example.com', plan: 'monthly', expiresAt: null });
    await callBulkSetStatus({ keys: ['ADIA-BKSS-NSKP-AAAA'], status: 'active' });
    const { listAuditLog } = await import('@/lib/db');
    const logs = listAuditLog({ licenseKey: 'ADIA-BKSS-NSKP-AAAA' });
    expect(logs.find((l) => l.action === 'set_status')).toBeUndefined();
  });

  it('accepts ?token= query param auth', async () => {
    insertLicense({ key: 'ADIA-BKSS-TOKN-AAAA', email: 'bkssTokn@example.com', plan: 'monthly', expiresAt: null });
    setStatus('ADIA-BKSS-TOKN-AAAA', 'canceled');
    const { POST } = await import('@/app/api/admin/bulk-set-status/route');
    const req = new NextRequest(
      'http://localhost/api/admin/bulk-set-status?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ keys: ['ADIA-BKSS-TOKN-AAAA'], status: 'active' }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
  });
});

// ─── GET /api/admin/export-licenses ─────────────────────────────────────────

describe('GET /api/admin/export-licenses', () => {
  async function callExport(
    params: Record<string, string> = {},
    token = 'test-admin-token',
  ) {
    const { GET } = await import('@/app/api/admin/export-licenses/route');
    const sp = new URLSearchParams(params);
    const req = new NextRequest(
      `http://localhost/api/admin/export-licenses?${sp.toString()}`,
      { headers: { Authorization: `Bearer ${token}` } },
    );
    return GET(req);
  }

  it('returns 401 with no token', async () => {
    const { GET } = await import('@/app/api/admin/export-licenses/route');
    const req = new NextRequest('http://localhost/api/admin/export-licenses');
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callExport({}, 'bad-token');
    expect(res.status).toBe(401);
  });

  it('returns 400 for invalid format', async () => {
    const res = await callExport({ format: 'xml' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/format/);
  });

  it('returns 400 for invalid status', async () => {
    const res = await callExport({ status: 'banned' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/status/);
  });

  it('returns 400 for invalid plan', async () => {
    const res = await callExport({ plan: 'enterprise' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/plan/);
  });

  it('returns 400 for invalid since date', async () => {
    const res = await callExport({ since: 'not-a-date' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/since/);
  });

  it('returns CSV with correct Content-Type for empty table', async () => {
    const res = await callExport({ format: 'csv' });
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toMatch(/text\/csv/);
    const text = await res.text();
    expect(text.startsWith('key,email,plan,status,issuedAt,expiresAt,machineCount,note')).toBe(true);
  });

  it('returns JSON with licenses array for empty table', async () => {
    const res = await callExport({ format: 'json' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.licenses).toEqual([]);
    expect(body.count).toBe(0);
  });

  it('includes all licenses in CSV export', async () => {
    insertLicense({ key: 'ADIA-EXPRT-AAA-0001', email: 'exportA@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-EXPRT-BBB-0002', email: 'exportB@example.com', plan: 'yearly', expiresAt: null });
    const res = await callExport({ format: 'csv' });
    expect(res.status).toBe(200);
    const text = await res.text();
    const lines = text.split('\n');
    expect(lines.length).toBe(3); // header + 2 rows
    expect(text).toContain('ADIA-EXPRT-AAA-0001');
    expect(text).toContain('ADIA-EXPRT-BBB-0002');
  });

  it('includes all licenses in JSON export with machineCount', async () => {
    insertLicense({ key: 'ADIA-EXPRT-CCC-0003', email: 'exportC@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation('ADIA-EXPRT-CCC-0003', 'machine-abc');
    const res = await callExport({ format: 'json' });
    expect(res.status).toBe(200);
    const body = await res.json();
    const found = body.licenses.find((l: { key: string }) => l.key === 'ADIA-EXPRT-CCC-0003');
    expect(found).toBeDefined();
    expect(found.machineCount).toBe(1);
    expect(found.plan).toBe('lifetime');
  });

  it('filters by status', async () => {
    insertLicense({ key: 'ADIA-EXPRT-STA-0001', email: 'exprtSta1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-EXPRT-STA-0002', email: 'exprtSta2@example.com', plan: 'monthly', expiresAt: null });
    setStatus('ADIA-EXPRT-STA-0002', 'canceled');
    const res = await callExport({ format: 'json', status: 'active' });
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-EXPRT-STA-0001');
    expect(keys).not.toContain('ADIA-EXPRT-STA-0002');
  });

  it('filters by plan', async () => {
    insertLicense({ key: 'ADIA-EXPRT-PLN-0001', email: 'exprtPln1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-EXPRT-PLN-0002', email: 'exprtPln2@example.com', plan: 'yearly', expiresAt: null });
    const res = await callExport({ format: 'json', plan: 'yearly' });
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-EXPRT-PLN-0002');
    expect(keys).not.toContain('ADIA-EXPRT-PLN-0001');
  });

  it('filters by since date', async () => {
    insertLicense({ key: 'ADIA-EXPRT-SNC-0001', email: 'exprtSnc1@example.com', plan: 'monthly', expiresAt: null });
    setIssuedAt('ADIA-EXPRT-SNC-0001', '2020-01-01T00:00:00Z');
    insertLicense({ key: 'ADIA-EXPRT-SNC-0002', email: 'exprtSnc2@example.com', plan: 'monthly', expiresAt: null });
    setIssuedAt('ADIA-EXPRT-SNC-0002', '2030-01-01T00:00:00Z');
    const res = await callExport({ format: 'json', since: '2025-01-01' });
    const body = await res.json();
    const keys = body.licenses.map((l: { key: string }) => l.key);
    expect(keys).toContain('ADIA-EXPRT-SNC-0002');
    expect(keys).not.toContain('ADIA-EXPRT-SNC-0001');
  });

  it('CSV escapes commas and quotes in note field', async () => {
    insertLicense({ key: 'ADIA-EXPRT-ESC-0001', email: 'exprtEsc@example.com', plan: 'monthly', expiresAt: null });
    const { setNote } = await import('@/lib/db');
    setNote('ADIA-EXPRT-ESC-0001', 'has, comma and "quote"');
    const res = await callExport({ format: 'csv' });
    const text = await res.text();
    expect(text).toContain('"has, comma and ""quote"""');
  });

  it('Content-Disposition header includes a .csv filename', async () => {
    const res = await callExport({ format: 'csv' });
    const cd = res.headers.get('content-disposition') ?? '';
    expect(cd).toMatch(/attachment.*\.csv/);
  });

  it('accepts ?token= query-param auth', async () => {
    const { GET } = await import('@/app/api/admin/export-licenses/route');
    const req = new NextRequest(
      'http://localhost/api/admin/export-licenses?token=test-admin-token&format=json',
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
  });
});
