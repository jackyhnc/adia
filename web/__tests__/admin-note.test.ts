// Tests for GET /api/admin/note and POST /api/admin/note
// GET  ?key=... → returns current note (null when unset).
// POST { key, note } → stores/updates the note; empty string / omitted clears it.

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, getNote } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(
    os.tmpdir(),
    `adia-note-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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

async function callGet(params: Record<string, string>, token = 'test-admin-token') {
  const { GET } = await import('@/app/api/admin/note/route');
  const qs = new URLSearchParams(params).toString();
  const req = new NextRequest(`http://localhost/api/admin/note?${qs}`, {
    method: 'GET',
    headers: authHeader(token),
  });
  return GET(req);
}

async function callPost(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/note/route');
  const req = new NextRequest('http://localhost/api/admin/note', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', ...authHeader(token) },
  });
  return POST(req);
}

// ─── GET ─────────────────────────────────────────────────────────────────────

describe('GET /api/admin/note', () => {
  it('returns 401 with no authorization header', async () => {
    const { GET } = await import('@/app/api/admin/note/route');
    const req = new NextRequest('http://localhost/api/admin/note?key=ADIA-XXXX-XXXX-XXXX', {
      method: 'GET',
    });
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callGet({ key: 'ADIA-XXXX-XXXX-XXXX' }, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('returns 400 when key is missing', async () => {
    const res = await callGet({});
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing key/i);
  });

  it('returns 404 for unknown key', async () => {
    const res = await callGet({ key: 'ADIA-UNKN-UNKN-UNKN' });
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body.error).toMatch(/unknown key/i);
  });

  it('returns null note when no note has been set', async () => {
    insertLicense({ key: 'ADIA-NOTE-NULL-AAAA', email: 'null@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callGet({ key: 'ADIA-NOTE-NULL-AAAA' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.key).toBe('ADIA-NOTE-NULL-AAAA');
    expect(body.note).toBeNull();
  });

  it('returns the note after it has been set', async () => {
    const key = 'ADIA-NOTE-RDNG-AAAA';
    insertLicense({ key, email: 'reading@example.com', plan: 'monthly', expiresAt: null });
    await callPost({ key, note: 'Speaker comp — PyCon 2026' });

    const res = await callGet({ key });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.note).toBe('Speaker comp — PyCon 2026');
  });

  it('accepts ?token= query param as auth fallback', async () => {
    insertLicense({ key: 'ADIA-NOTE-TOKN-AAAA', email: 'tok@example.com', plan: 'lifetime', expiresAt: null });
    const { GET } = await import('@/app/api/admin/note/route');
    const req = new NextRequest(
      'http://localhost/api/admin/note?key=ADIA-NOTE-TOKN-AAAA&token=test-admin-token',
      { method: 'GET' },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
  });
});

// ─── POST ────────────────────────────────────────────────────────────────────

describe('POST /api/admin/note', () => {
  it('returns 401 with no authorization header', async () => {
    const { POST } = await import('@/app/api/admin/note/route');
    const req = new NextRequest('http://localhost/api/admin/note', {
      method: 'POST',
      body: JSON.stringify({ key: 'ADIA-XXXX-XXXX-XXXX', note: 'test' }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callPost({ key: 'ADIA-XXXX-XXXX-XXXX', note: 'test' }, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('returns 400 when key is missing from body', async () => {
    const res = await callPost({ note: 'orphan note' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing key/i);
  });

  it('returns 400 when body is not valid JSON', async () => {
    const { POST } = await import('@/app/api/admin/note/route');
    const req = new NextRequest('http://localhost/api/admin/note', {
      method: 'POST',
      body: 'not-json',
      headers: { 'Content-Type': 'application/json', ...authHeader() },
    });
    const res = await POST(req);
    expect(res.status).toBe(400);
  });

  it('returns 404 for unknown key', async () => {
    const res = await callPost({ key: 'ADIA-UNKN-UNKN-UNKN', note: 'hi' });
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body.error).toMatch(/unknown key/i);
  });

  it('stores a note and returns it in the response', async () => {
    const key = 'ADIA-NOTE-STOR-AAAA';
    insertLicense({ key, email: 'store@example.com', plan: 'lifetime', expiresAt: null });

    const res = await callPost({ key, note: 'Beta tester — cohort 3' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.key).toBe(key);
    expect(body.note).toBe('Beta tester — cohort 3');

    // Verify persisted in DB.
    expect(getNote(key)).toBe('Beta tester — cohort 3');
  });

  it('overwrites an existing note', async () => {
    const key = 'ADIA-NOTE-UPDT-AAAA';
    insertLicense({ key, email: 'update@example.com', plan: 'monthly', expiresAt: null });

    await callPost({ key, note: 'First note' });
    expect(getNote(key)).toBe('First note');

    const res = await callPost({ key, note: 'Updated note' });
    expect(res.status).toBe(200);
    expect((await res.json()).note).toBe('Updated note');
    expect(getNote(key)).toBe('Updated note');
  });

  it('clears note when empty string is passed', async () => {
    const key = 'ADIA-NOTE-CLRE-AAAA';
    insertLicense({ key, email: 'clear-empty@example.com', plan: 'lifetime', expiresAt: null });

    await callPost({ key, note: 'Some note' });
    expect(getNote(key)).toBe('Some note');

    const res = await callPost({ key, note: '' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.note).toBeNull();
    expect(getNote(key)).toBeNull();
  });

  it('clears note when note is explicitly null', async () => {
    const key = 'ADIA-NOTE-CLRN-AAAA';
    insertLicense({ key, email: 'clear-null@example.com', plan: 'lifetime', expiresAt: null });

    await callPost({ key, note: 'Old note' });
    const res = await callPost({ key, note: null });
    expect(res.status).toBe(200);
    expect((await res.json()).note).toBeNull();
    expect(getNote(key)).toBeNull();
  });

  it('clears note when note field is absent from body', async () => {
    const key = 'ADIA-NOTE-CLRO-AAAA';
    insertLicense({ key, email: 'clear-omit@example.com', plan: 'yearly', expiresAt: null });

    await callPost({ key, note: 'Will be cleared' });
    const res = await callPost({ key });
    expect(res.status).toBe(200);
    expect((await res.json()).note).toBeNull();
    expect(getNote(key)).toBeNull();
  });

  it('normalizes key to uppercase before lookup', async () => {
    const key = 'ADIA-NOTE-CASE-AAAA';
    insertLicense({ key, email: 'case@example.com', plan: 'lifetime', expiresAt: null });

    const res = await callPost({ key: 'adia-note-case-aaaa', note: 'case-insensitive' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.key).toBe(key);
    expect(body.note).toBe('case-insensitive');
    expect(getNote(key)).toBe('case-insensitive');
  });

  it('trims whitespace from note before storing', async () => {
    const key = 'ADIA-NOTE-TRIM-AAAA';
    insertLicense({ key, email: 'trim@example.com', plan: 'lifetime', expiresAt: null });

    const res = await callPost({ key, note: '  trimmed note  ' });
    expect(res.status).toBe(200);
    expect((await res.json()).note).toBe('trimmed note');
    expect(getNote(key)).toBe('trimmed note');
  });

  it('accepts ?token= query param as auth fallback', async () => {
    const key = 'ADIA-NOTE-TOKP-AAAA';
    insertLicense({ key, email: 'tokpost@example.com', plan: 'lifetime', expiresAt: null });

    const { POST } = await import('@/app/api/admin/note/route');
    const req = new NextRequest(
      'http://localhost/api/admin/note?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ key, note: 'token-auth note' }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
    expect((await res.json()).note).toBe('token-auth note');
  });
});
