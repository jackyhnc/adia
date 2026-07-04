import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, findLicense, insertLicense, listAuditLog, setStatus } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(
    os.tmpdir(),
    `adia-bulk-revoke-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
  );
  resetDbForTesting(dbPath);
  process.env.ADMIN_TOKEN = 'test-admin-token';
});

afterEach(() => {
  resetDbForTesting();
  delete process.env.ADMIN_TOKEN;
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

async function callBulkRevoke(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/bulk-revoke/route');
  const req = new NextRequest('http://localhost/api/admin/bulk-revoke', {
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
  email = 'owner@example.com',
  plan: 'lifetime' | 'monthly' | 'yearly' = 'lifetime',
) {
  insertLicense({ key, email, plan, expiresAt: null });
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-revoke — auth', () => {
  it('returns 401 with no token', async () => {
    const { POST } = await import('@/app/api/admin/bulk-revoke/route');
    const req = new NextRequest('http://localhost/api/admin/bulk-revoke', {
      method: 'POST',
      body: JSON.stringify({ keys: ['ADIA-BRVK-AUTH-0001'] }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callBulkRevoke({ keys: ['ADIA-BRVK-AUTH-0002'] }, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query param', async () => {
    seedLicense('ADIA-BRVK-AUTH-0003');
    const { POST } = await import('@/app/api/admin/bulk-revoke/route');
    const req = new NextRequest(
      'http://localhost/api/admin/bulk-revoke?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ keys: ['ADIA-BRVK-AUTH-0003'] }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-revoke — validation', () => {
  it('returns 400 when keys is missing', async () => {
    const res = await callBulkRevoke({});
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/keys/);
  });

  it('returns 400 when keys is empty', async () => {
    const res = await callBulkRevoke({ keys: [] });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/keys/);
  });

  it('returns 400 when keys exceeds 100', async () => {
    const keys = Array.from({ length: 101 }, (_, i) => `ADIA-BRVK-VAL-${String(i).padStart(4, '0')}`);
    const res = await callBulkRevoke({ keys });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/100/);
  });
});

// ─── Core behavior ────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-revoke — core behavior', () => {
  it('revokes a single active key', async () => {
    seedLicense('ADIA-BRVK-CORE-0001');
    const res = await callBulkRevoke({ keys: ['ADIA-BRVK-CORE-0001'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BRVK-CORE-0001');
    expect(body.skipped).toHaveLength(0);
    expect(findLicense('ADIA-BRVK-CORE-0001')?.status).toBe('canceled');
  });

  it('revokes multiple keys in one request', async () => {
    seedLicense('ADIA-BRVK-CORE-0002');
    seedLicense('ADIA-BRVK-CORE-0003');
    seedLicense('ADIA-BRVK-CORE-0004');
    const res = await callBulkRevoke({
      keys: ['ADIA-BRVK-CORE-0002', 'ADIA-BRVK-CORE-0003', 'ADIA-BRVK-CORE-0004'],
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(3);
    for (const key of ['ADIA-BRVK-CORE-0002', 'ADIA-BRVK-CORE-0003', 'ADIA-BRVK-CORE-0004']) {
      expect(findLicense(key)?.status).toBe('canceled');
    }
  });

  it('normalizes keys to uppercase', async () => {
    seedLicense('ADIA-BRVK-CORE-0005');
    const res = await callBulkRevoke({ keys: ['adia-brvk-core-0005'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed[0].key).toBe('ADIA-BRVK-CORE-0005');
    expect(findLicense('ADIA-BRVK-CORE-0005')?.status).toBe('canceled');
  });

  it('returns previousStatus=active in changed entry', async () => {
    seedLicense('ADIA-BRVK-CORE-0006');
    const res = await callBulkRevoke({ keys: ['ADIA-BRVK-CORE-0006'] });
    const body = await res.json();
    expect(body.changed[0].previousStatus).toBe('active');
  });

  it('returns previousStatus=past_due when revoking a past_due license', async () => {
    seedLicense('ADIA-BRVK-CORE-0007');
    setStatus('ADIA-BRVK-CORE-0007', 'past_due');
    const res = await callBulkRevoke({ keys: ['ADIA-BRVK-CORE-0007'] });
    const body = await res.json();
    expect(body.changed[0].previousStatus).toBe('past_due');
    expect(findLicense('ADIA-BRVK-CORE-0007')?.status).toBe('canceled');
  });

  it('returns previousStatus=expired when revoking an expired license', async () => {
    seedLicense('ADIA-BRVK-CORE-0008');
    setStatus('ADIA-BRVK-CORE-0008', 'expired');
    const res = await callBulkRevoke({ keys: ['ADIA-BRVK-CORE-0008'] });
    const body = await res.json();
    expect(body.changed[0].previousStatus).toBe('expired');
    expect(findLicense('ADIA-BRVK-CORE-0008')?.status).toBe('canceled');
  });
});

// ─── Skip behavior ────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-revoke — skip behavior', () => {
  it('skips unknown keys with reason=not_found', async () => {
    const res = await callBulkRevoke({ keys: ['ADIA-BRVK-SKIP-0001'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0].key).toBe('ADIA-BRVK-SKIP-0001');
    expect(body.skipped[0].reason).toBe('not_found');
  });

  it('skips already-canceled keys with reason=already_revoked', async () => {
    seedLicense('ADIA-BRVK-SKIP-0002');
    setStatus('ADIA-BRVK-SKIP-0002', 'canceled');
    const res = await callBulkRevoke({ keys: ['ADIA-BRVK-SKIP-0002'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0].key).toBe('ADIA-BRVK-SKIP-0002');
    expect(body.skipped[0].reason).toBe('already_revoked');
  });

  it('handles mixed changed + skipped in one request', async () => {
    seedLicense('ADIA-BRVK-SKIP-0003');
    seedLicense('ADIA-BRVK-SKIP-0004');
    setStatus('ADIA-BRVK-SKIP-0004', 'canceled');
    // ADIA-BRVK-SKIP-0005 does not exist → not_found
    const res = await callBulkRevoke({
      keys: ['ADIA-BRVK-SKIP-0003', 'ADIA-BRVK-SKIP-0004', 'ADIA-BRVK-SKIP-0005'],
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BRVK-SKIP-0003');
    expect(body.skipped).toHaveLength(2);
    const reasons = body.skipped.map((s: { reason: string }) => s.reason);
    expect(reasons).toContain('already_revoked');
    expect(reasons).toContain('not_found');
  });

  it('does not mutate a skipped key', async () => {
    seedLicense('ADIA-BRVK-SKIP-0006');
    setStatus('ADIA-BRVK-SKIP-0006', 'canceled');
    await callBulkRevoke({ keys: ['ADIA-BRVK-SKIP-0006'] });
    // status must remain canceled (not double-written or reset)
    expect(findLicense('ADIA-BRVK-SKIP-0006')?.status).toBe('canceled');
  });
});

// ─── Audit log ────────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-revoke — audit log', () => {
  it('writes one audit log entry per revoked key', async () => {
    seedLicense('ADIA-BRVK-AUDT-0001');
    seedLicense('ADIA-BRVK-AUDT-0002');
    await callBulkRevoke({ keys: ['ADIA-BRVK-AUDT-0001', 'ADIA-BRVK-AUDT-0002'] });
    for (const key of ['ADIA-BRVK-AUDT-0001', 'ADIA-BRVK-AUDT-0002']) {
      const logs = listAuditLog({ licenseKey: key });
      expect(logs).toHaveLength(1);
      expect(logs[0].action).toBe('revoke');
    }
  });

  it('audit log detail contains previousStatus, newStatus=canceled, bulk=true', async () => {
    seedLicense('ADIA-BRVK-AUDT-0003');
    await callBulkRevoke({ keys: ['ADIA-BRVK-AUDT-0003'] });
    const logs = listAuditLog({ licenseKey: 'ADIA-BRVK-AUDT-0003' });
    const detail =
      typeof logs[0].detail === 'string' ? JSON.parse(logs[0].detail) : logs[0].detail;
    expect(detail).toMatchObject({
      previousStatus: 'active',
      newStatus: 'canceled',
      bulk: true,
    });
  });

  it('does not write audit log for not_found keys', async () => {
    await callBulkRevoke({ keys: ['ADIA-BRVK-AUDT-NONE'] });
    const logs = listAuditLog({ licenseKey: 'ADIA-BRVK-AUDT-NONE' });
    expect(logs).toHaveLength(0);
  });

  it('does not write audit log for already-canceled keys', async () => {
    seedLicense('ADIA-BRVK-AUDT-0004');
    setStatus('ADIA-BRVK-AUDT-0004', 'canceled');
    await callBulkRevoke({ keys: ['ADIA-BRVK-AUDT-0004'] });
    const logs = listAuditLog({ licenseKey: 'ADIA-BRVK-AUDT-0004' });
    expect(logs).toHaveLength(0);
  });
});
