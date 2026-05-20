'use client';

import { useState } from 'react';
import Link from 'next/link';

export default function Billing() {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function openPortal(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    const res = await fetch('/api/billing/portal', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email }),
    });
    if (res.ok) {
      const { url } = await res.json();
      window.location.href = url;
    } else {
      const body = await res.json().catch(() => ({}));
      setError(body.error ?? `Failed (HTTP ${res.status})`);
      setLoading(false);
    }
  }

  return (
    <section className="pt-12 pb-20 max-w-xl">
      <h1 className="text-3xl font-semibold tracking-tight">Manage your subscription</h1>
      <p className="mt-3 text-ink/70">
        Update your card, change plan, download invoices, or cancel — all through Stripe's secure
        customer portal. Enter the email you used at checkout and we'll send you to your billing page.
      </p>

      <form onSubmit={openPortal} className="card mt-8 space-y-3">
        <label className="block">
          <span className="text-xs uppercase tracking-wide text-ink/60">Billing email</span>
          <input
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="you@example.com"
            className="input mt-1"
          />
        </label>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Opening portal…' : 'Open Stripe portal →'}
        </button>
        {error && <p className="text-sm text-red-600">{error}</p>}
      </form>

      <p className="mt-6 text-sm text-ink/60">
        Lifetime customers don't have a subscription — there's nothing to manage. If you need an
        invoice, email <Link href="mailto:support@adia.app">support@adia.app</Link>.
      </p>
    </section>
  );
}
