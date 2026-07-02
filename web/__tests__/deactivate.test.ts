import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, recordActivation, hasActivation, countActivations } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

beforeEach(() => {
  dbPath = path.join(os.tmpdir(), `adia-deactivate-${Date.now()}.db`);
  resetDbForTesting(dbPath);
  resetRateLimit();
});

afterEach(() => {
  resetDbForTesting();
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

async function callPost(body: unknown, ip = '127.0.0.1') {
  const { POST } = await import('@/app/api/license/deactivate/route');
  const req = new NextRequest('http://localhost/api/license/deactivate', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', 'x-forwarded-for': ip },
  });
  return POST(req);
}

describe('POST /api/license/deactivate', () => {
  it('returns 400 when key is missing', async () => {
    const res = await callPost({ email: 'user@example.com', machine: 'machine-1' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing/i);
  });

  it('returns 400 when email is missing', async () => {
    const res = await callPost({ key: 'ADIA-XXXX-XXXX-XXXX', machine: 'machine-1' });
    expect(res.status).toBe(400);
  });

  it('returns 400 when machine is missing', async () => {
    const res = await callPost({ key: 'ADIA-XXXX-XXXX-XXXX', email: 'user@example.com' });
    expect(res.status).toBe(400);
  });

  it('returns 404 for unknown key/email combination', async () => {
    const res = await callPost({
      key: 'ADIA-UNKN-UNKN-UNKN',
      email: 'ghost@example.com',
      machine: 'machine-1',
    });
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body.error).toMatch(/not found/i);
  });

  it('returns 404 when machine is not activated', async () => {
    const key = 'ADIA-DEAC-TEST-AAAA';
    insertLicense({ key, email: 'user@example.com', plan: 'lifetime', expiresAt: null });

    const res = await callPost({ key, email: 'user@example.com', machine: 'ghost-machine' });
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body.error).toMatch(/machine not found/i);
  });

  it('returns 200 and removes the machine on happy path', async () => {
    const key = 'ADIA-DEAC-HPPY-AAAA';
    insertLicense({ key, email: 'happy@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation(key, 'machine-1');
    recordActivation(key, 'machine-2');
    expect(countActivations(key)).toBe(2);

    const res = await callPost({ key, email: 'happy@example.com', machine: 'machine-1' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.key).toBe(key);
    expect(body.seatsNow).toBe(1);
    expect(hasActivation(key, 'machine-1')).toBe(false);
    expect(hasActivation(key, 'machine-2')).toBe(true);
  });

  it('freeing a seat allows a new machine to activate', async () => {
    const key = 'ADIA-DEAC-FREE-AAAA';
    insertLicense({ key, email: 'seat@example.com', plan: 'lifetime', expiresAt: null });
    for (let i = 1; i <= 3; i++) recordActivation(key, `machine-${i}`);
    expect(countActivations(key)).toBe(3);

    // Free machine-1
    const deacRes = await callPost({ key, email: 'seat@example.com', machine: 'machine-1' });
    expect(deacRes.status).toBe(200);
    expect(countActivations(key)).toBe(2);

    // machine-4 can now activate (seat freed)
    const { POST: activatePost } = await import('@/app/api/license/activate/route');
    const actReq = new NextRequest('http://localhost/api/license/activate', {
      method: 'POST',
      body: JSON.stringify({ key, email: 'seat@example.com', machine: 'machine-4' }),
      headers: { 'Content-Type': 'application/json' },
    });
    const actRes = await activatePost(actReq);
    expect(actRes.status).toBe(200);
    expect(countActivations(key)).toBe(3);
  });

  it('returns 429 after 10 requests from the same IP', async () => {
    for (let i = 0; i < 10; i++) {
      const r = await callPost({}, '10.1.0.1');
      expect(r.status).not.toBe(429);
    }
    const r = await callPost({}, '10.1.0.1');
    expect(r.status).toBe(429);
    const body = await r.json();
    expect(body.error).toBe('too many requests');
    expect(r.headers.get('Retry-After')).toBeTruthy();
  });

  it('rate limit is per-IP — a different IP is not blocked', async () => {
    for (let i = 0; i < 10; i++) {
      await callPost({}, '10.1.0.2');
    }
    const r = await callPost({}, '10.1.0.3');
    expect(r.status).not.toBe(429);
  });
});
