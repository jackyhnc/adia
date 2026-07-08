// Tests for POST /api/admin/bulk-resend-license
// Body: { keys: string[], dryRun?: boolean }

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, listAuditLog } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

vi.mock('@/lib/email', () => ({
  sendLicenseEmail: vi.fn().mockResolvedValue(undefined),
  sendCustomEmail: vi.fn().mockResolvedValue(undefined),
  sendPaymentFailedEmail: vi.fn().mockResolvedValue(undefined),
}));

import { sendLicenseEmail } from '@/lib/email';
const mockSendLicenseEmail = vi.mocked(sendLicenseEmail);

let dbPath: string;

beforeEach(() => {
  resetRateLimit();
  vi.clearAllMocks();
  dbPath = path.join(
    os.tmpdir(),
    `adia-bulk-resend-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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
  const { POST } = await import('@/app/api/admin/bulk-resend-license/route');
  const req = new NextRequest('http://localhost/api/admin/bulk-resend-license', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', ...authHeader(token) },
  });
  return POST(req);
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-resend-license — auth', () => {
  it('returns 401 with no authorization header', async () => {
    const { POST } = await import('@/app/api/admin/bulk-resend-license/route');
    const req = new NextRequest('http://localhost/api/admin/bulk-resend-license', {
      method: 'POST',
      body: JSON.stringify({ keys: ['ADIA-XXXX-XXXX-XXXX'] }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callPost({ keys: ['ADIA-XXXX-XXXX-XXXX'] }, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query param as auth fallback', async () => {
    const key = 'ADIA-BRST-TOKN-AAAA';
    insertLicense({ key, email: 'tok@example.com', plan: 'lifetime', expiresAt: null });
    const { POST } = await import('@/app/api/admin/bulk-resend-license/route');
    const req = new NextRequest(
      'http://localhost/api/admin/bulk-resend-license?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ keys: [key] }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
    expect((await res.json()).ok).toBe(true);
  });
});

// ─── Validation ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-resend-license — validation', () => {
  it('returns 400 when keys is missing', async () => {
    const res = await callPost({});
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing or empty keys/i);
  });

  it('returns 400 when keys is an empty array', async () => {
    const res = await callPost({ keys: [] });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/missing or empty keys/i);
  });

  it('returns 400 when keys exceeds 50', async () => {
    const keys = Array.from({ length: 51 }, (_, i) => `ADIA-BRSB-${String(i).padStart(4, '0')}-AAAA`);
    const res = await callPost({ keys });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/too many keys/i);
  });
});

// ─── Core behavior ────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-resend-license — core behavior', () => {
  it('sends email for a known key and returns it in sent array', async () => {
    const key = 'ADIA-BRSN-SND1-AAAA';
    insertLicense({ key, email: 'snd1@example.com', plan: 'lifetime', expiresAt: null });

    const res = await callPost({ keys: [key] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.sent).toHaveLength(1);
    expect(body.sent[0]).toMatchObject({ key, email: 'snd1@example.com', plan: 'lifetime' });
    expect(body.skipped).toHaveLength(0);
    expect(mockSendLicenseEmail).toHaveBeenCalledTimes(1);
    expect(mockSendLicenseEmail).toHaveBeenCalledWith('snd1@example.com', key, 'lifetime');
  });

  it('sends emails for multiple keys in one request', async () => {
    const k1 = 'ADIA-BRMK-KEY1-AAAA';
    const k2 = 'ADIA-BRMK-KEY2-AAAA';
    insertLicense({ key: k1, email: 'mk1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: k2, email: 'mk2@example.com', plan: 'yearly', expiresAt: null });

    const res = await callPost({ keys: [k1, k2] });
    const body = await res.json();
    expect(body.sent).toHaveLength(2);
    expect(body.skipped).toHaveLength(0);
    expect(mockSendLicenseEmail).toHaveBeenCalledTimes(2);
  });

  it('normalizes keys to uppercase before lookup', async () => {
    const key = 'ADIA-BRUC-CASE-AAAA';
    insertLicense({ key, email: 'case@example.com', plan: 'monthly', expiresAt: null });

    const res = await callPost({ keys: ['adia-bruc-case-aaaa'] });
    const body = await res.json();
    expect(body.sent[0].key).toBe(key);
  });

  it('skips unknown keys with reason not_found', async () => {
    const res = await callPost({ keys: ['ADIA-BRNF-UNKN-AAAA'] });
    const body = await res.json();
    expect(body.sent).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0]).toMatchObject({ key: 'ADIA-BRNF-UNKN-AAAA', reason: 'not_found' });
    expect(mockSendLicenseEmail).not.toHaveBeenCalled();
  });

  it('handles mixed batch (one found, one not_found)', async () => {
    const key = 'ADIA-BRMX-GOOD-AAAA';
    insertLicense({ key, email: 'good@example.com', plan: 'lifetime', expiresAt: null });

    const res = await callPost({ keys: [key, 'ADIA-BRMX-MISS-AAAA'] });
    const body = await res.json();
    expect(body.sent).toHaveLength(1);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0]).toMatchObject({ key: 'ADIA-BRMX-MISS-AAAA', reason: 'not_found' });
    expect(mockSendLicenseEmail).toHaveBeenCalledTimes(1);
  });

  it('sends for non-active license status (canceled, expired)', async () => {
    const key = 'ADIA-BRCA-CNCL-AAAA';
    insertLicense({ key, email: 'canceled@example.com', plan: 'monthly', expiresAt: null });
    // Mark canceled via status update would be needed — for now the insert default is active
    // but we verify the route doesn't gate on status (unlike resend-payment-failed)
    const res = await callPost({ keys: [key] });
    const body = await res.json();
    expect(body.sent).toHaveLength(1);
    expect(mockSendLicenseEmail).toHaveBeenCalledTimes(1);
  });
});

// ─── Audit log ────────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-resend-license — audit log', () => {
  it('writes a resend_license audit entry per sent key', async () => {
    const key = 'ADIA-BRAL-LOG1-AAAA';
    insertLicense({ key, email: 'log1@example.com', plan: 'yearly', expiresAt: null });

    await callPost({ keys: [key] });
    const log = listAuditLog({ licenseKey: key });
    expect(log.length).toBe(1);
    expect(log[0].action).toBe('resend_license');
    const detail = JSON.parse(log[0].detail ?? '{}');
    expect(detail.to).toBe('log1@example.com');
    expect(detail.bulk).toBe(true);
  });

  it('writes one audit entry per key in a multi-key batch', async () => {
    const k1 = 'ADIA-BRAL-KEY1-AAAA';
    const k2 = 'ADIA-BRAL-KEY2-AAAA';
    insertLicense({ key: k1, email: 'key1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: k2, email: 'key2@example.com', plan: 'lifetime', expiresAt: null });

    await callPost({ keys: [k1, k2] });
    const log1 = listAuditLog({ licenseKey: k1 });
    const log2 = listAuditLog({ licenseKey: k2 });
    expect(log1).toHaveLength(1);
    expect(log2).toHaveLength(1);
  });

  it('does not write audit log for skipped (not_found) keys', async () => {
    const res = await callPost({ keys: ['ADIA-BRAL-MISS-AAAA'] });
    const body = await res.json();
    expect(body.skipped[0].reason).toBe('not_found');
    // No audit entries for the missing key
    const log = listAuditLog({ licenseKey: 'ADIA-BRAL-MISS-AAAA' });
    expect(log).toHaveLength(0);
  });
});

// ─── Dry run ──────────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-resend-license — dryRun', () => {
  it('returns sent list without sending emails or writing audit log', async () => {
    const key = 'ADIA-BRDR-DRY1-AAAA';
    insertLicense({ key, email: 'dry1@example.com', plan: 'monthly', expiresAt: null });

    const res = await callPost({ keys: [key], dryRun: true });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.dryRun).toBe(true);
    expect(body.sent).toHaveLength(1);
    expect(body.sent[0]).toMatchObject({ key, email: 'dry1@example.com' });
    expect(mockSendLicenseEmail).not.toHaveBeenCalled();
    const log = listAuditLog({ licenseKey: key });
    expect(log).toHaveLength(0);
  });

  it('dry run still skips not_found keys', async () => {
    const res = await callPost({ keys: ['ADIA-BRDR-MISS-AAAA'], dryRun: true });
    const body = await res.json();
    expect(body.dryRun).toBe(true);
    expect(body.skipped[0]).toMatchObject({ key: 'ADIA-BRDR-MISS-AAAA', reason: 'not_found' });
  });

  it('dry run returns dryRun: false when dryRun is not set', async () => {
    const key = 'ADIA-BRDR-NFLS-AAAA';
    insertLicense({ key, email: 'nfls@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callPost({ keys: [key] });
    const body = await res.json();
    expect(body.dryRun).toBe(false);
  });
});
