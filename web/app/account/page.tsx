'use client';

import { useState } from 'react';
import Link from 'next/link';

export default function Account() {
  return (
    <section className="pt-12 pb-20 max-w-xl space-y-10">
      <div>
        <h1 className="text-3xl font-semibold tracking-tight">Your account</h1>
        <p className="mt-2 text-ink/60">Manage your Adia license and subscription.</p>
      </div>
      <ResendPanel />
      <div className="card space-y-2">
        <h2 className="text-lg font-semibold">Subscription &amp; billing</h2>
        <p className="text-sm text-ink/60">
          Update your card, change plan, or cancel — through Stripe's secure portal.
        </p>
        <Link href="/billing" className="btn-primary inline-block mt-1">
          Open billing portal →
        </Link>
      </div>
    </section>
  );
}

function ResendPanel() {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setSent(false);
    try {
      const res = await fetch('/api/license/resend', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      });
      if (res.status === 429) {
        setError('Too many requests — please wait a few minutes and try again.');
      } else if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(body.error ?? `Failed (HTTP ${res.status})`);
      } else {
        setSent(true);
        setEmail('');
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-1">Lost your license key?</h2>
      <p className="text-sm text-ink/60 mb-3">
        Enter your purchase email and we'll send your key(s) to that address.
      </p>
      {sent ? (
        <p className="text-sm text-green-700 bg-green-50 border border-green-200 rounded-lg px-4 py-3">
          If that email is in our system, you'll receive a message shortly. Check your spam folder
          if it doesn't arrive within a minute.
        </p>
      ) : (
        <form onSubmit={submit} className="card space-y-3">
          <label className="block">
            <span className="text-xs uppercase tracking-wide text-ink/60">Purchase email</span>
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
            {loading ? 'Sending…' : 'Send my license key →'}
          </button>
          {error && <p className="text-sm text-red-600">{error}</p>}
        </form>
      )}
    </div>
  );
}
