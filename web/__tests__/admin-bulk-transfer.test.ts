import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, findLicense, insertLicense, listAuditLog } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(os.tmpdir(), `adia-bulk-transfer-${Date.now()}-${Math.random().toString(36).slice(2)}.db`);
  resetDbForTesting(dbPath);
  process.env.ADMIN_TOKEN = 'test-admin-token';
});

afterEach(() => {
  resetDbForTesting();
  delete process.env.ADMIN_TOKEN;
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

async function callBulkTransfer(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/bulk-transfer/route');
  const req = new NextRequest('http://localhost/api/admin/bulk-transfer', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });
  return POST(req);
}

function seedLicense(key: string, email: string, plan: 'lifetime' | 'monthly' | 'yearly' = 'lifetime') {
  insertLicense({ key, email, plan, expiresAt: null });
}

// ─── Auth ────────────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-transfer — auth', () => {
  it('returns 401 with no token', async () => {
    const { POST } = await import('@/app/api/admin/bulk-transfer/route');
    const req = new NextRequest('http://localhost/api/admin/bulk-transfer', {
      method: 'POST',
      body: JSON.stringify({ keys: ['ADIA-XFER-AUTH-0001'], newEmail: 'x@example.com' }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callBulkTransfer(
      { keys: ['ADIA-XFER-AUTH-0002'], newEmail: 'x@example.com' },
      'wrong-token',
    );
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query param', async () => {
    seedLicense('ADIA-XFER-AUTH-0003', 'old@example.com');
    const { POST } = await import('@/app/api/admin/bulk-transfer/route');
    const req = new NextRequest(
      `http://localhost/api/admin/bulk-transfer?token=test-admin-token`,
      {
        method: 'POST',
        body: JSON.stringify({ keys: ['ADIA-XFER-AUTH-0003'], newEmail: 'new@example.com' }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ──────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-transfer — validation', () => {
  it('returns 400 when keys is missing', async () => {
    const res = await callBulkTransfer({ newEmail: 'x@example.com' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/keys/);
  });

  it('returns 400 when keys is empty', async () => {
    const res = await callBulkTransfer({ keys: [], newEmail: 'x@example.com' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/keys/);
  });

  it('returns 400 when keys exceeds 100', async () => {
    const keys = Array.from({ length: 101 }, (_, i) => `ADIA-XFER-VAL-${String(i).padStart(4, '0')}`);
    const res = await callBulkTransfer({ keys, newEmail: 'x@example.com' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/100/);
  });

  it('returns 400 when newEmail is missing', async () => {
    const res = await callBulkTransfer({ keys: ['ADIA-XFER-VAL-0200'] });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/newEmail/);
  });

  it('returns 400 when newEmail is not a valid email', async () => {
    const res = await callBulkTransfer({ keys: ['ADIA-XFER-VAL-0300'], newEmail: 'not-an-email' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/newEmail/);
  });
});

// ─── Core behavior ───────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-transfer — core behavior', () => {
  it('transfers a single key to the new email', async () => {
    seedLicense('ADIA-XFER-CORE-0001', 'alice@example.com');
    const res = await callBulkTransfer({
      keys: ['ADIA-XFER-CORE-0001'],
      newEmail: 'bob@example.com',
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-XFER-CORE-0001');
    expect(body.changed[0].oldEmail).toBe('alice@example.com');
    expect(body.skipped).toHaveLength(0);
    expect(findLicense('ADIA-XFER-CORE-0001')?.email).toBe('bob@example.com');
  });

  it('transfers multiple keys in one request', async () => {
    seedLicense('ADIA-XFER-CORE-0002', 'alice@example.com');
    seedLicense('ADIA-XFER-CORE-0003', 'alice@example.com');
    seedLicense('ADIA-XFER-CORE-0004', 'alice@example.com');
    const res = await callBulkTransfer({
      keys: ['ADIA-XFER-CORE-0002', 'ADIA-XFER-CORE-0003', 'ADIA-XFER-CORE-0004'],
      newEmail: 'newowner@example.com',
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(3);
    for (const key of ['ADIA-XFER-CORE-0002', 'ADIA-XFER-CORE-0003', 'ADIA-XFER-CORE-0004']) {
      expect(findLicense(key)?.email).toBe('newowner@example.com');
    }
  });

  it('normalizes newEmail to lowercase', async () => {
    seedLicense('ADIA-XFER-CORE-0005', 'old@example.com');
    const res = await callBulkTransfer({
      keys: ['ADIA-XFER-CORE-0005'],
      newEmail: 'NEW@EXAMPLE.COM',
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.newEmail).toBe('new@example.com');
    expect(findLicense('ADIA-XFER-CORE-0005')?.email).toBe('new@example.com');
  });

  it('normalizes key input to uppercase', async () => {
    seedLicense('ADIA-XFER-CORE-0006', 'old@example.com');
    const res = await callBulkTransfer({
      keys: ['adia-xfer-core-0006'],
      newEmail: 'new@example.com',
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed[0].key).toBe('ADIA-XFER-CORE-0006');
  });

  it('returns newEmail in response', async () => {
    seedLicense('ADIA-XFER-CORE-0007', 'old@example.com');
    const res = await callBulkTransfer({
      keys: ['ADIA-XFER-CORE-0007'],
      newEmail: 'target@example.com',
    });
    const body = await res.json();
    expect(body.newEmail).toBe('target@example.com');
  });
});

// ─── Skip behavior ───────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-transfer — skip behavior', () => {
  it('skips unknown keys with reason=not_found', async () => {
    const res = await callBulkTransfer({
      keys: ['ADIA-XFER-SKIP-0001'],
      newEmail: 'new@example.com',
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0].key).toBe('ADIA-XFER-SKIP-0001');
    expect(body.skipped[0].reason).toBe('not_found');
  });

  it('skips keys already owned by newEmail with reason=already_set', async () => {
    seedLicense('ADIA-XFER-SKIP-0002', 'same@example.com');
    const res = await callBulkTransfer({
      keys: ['ADIA-XFER-SKIP-0002'],
      newEmail: 'same@example.com',
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0].reason).toBe('already_set');
  });

  it('handles mixed changed + skipped in one request', async () => {
    seedLicense('ADIA-XFER-SKIP-0003', 'alice@example.com');
    seedLicense('ADIA-XFER-SKIP-0004', 'bob@example.com'); // already_set
    // ADIA-XFER-SKIP-0005 doesn't exist → not_found
    const res = await callBulkTransfer({
      keys: ['ADIA-XFER-SKIP-0003', 'ADIA-XFER-SKIP-0004', 'ADIA-XFER-SKIP-0005'],
      newEmail: 'bob@example.com',
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-XFER-SKIP-0003');
    expect(body.skipped).toHaveLength(2);
    const reasons = body.skipped.map((s: { reason: string }) => s.reason);
    expect(reasons).toContain('already_set');
    expect(reasons).toContain('not_found');
  });

  it('does not mutate a skipped key', async () => {
    seedLicense('ADIA-XFER-SKIP-0006', 'owner@example.com');
    await callBulkTransfer({
      keys: ['ADIA-XFER-SKIP-0006'],
      newEmail: 'owner@example.com', // same → skip
    });
    expect(findLicense('ADIA-XFER-SKIP-0006')?.email).toBe('owner@example.com');
  });
});

// ─── Audit log ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-transfer — audit log', () => {
  it('writes one audit log entry per transferred key', async () => {
    seedLicense('ADIA-XFER-AUDT-0001', 'old@example.com');
    seedLicense('ADIA-XFER-AUDT-0002', 'old@example.com');
    await callBulkTransfer({
      keys: ['ADIA-XFER-AUDT-0001', 'ADIA-XFER-AUDT-0002'],
      newEmail: 'new@example.com',
    });
    for (const key of ['ADIA-XFER-AUDT-0001', 'ADIA-XFER-AUDT-0002']) {
      const logs = listAuditLog({ licenseKey: key });
      expect(logs).toHaveLength(1);
      expect(logs[0].action).toBe('bulk_transfer');
    }
  });

  it('audit log entry contains oldEmail, newEmail, and bulk=true', async () => {
    seedLicense('ADIA-XFER-AUDT-0003', 'from@example.com');
    await callBulkTransfer({
      keys: ['ADIA-XFER-AUDT-0003'],
      newEmail: 'to@example.com',
    });
    const logs = listAuditLog({ licenseKey: 'ADIA-XFER-AUDT-0003' });
    const detail = typeof logs[0].detail === 'string' ? JSON.parse(logs[0].detail) : logs[0].detail;
    expect(detail).toMatchObject({
      oldEmail: 'from@example.com',
      newEmail: 'to@example.com',
      bulk: true,
    });
  });

  it('does not write audit log for skipped keys', async () => {
    seedLicense('ADIA-XFER-AUDT-0004', 'same@example.com');
    await callBulkTransfer({
      keys: ['ADIA-XFER-AUDT-0004', 'ADIA-XFER-AUDT-NONE'],
      newEmail: 'same@example.com', // 0004 → already_set; NONE → not_found
    });
    const logs4 = listAuditLog({ licenseKey: 'ADIA-XFER-AUDT-0004' });
    expect(logs4).toHaveLength(0);
  });
});

// ─── Rate limit ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-transfer — rate limit', () => {
  it('returns 429 after 20 requests from the same IP', async () => {
    const { POST } = await import('@/app/api/admin/bulk-transfer/route');
    const ip = '10.98.12.1';
    let lastStatus = 0;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-transfer', {
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
    const { POST } = await import('@/app/api/admin/bulk-transfer/route');
    const ip = '10.98.12.2';
    let lastRes: Response | null = null;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-transfer', {
        method: 'POST',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
        body: JSON.stringify({}),
      });
      lastRes = await POST(req);
    }
    expect(lastRes?.headers.get('Retry-After')).toBeTruthy();
  });

  it('rate limit fires before auth check — wrong token still gets 429 when bucket exhausted', async () => {
    const { POST } = await import('@/app/api/admin/bulk-transfer/route');
    const ip = '10.98.12.3';
    for (let i = 0; i < 20; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-transfer', {
        method: 'POST',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
        body: JSON.stringify({}),
      });
      await POST(req);
    }
    const req = new NextRequest('http://localhost/api/admin/bulk-transfer', {
      method: 'POST',
      headers: { Authorization: 'Bearer wrong-token', 'x-forwarded-for': ip },
      body: JSON.stringify({}),
    });
    const res = await POST(req);
    expect(res.status).toBe(429);
  });
});
