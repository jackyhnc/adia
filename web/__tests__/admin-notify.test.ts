// Tests for POST /api/admin/notify
// Body: { key: string, subject: string, message: string }

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, listAuditLog } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

vi.mock('@/lib/email', () => ({
  sendCustomEmail: vi.fn().mockResolvedValue(undefined),
  sendLicenseEmail: vi.fn().mockResolvedValue(undefined),
  sendPaymentFailedEmail: vi.fn().mockResolvedValue(undefined),
}));

import { sendCustomEmail } from '@/lib/email';
const mockSendCustomEmail = vi.mocked(sendCustomEmail);

let dbPath: string;

beforeEach(() => {
  resetRateLimit();
  vi.clearAllMocks();
  dbPath = path.join(
    os.tmpdir(),
    `adia-notify-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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

async function callNotify(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/notify/route');
  const req = new NextRequest('http://localhost/api/admin/notify', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
  });
  return POST(req);
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('POST /api/admin/notify', () => {
  it('returns 401 with no token', async () => {
    const { POST } = await import('@/app/api/admin/notify/route');
    const req = new NextRequest('http://localhost/api/admin/notify', {
      method: 'POST',
      body: JSON.stringify({ key: 'ADIA-NTFY-AUTH-AAAA', subject: 'hi', message: 'hello' }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    insertLicense({ key: 'ADIA-NTFY-AUTH-BBBB', email: 'auth@example.com', plan: 'monthly', expiresAt: null });
    const res = await callNotify({ key: 'ADIA-NTFY-AUTH-BBBB', subject: 'hi', message: 'hello' }, 'bad-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query-param auth', async () => {
    const { POST } = await import('@/app/api/admin/notify/route');
    insertLicense({ key: 'ADIA-NTFY-AUTH-CCCC', email: 'qtok@example.com', plan: 'monthly', expiresAt: null });
    const req = new NextRequest(
      'http://localhost/api/admin/notify?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ key: 'ADIA-NTFY-AUTH-CCCC', subject: 'hi', message: 'hello' }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
  });

  // ─── Validation ───────────────────────────────────────────────────────────

  it('returns 400 when key is missing', async () => {
    const res = await callNotify({ subject: 'hi', message: 'hello' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/key/i);
  });

  it('returns 400 when subject is missing', async () => {
    insertLicense({ key: 'ADIA-NTFY-SUB-AAAA', email: 'sub@example.com', plan: 'monthly', expiresAt: null });
    const res = await callNotify({ key: 'ADIA-NTFY-SUB-AAAA', message: 'hello' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/subject/i);
  });

  it('returns 400 when message is missing', async () => {
    insertLicense({ key: 'ADIA-NTFY-MSG-AAAA', email: 'msg@example.com', plan: 'monthly', expiresAt: null });
    const res = await callNotify({ key: 'ADIA-NTFY-MSG-AAAA', subject: 'hi' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/message/i);
  });

  it('returns 400 when subject exceeds 200 characters', async () => {
    insertLicense({ key: 'ADIA-NTFY-SBL-AAAA', email: 'sbl@example.com', plan: 'monthly', expiresAt: null });
    const res = await callNotify({
      key: 'ADIA-NTFY-SBL-AAAA',
      subject: 'x'.repeat(201),
      message: 'hello',
    });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/subject.*long|200/i);
  });

  it('returns 400 when message exceeds 2000 characters', async () => {
    insertLicense({ key: 'ADIA-NTFY-MBL-AAAA', email: 'mbl@example.com', plan: 'monthly', expiresAt: null });
    const res = await callNotify({
      key: 'ADIA-NTFY-MBL-AAAA',
      subject: 'hi',
      message: 'x'.repeat(2001),
    });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/message.*long|2000/i);
  });

  it('returns 404 for unknown license key', async () => {
    const res = await callNotify({ key: 'ADIA-NTFY-NOF-ZZZZ', subject: 'hi', message: 'hello' });
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body.error).toMatch(/unknown/i);
  });

  // ─── Core behavior ────────────────────────────────────────────────────────

  it('returns 200 with ok, key, to, sentAt on success', async () => {
    insertLicense({ key: 'ADIA-NTFY-OK1-AAAA', email: 'ok@example.com', plan: 'monthly', expiresAt: null });
    const res = await callNotify({ key: 'ADIA-NTFY-OK1-AAAA', subject: 'Hello!', message: 'Just checking in.' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.key).toBe('ADIA-NTFY-OK1-AAAA');
    expect(body.to).toBe('ok@example.com');
    expect(body.sentAt).toBeTruthy();
  });

  it('calls sendCustomEmail with the license holder email, subject, and message', async () => {
    insertLicense({ key: 'ADIA-NTFY-EML-AAAA', email: 'notify@example.com', plan: 'yearly', expiresAt: null });
    await callNotify({
      key: 'ADIA-NTFY-EML-AAAA',
      subject: 'Important update',
      message: 'We need to tell you something.',
    });
    expect(mockSendCustomEmail).toHaveBeenCalledOnce();
    expect(mockSendCustomEmail).toHaveBeenCalledWith(
      'notify@example.com',
      'Important update',
      'We need to tell you something.',
    );
  });

  it('key is normalized to uppercase before lookup', async () => {
    insertLicense({ key: 'ADIA-NTFY-NRM-AAAA', email: 'norm@example.com', plan: 'monthly', expiresAt: null });
    const res = await callNotify({ key: 'adia-ntfy-nrm-aaaa', subject: 'hi', message: 'hello' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.key).toBe('ADIA-NTFY-NRM-AAAA');
    expect(body.to).toBe('norm@example.com');
  });

  it('subject at exactly 200 characters is accepted', async () => {
    insertLicense({ key: 'ADIA-NTFY-SBE-AAAA', email: 'sbe@example.com', plan: 'monthly', expiresAt: null });
    const res = await callNotify({
      key: 'ADIA-NTFY-SBE-AAAA',
      subject: 'x'.repeat(200),
      message: 'hello',
    });
    expect(res.status).toBe(200);
  });

  it('message at exactly 2000 characters is accepted', async () => {
    insertLicense({ key: 'ADIA-NTFY-MBE-AAAA', email: 'mbe@example.com', plan: 'monthly', expiresAt: null });
    const res = await callNotify({
      key: 'ADIA-NTFY-MBE-AAAA',
      subject: 'hi',
      message: 'x'.repeat(2000),
    });
    expect(res.status).toBe(200);
  });

  // ─── Audit log ────────────────────────────────────────────────────────────

  it('writes a notify audit log entry on success', async () => {
    insertLicense({ key: 'ADIA-NTFY-AUD-AAAA', email: 'audit@example.com', plan: 'monthly', expiresAt: null });
    await callNotify({ key: 'ADIA-NTFY-AUD-AAAA', subject: 'Check-in', message: 'How are you doing?' });
    const entries = listAuditLog({ licenseKey: 'ADIA-NTFY-AUD-AAAA' });
    expect(entries.length).toBe(1);
    expect(entries[0].action).toBe('notify');
  });

  it('audit log detail contains to address and subject', async () => {
    insertLicense({ key: 'ADIA-NTFY-ADE-AAAA', email: 'ade@example.com', plan: 'yearly', expiresAt: null });
    await callNotify({ key: 'ADIA-NTFY-ADE-AAAA', subject: 'My subject', message: 'My message' });
    const entries = listAuditLog({ licenseKey: 'ADIA-NTFY-ADE-AAAA' });
    const detail = JSON.parse(entries[0].detail ?? '{}');
    expect(detail.to).toBe('ade@example.com');
    expect(detail.subject).toBe('My subject');
  });

  it('does not write audit log entry when license is not found', async () => {
    await callNotify({ key: 'ADIA-NTFY-NAL-ZZZZ', subject: 'hi', message: 'hello' });
    const entries = listAuditLog({ licenseKey: 'ADIA-NTFY-NAL-ZZZZ' });
    expect(entries.length).toBe(0);
  });

  it('does not call sendCustomEmail when license is not found', async () => {
    await callNotify({ key: 'ADIA-NTFY-NEM-ZZZZ', subject: 'hi', message: 'hello' });
    expect(mockSendCustomEmail).not.toHaveBeenCalled();
  });

  // ─── Rate limit ───────────────────────────────────────────────────────────

  it('returns 429 after 10 requests from the same IP', async () => {
    insertLicense({ key: 'ADIA-NTFY-RL1-AAAA', email: 'rl@example.com', plan: 'monthly', expiresAt: null });
    for (let i = 0; i < 10; i++) {
      const res = await callNotify({ key: 'ADIA-NTFY-RL1-AAAA', subject: 'hi', message: 'msg' });
      expect(res.status).toBe(200);
    }
    const overLimit = await callNotify({ key: 'ADIA-NTFY-RL1-AAAA', subject: 'hi', message: 'msg' });
    expect(overLimit.status).toBe(429);
  });

  it('429 response includes Retry-After header', async () => {
    insertLicense({ key: 'ADIA-NTFY-RL2-AAAA', email: 'rl2@example.com', plan: 'monthly', expiresAt: null });
    for (let i = 0; i < 10; i++) {
      await callNotify({ key: 'ADIA-NTFY-RL2-AAAA', subject: 'hi', message: 'msg' });
    }
    const res = await callNotify({ key: 'ADIA-NTFY-RL2-AAAA', subject: 'hi', message: 'msg' });
    expect(res.status).toBe(429);
    expect(res.headers.get('retry-after')).toBeTruthy();
  });
});
