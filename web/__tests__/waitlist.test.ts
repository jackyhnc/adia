import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting } from '@/lib/db';

let dbPath: string;

beforeEach(() => {
  dbPath = path.join(os.tmpdir(), `adia-waitlist-${Date.now()}.db`);
  resetDbForTesting(dbPath);
});

afterEach(() => {
  resetDbForTesting();
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

async function callPost(email: string) {
  const { POST } = await import('@/app/api/waitlist/route');
  const formData = new FormData();
  formData.set('email', email);
  const req = new NextRequest('http://localhost/api/waitlist', {
    method: 'POST',
    body: formData,
  });
  return POST(req);
}

describe('POST /api/waitlist', () => {
  it('redirects invalid email to /download?waitlist=invalid', async () => {
    const res = await callPost('not-an-email');
    expect(res.status).toBe(307);
    expect(res.headers.get('location')).toContain('/download?waitlist=invalid');
  });

  it('redirects missing @ to invalid', async () => {
    const res = await callPost('nodomain');
    expect(res.status).toBe(307);
    expect(res.headers.get('location')).toContain('waitlist=invalid');
  });

  it('redirects valid email to /download?waitlist=ok', async () => {
    const res = await callPost('valid@example.com');
    expect(res.status).toBe(307);
    expect(res.headers.get('location')).toContain('/download?waitlist=ok');
  });

  it('accepts email with subdomains', async () => {
    const res = await callPost('user@mail.example.co.uk');
    expect(res.status).toBe(307);
    expect(res.headers.get('location')).toContain('waitlist=ok');
  });

  it('second submission of same email does not crash', async () => {
    await callPost('repeat@example.com');
    const res2 = await callPost('repeat@example.com');
    expect(res2.status).toBe(307);
    expect(res2.headers.get('location')).toContain('waitlist=ok');
  });
});
