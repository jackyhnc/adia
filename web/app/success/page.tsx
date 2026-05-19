import Link from 'next/link';

export default function Success({ searchParams }: { searchParams: { license?: string; email?: string } }) {
  const { license, email } = searchParams;
  return (
    <section className="pt-16 pb-20 max-w-xl">
      <div className="text-5xl">🎉</div>
      <h1 className="mt-4 text-4xl font-semibold tracking-tight">You're in.</h1>
      <p className="mt-3 text-ink/70">
        Your license has been emailed to <b>{email ?? 'your inbox'}</b>. Paste it into Adia and you're off.
      </p>
      {license && (
        <div className="card mt-6">
          <div className="text-xs text-ink/60">Your license key</div>
          <div className="mt-1 font-mono text-lg select-all">{license}</div>
          <p className="mt-3 text-xs text-ink/60">
            Open Adia → click the notch → settings → paste the key with the email above.
          </p>
        </div>
      )}
      <div className="mt-8 flex gap-3">
        <Link href="/download" className="btn-primary">Download Adia</Link>
        <Link href="/" className="btn-secondary">Back to home</Link>
      </div>
    </section>
  );
}
