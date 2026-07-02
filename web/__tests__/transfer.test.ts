import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, findLicense, recordActivation } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

beforeEach(() => {
  dbPath = path.join(os.tmpdir(), `adia-transfer-${Date.now()}.db`);
  resetDbForTesting(dbPath);
  resetRateLimit();
});

afterEach(() => {
  resetDbForTesting();
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

async function callPost(body: unknown, ip = '127.0.0.1') {
  const { POST } = await import('@/app/api/license/transfer/route');
  const req = new NextRequest('http://localhost/api/license/transfer', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', 'x-forwarded-for': ip },
  });
  return POST(req);
}

describe('POST /api/license/transfer', () => {
  it('returns 400 when key is missing', async () => {
    const res = await callPost({ email: 'old@example.com', newEmail: 'new@example.com' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing/i);
  });

  it('returns 400 when email is missing', async () => {
    const res = await callPost({ key: 'ADIA-XXXX-XXXX-XXXX', newEmail: 'new@example.com' });
    expect(res.status).toBe(400);
  });

  it('returns 400 when newEmail is missing', async () => {
    const res = await callPost({ key: 'ADIA-XXXX-XXXX-XXXX', email: 'old@example.com' });
    expect(res.status).toBe(400);
  });

  it('returns 404 for unknown key/email combination', async () => {
    const res = await callPost({
      key: 'ADIA-UNKN-UNKN-UNKN',
      email: 'ghost@example.com',
      newEmail: 'new@example.com',
    });
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body.error).toMatch(/not found/i);
  });

  it('returns 422 when newEmail is the same as the current email', async () => {
    const key = 'ADIA-XFER-SAME-AAAA';
    insertLicense({ key, email: 'same@example.com', plan: 'lifetime', expiresAt: null });

    const res = await callPost({ key, email: 'same@example.com', newEmail: 'same@example.com' });
    expect(res.status).toBe(422);
    const body = await res.json();
    expect(body.error).toMatch(/same/i);
  });

  it('returns 422 for newEmail same as current after case normalization', async () => {
    const key = 'ADIA-XFER-CASE-AAAA';
    insertLicense({ key, email: 'user@example.com', plan: 'lifetime', expiresAt: null });

    const res = await callPost({ key, email: 'user@example.com', newEmail: 'USER@EXAMPLE.COM' });
    expect(res.status).toBe(422);
  });

  it('returns 200 and updates the email on happy path', async () => {
    const key = 'ADIA-XFER-HPPY-AAAA';
    insertLicense({ key, email: 'old@example.com', plan: 'lifetime', expiresAt: null });

    const res = await callPost({ key, email: 'old@example.com', newEmail: 'new@example.com' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.key).toBe(key);
    expect(body.email).toBe('new@example.com');
    expect(body.plan).toBe('lifetime');
  });

  it('DB reflects the new email after transfer', async () => {
    const key = 'ADIA-XFER-DBCK-AAAA';
    insertLicense({ key, email: 'original@example.com', plan: 'yearly', expiresAt: null });

    await callPost({ key, email: 'original@example.com', newEmail: 'transferred@example.com' });

    const license = findLicense(key);
    expect(license?.email).toBe('transferred@example.com');
  });

  it('old email no longer authenticates after transfer', async () => {
    const key = 'ADIA-XFER-AUTH-AAAA';
    insertLicense({ key, email: 'before@example.com', plan: 'lifetime', expiresAt: null });

    await callPost({ key, email: 'before@example.com', newEmail: 'after@example.com' });

    // findLicense with old email should return null
    const byOld = findLicense(key, 'before@example.com');
    expect(byOld).toBeNull();

    // findLicense with new email should succeed
    const byNew = findLicense(key, 'after@example.com');
    expect(byNew?.email).toBe('after@example.com');
  });

  it('new email can activate after transfer', async () => {
    const key = 'ADIA-XFER-ACTV-AAAA';
    insertLicense({ key, email: 'sender@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation(key, 'sender-machine');

    await callPost({ key, email: 'sender@example.com', newEmail: 'receiver@example.com' });

    // New owner should be able to activate their machine
    const { POST: activatePost } = await import('@/app/api/license/activate/route');
    const actReq = new NextRequest('http://localhost/api/license/activate', {
      method: 'POST',
      body: JSON.stringify({ key, email: 'receiver@example.com', machine: 'receiver-machine' }),
      headers: { 'Content-Type': 'application/json' },
    });
    const actRes = await activatePost(actReq);
    expect(actRes.status).toBe(200);
    const actBody = await actRes.json();
    expect(actBody.email).toBe('receiver@example.com');
  });

  it('newEmail is normalized to lowercase', async () => {
    const key = 'ADIA-XFER-LOWY-AAAA';
    insertLicense({ key, email: 'owner@example.com', plan: 'lifetime', expiresAt: null });

    const res = await callPost({ key, email: 'owner@example.com', newEmail: 'NEWOWNER@EXAMPLE.COM' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.email).toBe('newowner@example.com');
  });

  it('returns 429 after 5 requests from the same IP', async () => {
    for (let i = 0; i < 5; i++) {
      const r = await callPost({}, '10.2.0.1');
      expect(r.status).not.toBe(429);
    }
    const r = await callPost({}, '10.2.0.1');
    expect(r.status).toBe(429);
    const body = await r.json();
    expect(body.error).toBe('too many requests');
    expect(r.headers.get('Retry-After')).toBeTruthy();
  });

  it('rate limit is per-IP — a different IP is not blocked', async () => {
    for (let i = 0; i < 5; i++) {
      await callPost({}, '10.2.0.2');
    }
    const r = await callPost({}, '10.2.0.3');
    expect(r.status).not.toBe(429);
  });
});
