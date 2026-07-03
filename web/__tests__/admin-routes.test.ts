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
});
