// Tests for POST /api/license/resend — self-service license key resend.

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

vi.mock('@/lib/email', () => ({
  sendLicenseEmail: vi.fn().mockResolvedValue(undefined),
  sendPaymentFailedEmail: vi.fn().mockResolvedValue(undefined),
  sendLicenseResendEmail: vi.fn().mockResolvedValue(undefined),
}));

import { sendLicenseResendEmail } from '@/lib/email';
const mockSendResend = vi.mocked(sendLicenseResendEmail);

let dbPath: string;

beforeEach(() => {
  dbPath = path.join(
    os.tmpdir(),
    `adia-resend-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
  );
  resetDbForTesting(dbPath);
  resetRateLimit();
  mockSendResend.mockReset();
  mockSendResend.mockResolvedValue(undefined);
});

afterEach(() => {
  resetDbForTesting();
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

async function callResend(body: unknown, ip = '1.2.3.4') {
  const { POST } = await import('@/app/api/license/resend/route');
  const req = new NextRequest('http://localhost/api/license/resend', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', 'x-forwarded-for': ip },
  });
  return POST(req);
}

describe('POST /api/license/resend', () => {
  it('returns 400 for missing email', async () => {
    const res = await callResend({});
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/invalid email/i);
  });

  it('returns 400 for malformed email', async () => {
    const res = await callResend({ email: 'not-an-email' });
    expect(res.status).toBe(400);
  });

  it('returns ok=true even when email has no licenses (anti-enumeration)', async () => {
    const res = await callResend({ email: 'nobody@example.com' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(mockSendResend).not.toHaveBeenCalled();
  });

  it('sends email and returns ok=true when licenses exist', async () => {
    insertLicense({
      key: 'ADIA-AAAA-BBBB-CCCC',
      email: 'user@example.com',
      plan: 'monthly',
      expiresAt: null,
    });

    const res = await callResend({ email: 'user@example.com' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);

    expect(mockSendResend).toHaveBeenCalledOnce();
    const [to, licenses] = mockSendResend.mock.calls[0]!;
    expect(to).toBe('user@example.com');
    expect(licenses).toHaveLength(1);
    expect(licenses[0]!.key).toBe('ADIA-AAAA-BBBB-CCCC');
  });

  it('sends all licenses when the email has multiple', async () => {
    insertLicense({ key: 'ADIA-AAAA-BBBB-CCQ1', email: 'multi@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-AAAA-BBBB-CCQ2', email: 'multi@example.com', plan: 'yearly',  expiresAt: null });

    const res = await callResend({ email: 'multi@example.com' });
    expect(res.status).toBe(200);
    expect(mockSendResend).toHaveBeenCalledOnce();
    const [, licenses] = mockSendResend.mock.calls[0]!;
    expect(licenses).toHaveLength(2);
  });

  it('normalises email to lowercase before lookup', async () => {
    insertLicense({ key: 'ADIA-CASE-NORM-AAAA', email: 'user@example.com', plan: 'lifetime', expiresAt: null });

    const res = await callResend({ email: 'USER@EXAMPLE.COM' });
    expect(res.status).toBe(200);
    expect(mockSendResend).toHaveBeenCalledOnce();
    const [to] = mockSendResend.mock.calls[0]!;
    expect(to).toBe('user@example.com');
  });

  it('returns 429 after 3 requests from the same IP', async () => {
    const ip = '9.9.9.9';
    await callResend({ email: 'a@example.com' }, ip);
    await callResend({ email: 'a@example.com' }, ip);
    await callResend({ email: 'a@example.com' }, ip);
    const res = await callResend({ email: 'a@example.com' }, ip);
    expect(res.status).toBe(429);
    const body = await res.json();
    expect(body.error).toMatch(/too many/i);
  });

  it('different IPs do not share rate-limit buckets', async () => {
    for (let i = 0; i < 3; i++) await callResend({ email: 'x@example.com' }, '10.0.0.1');
    const res = await callResend({ email: 'x@example.com' }, '10.0.0.2');
    expect(res.status).toBe(200);
  });
});
