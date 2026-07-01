import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, recordActivation } from '@/lib/db';
import { planExpiry } from '@/lib/license';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

beforeEach(() => {
  dbPath = path.join(os.tmpdir(), `adia-validate-${Date.now()}.db`);
  resetDbForTesting(dbPath);
  resetRateLimit();
});

afterEach(() => {
  resetDbForTesting();
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

async function callPost(body: unknown) {
  const { POST } = await import('@/app/api/license/validate/route');
  const req = new NextRequest('http://localhost/api/license/validate', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json' },
  });
  return POST(req);
}

describe('POST /api/license/validate', () => {
  it('returns 400 when fields are missing', async () => {
    const res = await callPost({ key: 'ADIA-XXXX-XXXX-XXXX' });
    expect(res.status).toBe(400);
  });

  it('returns 400 when body is empty', async () => {
    const res = await callPost({});
    expect(res.status).toBe(400);
  });

  it('returns 404 for unknown key', async () => {
    const res = await callPost({ key: 'ADIA-UNKN-UNKN-UNKN', machine: 'machine-abc' });
    expect(res.status).toBe(404);
  });

  it('returns 403 for expired license', async () => {
    const key = 'ADIA-EXPR-VALI-AAAA';
    insertLicense({
      key,
      email: 'expired@example.com',
      plan: 'monthly',
      expiresAt: new Date(Date.now() - 86400 * 1000).toISOString(),
    });
    const res = await callPost({ key, machine: 'machine-1' });
    expect(res.status).toBe(403);
  });

  it('returns 403 for machine that was never activated (seat-bypass prevention)', async () => {
    const key = 'ADIA-NOVO-MACH-AAAA';
    insertLicense({ key, email: 'noact@example.com', plan: 'lifetime', expiresAt: null });
    // machine-new was never recorded via /activate — validate must reject it
    const res = await callPost({ key, machine: 'machine-new' });
    expect(res.status).toBe(403);
    const body = await res.json();
    expect(body.error).toMatch(/not activated/i);
  });

  it('returns 200 on valid license for a pre-activated machine', async () => {
    const key = 'ADIA-VALI-HPPY-AAAA';
    insertLicense({ key, email: 'valid@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation(key, 'machine-ok');

    const res = await callPost({ key, machine: 'machine-ok' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.key).toBe(key);
    expect(body.lastValidatedAt).toBeTruthy();
  });

  it('returns 200 for yearly license with future expiry (pre-activated machine)', async () => {
    const key = 'ADIA-YRLY-VALI-AAAA';
    insertLicense({ key, email: 'yearly@example.com', plan: 'yearly', expiresAt: planExpiry('yearly') });
    recordActivation(key, 'machine-yrly');

    const res = await callPost({ key, machine: 'machine-yrly' });
    expect(res.status).toBe(200);
  });
});
