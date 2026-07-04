// Tests for web/lib/admin.ts adminGuard helper and rate-limiting on admin routes.
//
// Verifies:
// 1. adminGuard returns null (allow) for a valid token
// 2. adminGuard returns 429 after 20 requests from the same IP
// 3. Rate limits are keyed per route — exhausting one route does not block others
// 4. Rate limit is per IP — a different IP gets its own bucket
// 5. adminGuard returns 401 when ADMIN_TOKEN is unset
// 6. adminGuard returns 401 for a wrong token
// 7. Bearer and ?token= auth both work
// 8. Spot-checks on stats + revoke routes (newly rate-limited) to confirm 429 fires

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { adminGuard } from '@/lib/admin';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';
import { resetDbForTesting, insertLicense } from '@/lib/db';

let dbPath: string;

beforeEach(() => {
  dbPath = path.join(
    os.tmpdir(),
    `adia-admin-guard-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
  );
  resetDbForTesting(dbPath);
  resetRateLimit();
  process.env.ADMIN_TOKEN = 'test-admin-token';
});

afterEach(() => {
  resetDbForTesting();
  delete process.env.ADMIN_TOKEN;
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

function makeReq(
  route: string,
  opts: {
    ip?: string;
    token?: string | null;
    useQueryParam?: boolean;
  } = {},
) {
  const ip = opts.ip ?? '10.0.0.1';
  const url = opts.useQueryParam
    ? `http://localhost/api/admin/${route}?token=${opts.token ?? 'test-admin-token'}`
    : `http://localhost/api/admin/${route}`;
  const headers: Record<string, string> = { 'x-forwarded-for': ip };
  if (!opts.useQueryParam && opts.token !== null) {
    headers['Authorization'] = `Bearer ${opts.token ?? 'test-admin-token'}`;
  }
  return new NextRequest(url, { method: 'GET', headers });
}

// ─── adminGuard unit tests ─────────────────────────────────────────────────────

describe('adminGuard', () => {
  it('returns null (allow) for a valid bearer token', () => {
    const res = adminGuard(makeReq('stats'), 'stats');
    expect(res).toBeNull();
  });

  it('returns null for a valid ?token= query param', () => {
    const res = adminGuard(makeReq('stats', { useQueryParam: true }), 'stats');
    expect(res).toBeNull();
  });

  it('returns 401 when ADMIN_TOKEN env var is unset', () => {
    delete process.env.ADMIN_TOKEN;
    const res = adminGuard(makeReq('stats', { token: 'anything' }), 'stats');
    expect(res).not.toBeNull();
    expect(res!.status).toBe(401);
  });

  it('returns 401 for a wrong bearer token', () => {
    const res = adminGuard(makeReq('stats', { token: 'wrong-token' }), 'stats');
    expect(res).not.toBeNull();
    expect(res!.status).toBe(401);
  });

  it('returns 429 after 20 requests from the same IP', () => {
    for (let i = 0; i < 20; i++) {
      const res = adminGuard(makeReq('stats'), 'stats');
      expect(res).toBeNull();
    }
    const res = adminGuard(makeReq('stats'), 'stats');
    expect(res).not.toBeNull();
    expect(res!.status).toBe(429);
  });

  it('429 includes a Retry-After header', async () => {
    for (let i = 0; i < 20; i++) adminGuard(makeReq('stats'), 'stats');
    const res = adminGuard(makeReq('stats'), 'stats')!;
    const body = await res.json();
    expect(body.error).toMatch(/too many requests/i);
    expect(res.headers.get('Retry-After')).toBeTruthy();
  });

  it('rate limit is keyed per route — exhausting stats does not block revoke', () => {
    for (let i = 0; i < 20; i++) adminGuard(makeReq('stats'), 'stats');
    const blocked = adminGuard(makeReq('stats'), 'stats');
    expect(blocked).not.toBeNull();
    expect(blocked!.status).toBe(429);

    // revoke has its own bucket — same IP is still allowed
    const allowed = adminGuard(makeReq('revoke'), 'revoke');
    expect(allowed).toBeNull();
  });

  it('rate limit is keyed per IP — a different IP has its own bucket', () => {
    for (let i = 0; i < 20; i++) adminGuard(makeReq('stats', { ip: '10.0.0.2' }), 'stats');
    const blocked = adminGuard(makeReq('stats', { ip: '10.0.0.2' }), 'stats');
    expect(blocked!.status).toBe(429);

    const allowed = adminGuard(makeReq('stats', { ip: '10.0.0.3' }), 'stats');
    expect(allowed).toBeNull();
  });

  it('rate limit fires before auth check — wrong token still gets 429 when bucket exhausted', () => {
    for (let i = 0; i < 20; i++) adminGuard(makeReq('stats'), 'stats');
    const res = adminGuard(makeReq('stats', { token: 'bad-token' }), 'stats');
    expect(res).not.toBeNull();
    expect(res!.status).toBe(429);
  });
});

// ─── Spot-checks on newly rate-limited routes ──────────────────────────────────

describe('POST /api/admin/revoke — rate limit', () => {
  it('returns 429 after 20 requests from the same IP', async () => {
    insertLicense({ key: 'ADIA-RLRV-GRDT-AAAA', email: 'rl-revoke@example.com', plan: 'lifetime', expiresAt: null });

    const { POST } = await import('@/app/api/admin/revoke/route');
    const makeRevokeReq = () =>
      new NextRequest('http://localhost/api/admin/revoke', {
        method: 'POST',
        body: JSON.stringify({ key: 'ADIA-RLRV-GRDT-AAAA' }),
        headers: {
          'Content-Type': 'application/json',
          Authorization: 'Bearer test-admin-token',
          'x-forwarded-for': '10.1.0.1',
        },
      });

    for (let i = 0; i < 20; i++) {
      const res = await POST(makeRevokeReq());
      expect(res.status).toBe(200);
    }

    const res = await POST(makeRevokeReq());
    expect(res.status).toBe(429);
    const body = await res.json();
    expect(body.error).toMatch(/too many requests/i);
  });
});

describe('GET /api/admin/stats — rate limit', () => {
  it('returns 429 after 20 requests from the same IP', async () => {
    const { GET } = await import('@/app/api/admin/stats/route');
    const makeStatsReq = () =>
      new NextRequest('http://localhost/api/admin/stats', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer test-admin-token',
          'x-forwarded-for': '10.2.0.1',
        },
      });

    for (let i = 0; i < 20; i++) {
      const res = await GET(makeStatsReq());
      expect(res.status).toBe(200);
    }

    const res = await GET(makeStatsReq());
    expect(res.status).toBe(429);
  });
});

describe('GET /api/admin/lookup — rate limit', () => {
  it('returns 429 after 20 requests from the same IP', async () => {
    insertLicense({ key: 'ADIA-RLLK-GRDT-AAAA', email: 'rl-lookup@example.com', plan: 'yearly', expiresAt: null });

    const { GET } = await import('@/app/api/admin/lookup/route');
    const makeLookupReq = () =>
      new NextRequest('http://localhost/api/admin/lookup?key=ADIA-RLLK-GRDT-AAAA', {
        method: 'GET',
        headers: {
          Authorization: 'Bearer test-admin-token',
          'x-forwarded-for': '10.3.0.1',
        },
      });

    for (let i = 0; i < 20; i++) {
      const res = await GET(makeLookupReq());
      expect(res.status).toBe(200);
    }

    const res = await GET(makeLookupReq());
    expect(res.status).toBe(429);
  });
});
