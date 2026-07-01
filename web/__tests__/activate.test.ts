import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, countActivations, hasActivation } from '@/lib/db';
import { planExpiry } from '@/lib/license';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

beforeEach(() => {
  dbPath = path.join(os.tmpdir(), `adia-activate-${Date.now()}.db`);
  resetDbForTesting(dbPath);
  resetRateLimit();
});

afterEach(() => {
  resetDbForTesting();
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

async function callPost(body: unknown) {
  const { POST } = await import('@/app/api/license/activate/route');
  const req = new NextRequest('http://localhost/api/license/activate', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json' },
  });
  return POST(req);
}

async function callPostFromIp(body: unknown, ip: string) {
  const { POST } = await import('@/app/api/license/activate/route');
  const req = new NextRequest('http://localhost/api/license/activate', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', 'x-forwarded-for': ip },
  });
  return POST(req);
}

describe('POST /api/license/activate', () => {
  it('returns 400 when fields are missing', async () => {
    const res = await callPost({ key: 'ADIA-XXXX-XXXX-XXXX' });
    expect(res.status).toBe(400);
  });

  it('returns 400 when all fields missing', async () => {
    const res = await callPost({});
    expect(res.status).toBe(400);
  });

  it('returns 404 for unknown key/email combination', async () => {
    const res = await callPost({
      key: 'ADIA-UNKN-UNKN-UNKN',
      email: 'ghost@example.com',
      machine: 'machine-abc',
    });
    expect(res.status).toBe(404);
  });

  it('returns 403 for expired license', async () => {
    const key = 'ADIA-EXPR-ACTV-AAAA';
    insertLicense({
      key,
      email: 'expired@example.com',
      plan: 'monthly',
      expiresAt: new Date(Date.now() - 86400 * 1000).toISOString(),
    });

    const res = await callPost({ key, email: 'expired@example.com', machine: 'machine-1' });
    expect(res.status).toBe(403);
    const body = await res.json();
    expect(body.error).toMatch(/expired/i);
  });

  it('returns 403 when max seats exceeded', async () => {
    const key = 'ADIA-SEAT-ACTV-AAAA';
    insertLicense({ key, email: 'multi@example.com', plan: 'lifetime', expiresAt: null });

    for (let i = 1; i <= 3; i++) {
      await callPost({ key, email: 'multi@example.com', machine: `machine-${i}` });
    }

    const res = await callPost({ key, email: 'multi@example.com', machine: 'machine-4' });
    expect(res.status).toBe(403);
    const body = await res.json();
    expect(body.error).toMatch(/3 machines/i);
  });

  it('does not persist a rejected machine (no phantom DB rows)', async () => {
    const key = 'ADIA-PHTM-ACTV-AAAA';
    insertLicense({ key, email: 'phantom@example.com', plan: 'lifetime', expiresAt: null });

    for (let i = 1; i <= 3; i++) {
      await callPost({ key, email: 'phantom@example.com', machine: `machine-${i}` });
    }
    expect(countActivations(key)).toBe(3);

    const res = await callPost({ key, email: 'phantom@example.com', machine: 'machine-4' });
    expect(res.status).toBe(403);

    // machine-4 must NOT be in the activations table
    expect(countActivations(key)).toBe(3);
    expect(hasActivation(key, 'machine-4')).toBe(false);
  });

  it('allows re-activation of a known machine even when seats are full', async () => {
    const key = 'ADIA-REAC-ACTV-AAAA';
    insertLicense({ key, email: 'reactivate@example.com', plan: 'lifetime', expiresAt: null });

    for (let i = 1; i <= 3; i++) {
      await callPost({ key, email: 'reactivate@example.com', machine: `machine-${i}` });
    }
    expect(countActivations(key)).toBe(3);

    // machine-1 re-activating (e.g. app relaunch) must succeed without consuming a new seat
    const res = await callPost({ key, email: 'reactivate@example.com', machine: 'machine-1' });
    expect(res.status).toBe(200);
    expect(countActivations(key)).toBe(3);
  });

  it('returns 200 on happy path', async () => {
    const key = 'ADIA-HPPY-ACTV-AAAA';
    insertLicense({ key, email: 'happy@example.com', plan: 'yearly', expiresAt: planExpiry('yearly') });

    const res = await callPost({ key, email: 'happy@example.com', machine: 'machine-ok' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.key).toBe(key);
    expect(body.email).toBe('happy@example.com');
    expect(body.lastValidatedAt).toBeTruthy();
  });

  // Rate-limit integration: 20 req/min per IP. Pass empty bodies so we return 400
  // before any DB access — the rate limiter fires before body parsing.
  it('returns 429 after 20 requests from the same IP', async () => {
    for (let i = 0; i < 20; i++) {
      const r = await callPostFromIp({}, '10.0.0.1');
      expect(r.status).not.toBe(429);
    }
    const r = await callPostFromIp({}, '10.0.0.1');
    expect(r.status).toBe(429);
    const body = await r.json();
    expect(body.error).toBe('too many requests');
    expect(r.headers.get('Retry-After')).toBeTruthy();
  });

  it('rate limit is per-IP — a different IP is not blocked', async () => {
    for (let i = 0; i < 20; i++) {
      await callPostFromIp({}, '10.0.0.2');
    }
    // 10.0.0.2 bucket exhausted; 10.0.0.3 starts fresh
    const r = await callPostFromIp({}, '10.0.0.3');
    expect(r.status).not.toBe(429);
  });
});
