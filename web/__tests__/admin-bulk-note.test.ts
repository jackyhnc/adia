// Tests for POST /api/admin/bulk-note
// Body: { keys: string[], note?: string | null, mode?: 'set' | 'append' | 'clear' }

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, getNote, listAuditLog } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(
    os.tmpdir(),
    `adia-bulk-note-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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
  const { POST } = await import('@/app/api/admin/bulk-note/route');
  const req = new NextRequest('http://localhost/api/admin/bulk-note', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', ...authHeader(token) },
  });
  return POST(req);
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-note — auth', () => {
  it('returns 401 with no authorization header', async () => {
    const { POST } = await import('@/app/api/admin/bulk-note/route');
    const req = new NextRequest('http://localhost/api/admin/bulk-note', {
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
    const key = 'ADIA-BNTK-TOKN-AAAA';
    insertLicense({ key, email: 'tok@example.com', plan: 'lifetime', expiresAt: null });
    const { POST } = await import('@/app/api/admin/bulk-note/route');
    const req = new NextRequest(
      'http://localhost/api/admin/bulk-note?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ keys: [key], note: 'token-auth' }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
    expect((await res.json()).ok).toBe(true);
  });
});

// ─── Validation ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-note — validation', () => {
  it('returns 400 when keys is missing', async () => {
    const res = await callPost({ note: 'hello' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing or empty keys/i);
  });

  it('returns 400 when keys is an empty array', async () => {
    const res = await callPost({ keys: [] });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/missing or empty keys/i);
  });

  it('returns 400 when keys exceeds 100', async () => {
    const keys = Array.from({ length: 101 }, (_, i) => `ADIA-BULK-${String(i).padStart(4, '0')}-AAAA`);
    const res = await callPost({ keys, note: 'x' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/too many keys/i);
  });

  it('returns 400 for invalid mode', async () => {
    const key = 'ADIA-BNMD-INVL-AAAA';
    insertLicense({ key, email: 'mode@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callPost({ keys: [key], mode: 'upsert', note: 'x' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/invalid mode/i);
  });
});

// ─── Mode: set (default) ──────────────────────────────────────────────────────

describe('POST /api/admin/bulk-note — mode: set', () => {
  it('sets a note and returns changed entry', async () => {
    const key = 'ADIA-BNST-SET1-AAAA';
    insertLicense({ key, email: 'set1@example.com', plan: 'lifetime', expiresAt: null });

    const res = await callPost({ keys: [key], note: 'Beta tester' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0]).toMatchObject({ key, previousNote: null, newNote: 'Beta tester' });
    expect(body.skipped).toHaveLength(0);
    expect(getNote(key)).toBe('Beta tester');
  });

  it('skips unknown keys with reason not_found', async () => {
    const res = await callPost({ keys: ['ADIA-BNNF-UNKN-AAAA'], note: 'x' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0]).toMatchObject({ key: 'ADIA-BNNF-UNKN-AAAA', reason: 'not_found' });
  });

  it('skips key when note is already equal (already_set)', async () => {
    const key = 'ADIA-BNAS-SAME-AAAA';
    insertLicense({ key, email: 'same@example.com', plan: 'monthly', expiresAt: null });
    await callPost({ keys: [key], note: 'no change' });

    const res = await callPost({ keys: [key], note: 'no change' });
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped[0]).toMatchObject({ key, reason: 'already_set' });
  });

  it('clears note when empty string is provided', async () => {
    const key = 'ADIA-BNCE-CLR1-AAAA';
    insertLicense({ key, email: 'clr1@example.com', plan: 'yearly', expiresAt: null });
    await callPost({ keys: [key], note: 'to be cleared' });

    const res = await callPost({ keys: [key], note: '' });
    const body = await res.json();
    expect(body.changed[0]).toMatchObject({ key, previousNote: 'to be cleared', newNote: null });
    expect(getNote(key)).toBeNull();
  });

  it('clears note when note field is omitted', async () => {
    const key = 'ADIA-BNCO-CLR2-AAAA';
    insertLicense({ key, email: 'clr2@example.com', plan: 'lifetime', expiresAt: null });
    await callPost({ keys: [key], note: 'will be gone' });

    const res = await callPost({ keys: [key] });
    const body = await res.json();
    expect(body.changed[0].newNote).toBeNull();
    expect(getNote(key)).toBeNull();
  });

  it('handles multiple keys in one request with mixed outcomes', async () => {
    const k1 = 'ADIA-BNMK-KEY1-AAAA';
    const k2 = 'ADIA-BNMK-KEY2-AAAA';
    const k3 = 'ADIA-BNMK-UNKN-AAAA';
    insertLicense({ key: k1, email: 'k1@example.com', plan: 'lifetime', expiresAt: null });
    insertLicense({ key: k2, email: 'k2@example.com', plan: 'monthly', expiresAt: null });

    const res = await callPost({ keys: [k1, k2, k3], note: 'batch' });
    const body = await res.json();
    expect(body.changed).toHaveLength(2);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0]).toMatchObject({ key: k3, reason: 'not_found' });
    expect(getNote(k1)).toBe('batch');
    expect(getNote(k2)).toBe('batch');
  });

  it('normalizes keys to uppercase', async () => {
    const key = 'ADIA-BNUC-CASE-AAAA';
    insertLicense({ key, email: 'case@example.com', plan: 'lifetime', expiresAt: null });

    const res = await callPost({ keys: ['adia-bnuc-case-aaaa'], note: 'case ok' });
    const body = await res.json();
    expect(body.changed[0].key).toBe(key);
    expect(getNote(key)).toBe('case ok');
  });
});

// ─── Mode: append ─────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-note — mode: append', () => {
  it('appends to an existing note with " | " separator', async () => {
    const key = 'ADIA-BNAP-APP1-AAAA';
    insertLicense({ key, email: 'app1@example.com', plan: 'lifetime', expiresAt: null });
    await callPost({ keys: [key], note: 'first' });

    const res = await callPost({ keys: [key], note: 'second', mode: 'append' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed[0]).toMatchObject({ key, previousNote: 'first', newNote: 'first | second' });
    expect(getNote(key)).toBe('first | second');
  });

  it('creates note when no existing note (acts like set)', async () => {
    const key = 'ADIA-BNAP-NEW1-AAAA';
    insertLicense({ key, email: 'new1@example.com', plan: 'monthly', expiresAt: null });

    const res = await callPost({ keys: [key], note: 'first entry', mode: 'append' });
    const body = await res.json();
    expect(body.changed[0].newNote).toBe('first entry');
    expect(getNote(key)).toBe('first entry');
  });

  it('skips (already_set) when note to append is empty', async () => {
    const key = 'ADIA-BNAP-SKP1-AAAA';
    insertLicense({ key, email: 'skp1@example.com', plan: 'yearly', expiresAt: null });
    await callPost({ keys: [key], note: 'existing' });

    const res = await callPost({ keys: [key], note: '', mode: 'append' });
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped[0]).toMatchObject({ key, reason: 'already_set' });
    expect(getNote(key)).toBe('existing');
  });
});

// ─── Mode: clear ──────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-note — mode: clear', () => {
  it('clears the note regardless of the note field', async () => {
    const key = 'ADIA-BNCL-CLR1-AAAA';
    insertLicense({ key, email: 'clrm@example.com', plan: 'lifetime', expiresAt: null });
    await callPost({ keys: [key], note: 'will be erased' });

    const res = await callPost({ keys: [key], mode: 'clear', note: 'ignored' });
    const body = await res.json();
    expect(body.changed[0]).toMatchObject({ key, previousNote: 'will be erased', newNote: null });
    expect(getNote(key)).toBeNull();
  });

  it('skips (already_set) when note is already null', async () => {
    const key = 'ADIA-BNCL-NUL1-AAAA';
    insertLicense({ key, email: 'nul1@example.com', plan: 'monthly', expiresAt: null });

    const res = await callPost({ keys: [key], mode: 'clear' });
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped[0]).toMatchObject({ key, reason: 'already_set' });
  });
});

// ─── Audit log ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-note — audit log', () => {
  it('writes one bulk_note audit entry per changed key', async () => {
    const k1 = 'ADIA-BNAL-LOG1-AAAA';
    const k2 = 'ADIA-BNAL-LOG2-AAAA';
    insertLicense({ key: k1, email: 'log1@example.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: k2, email: 'log2@example.com', plan: 'yearly', expiresAt: null });

    await callPost({ keys: [k1, k2], note: 'hello', mode: 'set' });

    for (const key of [k1, k2]) {
      const logs = listAuditLog({ licenseKey: key });
      expect(logs).toHaveLength(1);
      expect(logs[0].action).toBe('bulk_note');
    }
  });

  it('audit log detail contains mode, previousNote, newNote, and bulk=true', async () => {
    const key = 'ADIA-BNAL-DET1-AAAA';
    insertLicense({ key, email: 'det1@example.com', plan: 'lifetime', expiresAt: null });

    await callPost({ keys: [key], note: 'my note', mode: 'set' });

    const logs = listAuditLog({ licenseKey: key });
    const detail = typeof logs[0].detail === 'string' ? JSON.parse(logs[0].detail) : logs[0].detail;
    expect(detail).toMatchObject({
      mode: 'set',
      previousNote: null,
      newNote: 'my note',
      bulk: true,
    });
  });

  it('does not write audit log for skipped keys', async () => {
    const key = 'ADIA-BNAL-SKP1-AAAA';
    insertLicense({ key, email: 'skp1@example.com', plan: 'monthly', expiresAt: null });
    await callPost({ keys: [key], note: 'existing' });

    // Second call with same note → already_set → skipped; not_found key also skipped
    await callPost({ keys: [key, 'ADIA-BNAL-NOTFOUND'], note: 'existing' });

    // Only one audit entry (from the first call)
    const logs = listAuditLog({ licenseKey: key });
    expect(logs).toHaveLength(1);
  });
});

// ─── Rate limit ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-note — rate limit', () => {
  it('returns 429 after 20 requests from the same IP', async () => {
    const { POST } = await import('@/app/api/admin/bulk-note/route');
    const ip = '10.98.6.1';
    let lastStatus = 0;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-note', {
        method: 'POST',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
        body: JSON.stringify({}),
      });
      const res = await POST(req);
      lastStatus = res.status;
    }
    expect(lastStatus).toBe(429);
  });

  it('429 response includes Retry-After header', async () => {
    const { POST } = await import('@/app/api/admin/bulk-note/route');
    const ip = '10.98.6.2';
    let lastRes: Response | null = null;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-note', {
        method: 'POST',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
        body: JSON.stringify({}),
      });
      lastRes = await POST(req);
    }
    expect(lastRes?.headers.get('Retry-After')).toBeTruthy();
  });

  it('rate limit fires before auth check — wrong token still gets 429 when bucket exhausted', async () => {
    const { POST } = await import('@/app/api/admin/bulk-note/route');
    const ip = '10.98.6.3';
    for (let i = 0; i < 20; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-note', {
        method: 'POST',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
        body: JSON.stringify({}),
      });
      await POST(req);
    }
    const req = new NextRequest('http://localhost/api/admin/bulk-note', {
      method: 'POST',
      headers: { Authorization: 'Bearer wrong-token', 'x-forwarded-for': ip },
      body: JSON.stringify({}),
    });
    const res = await POST(req);
    expect(res.status).toBe(429);
  });
});
