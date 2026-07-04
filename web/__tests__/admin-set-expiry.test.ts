// Tests for POST /api/admin/set-expiry
// Sets a license's expiresAt to an absolute date (or null for lifetime).

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, findLicense, listAuditLog } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(
    os.tmpdir(),
    `adia-set-expiry-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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

async function callSetExpiry(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/set-expiry/route');
  const req = new NextRequest('http://localhost/api/admin/set-expiry', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', ...authHeader(token) },
  });
  return POST(req);
}

// ─── POST /api/admin/set-expiry ───────────────────────────────────────────────

describe('POST /api/admin/set-expiry', () => {
  it('returns 401 when no token is provided', async () => {
    const res = await callSetExpiry({ key: 'ADIA-SEXP-AUTH-AAAA', expiresAt: '2025-12-31' }, 'wrong-token');
    expect(res.status).toBe(401);
    const body = await res.json();
    expect(body.error).toMatch(/unauthorized/i);
  });

  it('returns 401 when ADMIN_TOKEN env var is absent', async () => {
    delete process.env.ADMIN_TOKEN;
    const res = await callSetExpiry({ key: 'ADIA-SEXP-AUTH-BBBB', expiresAt: '2025-12-31' });
    expect(res.status).toBe(401);
  });

  it('returns 400 when key is missing from body', async () => {
    const res = await callSetExpiry({ expiresAt: '2025-12-31' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing key/i);
  });

  it('returns 400 when expiresAt field is absent entirely', async () => {
    const res = await callSetExpiry({ key: 'ADIA-SEXP-MISS-AAAA' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing expiresAt/i);
  });

  it('returns 400 when expiresAt is an invalid date string', async () => {
    insertLicense({ key: 'ADIA-SEXP-INVD-AAAA', email: 'inv@example.com', plan: 'monthly', expiresAt: null });
    const res = await callSetExpiry({ key: 'ADIA-SEXP-INVD-AAAA', expiresAt: 'not-a-date' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/ISO-8601/i);
  });

  it('returns 400 when expiresAt is a number (wrong type)', async () => {
    insertLicense({ key: 'ADIA-SEXP-TYPP-AAAA', email: 'typp@example.com', plan: 'monthly', expiresAt: null });
    const res = await callSetExpiry({ key: 'ADIA-SEXP-TYPP-AAAA', expiresAt: 12345 });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/ISO-8601/i);
  });

  it('returns 404 when key is unknown', async () => {
    const res = await callSetExpiry({ key: 'ADIA-SEXP-UNKN-ZZZZ', expiresAt: '2025-12-31' });
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body.error).toMatch(/unknown key/i);
  });

  it('returns 422 when expiresAt is already set to the same date', async () => {
    const isoDate = '2025-06-30T00:00:00.000Z';
    insertLicense({ key: 'ADIA-SEXP-NOOP-AAAA', email: 'noop@example.com', plan: 'monthly', expiresAt: isoDate });
    const res = await callSetExpiry({ key: 'ADIA-SEXP-NOOP-AAAA', expiresAt: isoDate });
    expect(res.status).toBe(422);
    const body = await res.json();
    expect(body.error).toMatch(/already set/i);
  });

  it('returns 422 when setting null on a license that is already lifetime (null)', async () => {
    insertLicense({ key: 'ADIA-SEXP-LIFE-AAAA', email: 'life@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callSetExpiry({ key: 'ADIA-SEXP-LIFE-AAAA', expiresAt: null });
    expect(res.status).toBe(422);
    const body = await res.json();
    expect(body.error).toMatch(/already set/i);
  });

  it('200 — sets expiresAt to a specific ISO date', async () => {
    insertLicense({ key: 'ADIA-SEXP-DATE-AAAA', email: 'date@example.com', plan: 'monthly', expiresAt: null });
    const res = await callSetExpiry({ key: 'ADIA-SEXP-DATE-AAAA', expiresAt: '2026-06-30' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.key).toBe('ADIA-SEXP-DATE-AAAA');
    expect(body.previousExpiresAt).toBeNull();
    expect(body.newExpiresAt).toBe(new Date('2026-06-30').toISOString());
  });

  it('200 — sets expiresAt to null (convert to lifetime)', async () => {
    insertLicense({
      key: 'ADIA-SEXP-NULLL-AAA',
      email: 'null@example.com',
      plan: 'monthly',
      expiresAt: '2025-12-31T00:00:00.000Z',
    });
    const res = await callSetExpiry({ key: 'ADIA-SEXP-NULLL-AAA', expiresAt: null });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.newExpiresAt).toBeNull();
    expect(body.previousExpiresAt).toBe('2025-12-31T00:00:00.000Z');
  });

  it('persists the new expiresAt to the database', async () => {
    insertLicense({ key: 'ADIA-SEXP-PERS-AAAA', email: 'pers@example.com', plan: 'yearly', expiresAt: null });
    await callSetExpiry({ key: 'ADIA-SEXP-PERS-AAAA', expiresAt: '2027-01-01' });
    const license = findLicense('ADIA-SEXP-PERS-AAAA');
    expect(license).not.toBeNull();
    expect(new Date(license!.expiresAt!).getFullYear()).toBe(2027);
  });

  it('persists null (lifetime) to the database', async () => {
    insertLicense({
      key: 'ADIA-SEXP-PNULL-AAA',
      email: 'pnull@example.com',
      plan: 'yearly',
      expiresAt: '2024-01-01T00:00:00.000Z',
    });
    await callSetExpiry({ key: 'ADIA-SEXP-PNULL-AAA', expiresAt: null });
    const license = findLicense('ADIA-SEXP-PNULL-AAA');
    expect(license!.expiresAt).toBeNull();
  });

  it('normalises key to uppercase', async () => {
    insertLicense({ key: 'ADIA-SEXP-CASE-AAAA', email: 'case@example.com', plan: 'monthly', expiresAt: null });
    const res = await callSetExpiry({ key: 'adia-sexp-case-aaaa', expiresAt: '2028-06-15' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.key).toBe('ADIA-SEXP-CASE-AAAA');
  });

  it('accepts ?token= query param as auth fallback', async () => {
    const { POST } = await import('@/app/api/admin/set-expiry/route');
    insertLicense({ key: 'ADIA-SEXP-TOKN-AAAA', email: 'tok@example.com', plan: 'monthly', expiresAt: null });
    const req = new NextRequest('http://localhost/api/admin/set-expiry?token=test-admin-token', {
      method: 'POST',
      body: JSON.stringify({ key: 'ADIA-SEXP-TOKN-AAAA', expiresAt: '2029-01-01' }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(200);
  });

  it('writes a set_expiry audit log entry on success', async () => {
    insertLicense({ key: 'ADIA-SEXP-AUDT-AAAA', email: 'audit@example.com', plan: 'yearly', expiresAt: null });
    await callSetExpiry({ key: 'ADIA-SEXP-AUDT-AAAA', expiresAt: '2030-12-31' });
    const entries = listAuditLog({ licenseKey: 'ADIA-SEXP-AUDT-AAAA' });
    expect(entries.length).toBe(1);
    expect(entries[0].action).toBe('set_expiry');
    const detail = JSON.parse(entries[0].detail ?? '{}');
    expect(detail.previousExpiresAt).toBeNull();
    expect(detail.newExpiresAt).toBe(new Date('2030-12-31').toISOString());
  });

  it('does not write audit entry when request fails (404)', async () => {
    const res = await callSetExpiry({ key: 'ADIA-SEXP-NLOG-ZZZZ', expiresAt: '2025-01-01' });
    expect(res.status).toBe(404);
    const entries = listAuditLog({ licenseKey: 'ADIA-SEXP-NLOG-ZZZZ' });
    expect(entries.length).toBe(0);
  });
});
