import { describe, it, expect } from 'vitest';
import { generateLicenseKey, planExpiry } from '@/lib/license';

describe('generateLicenseKey', () => {
  const pattern = /^ADIA-[A-Z2-9]{4}-[A-Z2-9]{4}-[A-Z2-9]{4}$/;

  it('matches expected format', () => {
    expect(generateLicenseKey()).toMatch(pattern);
  });

  it('generates no duplicates over 1000 calls', () => {
    const keys = new Set(Array.from({ length: 1000 }, () => generateLicenseKey()));
    expect(keys.size).toBe(1000);
  });

  it('only contains valid alphabet characters', () => {
    for (let i = 0; i < 50; i++) {
      const key = generateLicenseKey();
      const parts = key.split('-');
      expect(parts).toHaveLength(4);
      for (const block of parts.slice(1)) {
        expect(block).toMatch(/^[A-Z2-9]{4}$/);
      }
    }
  });
});

describe('planExpiry', () => {
  it('returns null for lifetime', () => {
    expect(planExpiry('lifetime')).toBeNull();
  });

  it('returns ~31 days for monthly', () => {
    const expiry = planExpiry('monthly');
    expect(expiry).not.toBeNull();
    const diff = new Date(expiry!).getTime() - Date.now();
    const days = diff / (1000 * 60 * 60 * 24);
    expect(days).toBeGreaterThan(30.9);
    expect(days).toBeLessThan(31.1);
  });

  it('returns ~366 days for yearly', () => {
    const expiry = planExpiry('yearly');
    expect(expiry).not.toBeNull();
    const diff = new Date(expiry!).getTime() - Date.now();
    const days = diff / (1000 * 60 * 60 * 24);
    expect(days).toBeGreaterThan(365.9);
    expect(days).toBeLessThan(366.1);
  });

  it('returns a valid ISO date string', () => {
    const expiry = planExpiry('monthly');
    expect(expiry).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/);
  });
});
