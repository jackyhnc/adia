// Tests for POST /api/admin/deactivate-all
// Admin-only endpoint. Removes ALL machine activations for a license key.
// Auth: ADMIN_TOKEN bearer header or ?token= query param.

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, recordActivation, countActivations, listActivations } from '@/lib/db';

let dbPath: string;

beforeEach(() => {
  dbPath = path.join(
    os.tmpdir(),
    `adia-deactivate-all-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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
  const { POST } = await import('@/app/api/admin/deactivate-all/route');
  const req = new NextRequest('http://localhost/api/admin/deactivate-all', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', ...authHeader(token) },
  });
  return POST(req);
}

describe('POST /api/admin/deactivate-all', () => {
  it('returns 401 with no authorization header', async () => {
    const { POST } = await import('@/app/api/admin/deactivate-all/route');
    const req = new NextRequest('http://localhost/api/admin/deactivate-all', {
      method: 'POST',
      body: JSON.stringify({ key: 'ADIA-XXXX-XXXX-XXXX' }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callPost({ key: 'ADIA-XXXX-XXXX-XXXX' }, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('returns 400 when key is missing from body', async () => {
    const res = await callPost({});
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing key/i);
  });

  it('returns 400 when body is not valid JSON', async () => {
    const { POST } = await import('@/app/api/admin/deactivate-all/route');
    const req = new NextRequest('http://localhost/api/admin/deactivate-all', {
      method: 'POST',
      body: 'not-json',
      headers: { 'Content-Type': 'application/json', ...authHeader() },
    });
    const res = await POST(req);
    expect(res.status).toBe(400);
  });

  it('returns 404 for unknown key', async () => {
    const res = await callPost({ key: 'ADIA-UNKN-UNKN-UNKN' });
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body.error).toMatch(/unknown key/i);
  });

  it('removes all activations and returns removed count', async () => {
    const key = 'ADIA-DALL-HPPY-AAAA';
    insertLicense({ key, email: 'all@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation(key, 'machine-1');
    recordActivation(key, 'machine-2');
    recordActivation(key, 'machine-3');
    expect(countActivations(key)).toBe(3);

    const res = await callPost({ key });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.key).toBe(key);
    expect(body.removedCount).toBe(3);
    expect(countActivations(key)).toBe(0);
  });

  it('returns removedCount 0 for a key with no activations (idempotent)', async () => {
    const key = 'ADIA-DALL-NOAC-AAAA';
    insertLicense({ key, email: 'noact@example.com', plan: 'monthly', expiresAt: null });

    const res = await callPost({ key });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.removedCount).toBe(0);
  });

  it('calling twice is idempotent — second call removes 0', async () => {
    const key = 'ADIA-DALL-IDMP-AAAA';
    insertLicense({ key, email: 'idempotent@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation(key, 'machine-x');

    const res1 = await callPost({ key });
    expect((await res1.json()).removedCount).toBe(1);

    const res2 = await callPost({ key });
    expect(res2.status).toBe(200);
    expect((await res2.json()).removedCount).toBe(0);
  });

  it('normalizes key to uppercase before lookup', async () => {
    const key = 'ADIA-DALL-CASE-AAAA';
    insertLicense({ key, email: 'casetest@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation(key, 'machine-1');

    const res = await callPost({ key: 'adia-dall-case-aaaa' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.key).toBe('ADIA-DALL-CASE-AAAA');
    expect(body.removedCount).toBe(1);
  });

  it('only removes activations for the specified key — other keys are unaffected', async () => {
    const keyA = 'ADIA-DALL-ISOL-AAAA';
    const keyB = 'ADIA-DALL-ISOL-BBBB';
    insertLicense({ key: keyA, email: 'a@example.com', plan: 'lifetime', expiresAt: null });
    insertLicense({ key: keyB, email: 'b@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation(keyA, 'machine-a1');
    recordActivation(keyA, 'machine-a2');
    recordActivation(keyB, 'machine-b1');

    const res = await callPost({ key: keyA });
    expect(res.status).toBe(200);
    expect((await res.json()).removedCount).toBe(2);

    // keyB activations are untouched
    expect(countActivations(keyB)).toBe(1);
    const bActivations = listActivations(keyB);
    expect(bActivations[0].machineHash).toBe('machine-b1');
  });

  it('accepts ?token= query param as auth fallback', async () => {
    const key = 'ADIA-DALL-TOKN-AAAA';
    insertLicense({ key, email: 'tokauth@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation(key, 'machine-tok');

    const { POST } = await import('@/app/api/admin/deactivate-all/route');
    const req = new NextRequest(
      'http://localhost/api/admin/deactivate-all?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ key }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.removedCount).toBe(1);
  });
});
