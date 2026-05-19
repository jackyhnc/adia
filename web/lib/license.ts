import crypto from 'node:crypto';

export function generateLicenseKey(): string {
  // ADIA-XXXX-XXXX-XXXX where X is base32-ish (no 0/O/1/I)
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const block = () =>
    Array.from(crypto.randomBytes(4))
      .map((b) => alphabet[b % alphabet.length])
      .join('');
  return `ADIA-${block()}-${block()}-${block()}`;
}

export function planExpiry(plan: 'monthly' | 'yearly' | 'lifetime'): string | null {
  const now = new Date();
  if (plan === 'lifetime') return null;
  const ms = plan === 'monthly'
    ? 31 * 24 * 60 * 60 * 1000
    : 366 * 24 * 60 * 60 * 1000;
  return new Date(now.getTime() + ms).toISOString();
}
