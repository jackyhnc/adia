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
  dbPath = path.join(
    os.tmpdir(),
    `adia-bulk-change-email-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
  );
  resetDbForTesting(dbPath);
  process.env.ADMIN_TOKEN = 'test-admin-token';
});

afterEach(() => {
  resetDbForTesting();
  delete process.env.ADMIN_TOKEN;
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

async function callBulkChangeEmail(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/bulk-change-email/route');
  const req = new NextRequest('http://localhost/api/admin/bulk-change-email', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });
  return POST(req);
}

function seedLicense(
  key: string,
  email: string,
  plan: 'lifetime' | 'monthly' | 'yearly' = 'lifetime',
) {
  insertLicense({ key, email, plan, expiresAt: null });
}

// ─── Auth ────────────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-change-email — auth', () => {
  it('returns 401 with no token', async () => {
    const { POST } = await import('@/app/api/admin/bulk-change-email/route');
    const req = new NextRequest('http://localhost/api/admin/bulk-change-email', {
      method: 'POST',
      body: JSON.stringify({ changes: [{ key: 'ADIA-BCE-AUTH-0001', newEmail: 'x@example.com' }] }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callBulkChangeEmail(
      { changes: [{ key: 'ADIA-BCE-AUTH-0002', newEmail: 'x@example.com' }] },
      'wrong-token',
    );
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query param', async () => {
    seedLicense('ADIA-BCE-AUTH-0003', 'old@example.com');
    const { POST } = await import('@/app/api/admin/bulk-change-email/route');
    const req = new NextRequest(
      'http://localhost/api/admin/bulk-change-email?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({
          changes: [{ key: 'ADIA-BCE-AUTH-0003', newEmail: 'new@example.com' }],
        }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ──────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-change-email — validation', () => {
  it('returns 400 when changes is missing', async () => {
    const res = await callBulkChangeEmail({});
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/changes/);
  });

  it('returns 400 when changes is empty array', async () => {
    const res = await callBulkChangeEmail({ changes: [] });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/changes/);
  });

  it('returns 400 when changes exceeds 100', async () => {
    const changes = Array.from({ length: 101 }, (_, i) => ({
      key: `ADIA-BCE-VAL-${String(i).padStart(4, '0')}`,
      newEmail: `user${i}@example.com`,
    }));
    const res = await callBulkChangeEmail({ changes });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/100/);
  });

  it('returns 400 when an entry is missing key', async () => {
    const res = await callBulkChangeEmail({ changes: [{ newEmail: 'x@example.com' }] });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/key/);
  });

  it('returns 400 when an entry is missing newEmail', async () => {
    const res = await callBulkChangeEmail({ changes: [{ key: 'ADIA-BCE-VAL-0200' }] });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/newEmail/);
  });

  it('returns 400 when an entry has invalid newEmail', async () => {
    const res = await callBulkChangeEmail({
      changes: [{ key: 'ADIA-BCE-VAL-0300', newEmail: 'not-an-email' }],
    });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/newEmail/);
  });

  it('returns 400 when a later entry has an invalid newEmail — no partial mutations', async () => {
    seedLicense('ADIA-BCE-VAL-0401', 'old@example.com');
    const res = await callBulkChangeEmail({
      changes: [
        { key: 'ADIA-BCE-VAL-0401', newEmail: 'valid@example.com' },
        { key: 'ADIA-BCE-VAL-0402', newEmail: 'bad-email' },
      ],
    });
    expect(res.status).toBe(400);
    // First key must not have been mutated because validation is up-front
    expect(findLicense('ADIA-BCE-VAL-0401')?.email).toBe('old@example.com');
  });
});

// ─── Core behavior ───────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-change-email — core behavior', () => {
  it('changes email on a single key', async () => {
    seedLicense('ADIA-BCE-CORE-0001', 'alice@example.com');
    const res = await callBulkChangeEmail({
      changes: [{ key: 'ADIA-BCE-CORE-0001', newEmail: 'bob@example.com' }],
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BCE-CORE-0001');
    expect(body.changed[0].oldEmail).toBe('alice@example.com');
    expect(body.changed[0].newEmail).toBe('bob@example.com');
    expect(body.skipped).toHaveLength(0);
    expect(findLicense('ADIA-BCE-CORE-0001')?.email).toBe('bob@example.com');
  });

  it('changes each key to its own different email in one request', async () => {
    seedLicense('ADIA-BCE-CORE-0002', 'old@example.com');
    seedLicense('ADIA-BCE-CORE-0003', 'old@example.com');
    seedLicense('ADIA-BCE-CORE-0004', 'old@example.com');
    const res = await callBulkChangeEmail({
      changes: [
        { key: 'ADIA-BCE-CORE-0002', newEmail: 'alice@corp.com' },
        { key: 'ADIA-BCE-CORE-0003', newEmail: 'bob@corp.com' },
        { key: 'ADIA-BCE-CORE-0004', newEmail: 'carol@corp.com' },
      ],
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(3);
    expect(findLicense('ADIA-BCE-CORE-0002')?.email).toBe('alice@corp.com');
    expect(findLicense('ADIA-BCE-CORE-0003')?.email).toBe('bob@corp.com');
    expect(findLicense('ADIA-BCE-CORE-0004')?.email).toBe('carol@corp.com');
  });

  it('normalizes key to uppercase', async () => {
    seedLicense('ADIA-BCE-CORE-0005', 'old@example.com');
    const res = await callBulkChangeEmail({
      changes: [{ key: 'adia-bce-core-0005', newEmail: 'new@example.com' }],
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed[0].key).toBe('ADIA-BCE-CORE-0005');
  });

  it('normalizes newEmail to lowercase', async () => {
    seedLicense('ADIA-BCE-CORE-0006', 'old@example.com');
    const res = await callBulkChangeEmail({
      changes: [{ key: 'ADIA-BCE-CORE-0006', newEmail: 'NEW@EXAMPLE.COM' }],
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed[0].newEmail).toBe('new@example.com');
    expect(findLicense('ADIA-BCE-CORE-0006')?.email).toBe('new@example.com');
  });

  it('response includes oldEmail and newEmail per changed entry', async () => {
    seedLicense('ADIA-BCE-CORE-0007', 'from@example.com');
    const res = await callBulkChangeEmail({
      changes: [{ key: 'ADIA-BCE-CORE-0007', newEmail: 'to@example.com' }],
    });
    const body = await res.json();
    expect(body.changed[0]).toMatchObject({
      key: 'ADIA-BCE-CORE-0007',
      oldEmail: 'from@example.com',
      newEmail: 'to@example.com',
    });
  });
});

// ─── Skip behavior ───────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-change-email — skip behavior', () => {
  it('skips unknown keys with reason=not_found', async () => {
    const res = await callBulkChangeEmail({
      changes: [{ key: 'ADIA-BCE-SKIP-0001', newEmail: 'new@example.com' }],
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0].key).toBe('ADIA-BCE-SKIP-0001');
    expect(body.skipped[0].reason).toBe('not_found');
  });

  it('skips keys already at the target email with reason=already_set', async () => {
    seedLicense('ADIA-BCE-SKIP-0002', 'same@example.com');
    const res = await callBulkChangeEmail({
      changes: [{ key: 'ADIA-BCE-SKIP-0002', newEmail: 'same@example.com' }],
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0].reason).toBe('already_set');
  });

  it('handles mixed changed + not_found + already_set in one request', async () => {
    seedLicense('ADIA-BCE-SKIP-0003', 'old@example.com');
    seedLicense('ADIA-BCE-SKIP-0004', 'stays@example.com'); // already_set target
    // ADIA-BCE-SKIP-0005 does not exist → not_found
    const res = await callBulkChangeEmail({
      changes: [
        { key: 'ADIA-BCE-SKIP-0003', newEmail: 'fresh@example.com' },
        { key: 'ADIA-BCE-SKIP-0004', newEmail: 'stays@example.com' },
        { key: 'ADIA-BCE-SKIP-0005', newEmail: 'x@example.com' },
      ],
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BCE-SKIP-0003');
    expect(body.skipped).toHaveLength(2);
    const reasons = body.skipped.map((s: { reason: string }) => s.reason);
    expect(reasons).toContain('already_set');
    expect(reasons).toContain('not_found');
  });

  it('does not mutate a skipped key', async () => {
    seedLicense('ADIA-BCE-SKIP-0006', 'owner@example.com');
    await callBulkChangeEmail({
      changes: [{ key: 'ADIA-BCE-SKIP-0006', newEmail: 'owner@example.com' }],
    });
    expect(findLicense('ADIA-BCE-SKIP-0006')?.email).toBe('owner@example.com');
  });
});

// ─── Audit log ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-change-email — audit log', () => {
  it('writes one audit log entry per changed key', async () => {
    seedLicense('ADIA-BCE-AUDT-0001', 'old@example.com');
    seedLicense('ADIA-BCE-AUDT-0002', 'old@example.com');
    await callBulkChangeEmail({
      changes: [
        { key: 'ADIA-BCE-AUDT-0001', newEmail: 'alice@example.com' },
        { key: 'ADIA-BCE-AUDT-0002', newEmail: 'bob@example.com' },
      ],
    });
    for (const key of ['ADIA-BCE-AUDT-0001', 'ADIA-BCE-AUDT-0002']) {
      const logs = listAuditLog({ licenseKey: key });
      expect(logs).toHaveLength(1);
      expect(logs[0].action).toBe('bulk_change_email');
    }
  });

  it('audit log detail contains oldEmail, newEmail, and bulk=true', async () => {
    seedLicense('ADIA-BCE-AUDT-0003', 'from@example.com');
    await callBulkChangeEmail({
      changes: [{ key: 'ADIA-BCE-AUDT-0003', newEmail: 'to@example.com' }],
    });
    const logs = listAuditLog({ licenseKey: 'ADIA-BCE-AUDT-0003' });
    const detail =
      typeof logs[0].detail === 'string' ? JSON.parse(logs[0].detail) : logs[0].detail;
    expect(detail).toMatchObject({
      oldEmail: 'from@example.com',
      newEmail: 'to@example.com',
      bulk: true,
    });
  });

  it('audit log entry captures the per-key newEmail (not a shared destination)', async () => {
    seedLicense('ADIA-BCE-AUDT-0004', 'old@example.com');
    seedLicense('ADIA-BCE-AUDT-0005', 'old@example.com');
    await callBulkChangeEmail({
      changes: [
        { key: 'ADIA-BCE-AUDT-0004', newEmail: 'alice@corp.com' },
        { key: 'ADIA-BCE-AUDT-0005', newEmail: 'bob@corp.com' },
      ],
    });
    const log4 = listAuditLog({ licenseKey: 'ADIA-BCE-AUDT-0004' });
    const detail4 = typeof log4[0].detail === 'string' ? JSON.parse(log4[0].detail) : log4[0].detail;
    expect(detail4.newEmail).toBe('alice@corp.com');

    const log5 = listAuditLog({ licenseKey: 'ADIA-BCE-AUDT-0005' });
    const detail5 = typeof log5[0].detail === 'string' ? JSON.parse(log5[0].detail) : log5[0].detail;
    expect(detail5.newEmail).toBe('bob@corp.com');
  });

  it('does not write audit log for skipped keys', async () => {
    seedLicense('ADIA-BCE-AUDT-0006', 'same@example.com');
    await callBulkChangeEmail({
      changes: [
        { key: 'ADIA-BCE-AUDT-0006', newEmail: 'same@example.com' }, // already_set
        { key: 'ADIA-BCE-AUDT-NONE', newEmail: 'x@example.com' },     // not_found
      ],
    });
    expect(listAuditLog({ licenseKey: 'ADIA-BCE-AUDT-0006' })).toHaveLength(0);
  });
});

// ─── Rate limit ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-change-email — rate limit', () => {
  it('returns 429 after 20 requests from the same IP', async () => {
    const { POST } = await import('@/app/api/admin/bulk-change-email/route');
    const ip = '10.98.1.1';
    let lastStatus = 0;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-change-email', {
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
    const { POST } = await import('@/app/api/admin/bulk-change-email/route');
    const ip = '10.98.1.2';
    let lastRes: Response | null = null;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-change-email', {
        method: 'POST',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
        body: JSON.stringify({}),
      });
      lastRes = await POST(req);
    }
    expect(lastRes?.headers.get('Retry-After')).toBeTruthy();
  });

  it('rate limit fires before auth check — wrong token still gets 429 when bucket exhausted', async () => {
    const { POST } = await import('@/app/api/admin/bulk-change-email/route');
    const ip = '10.98.1.3';
    for (let i = 0; i < 20; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-change-email', {
        method: 'POST',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
        body: JSON.stringify({}),
      });
      await POST(req);
    }
    const req = new NextRequest('http://localhost/api/admin/bulk-change-email', {
      method: 'POST',
      headers: { Authorization: 'Bearer wrong-token', 'x-forwarded-for': ip },
      body: JSON.stringify({}),
    });
    const res = await POST(req);
    expect(res.status).toBe(429);
  });
});
