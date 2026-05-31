export const dynamic = 'force-dynamic';

async function fetchLatestRelease() {
  try {
    const res = await fetch('https://api.github.com/repos/jackyhnc/adia/releases/latest', {
      next: { revalidate: 600 },
      headers: { Accept: 'application/vnd.github+json' },
    });
    if (!res.ok) return null;
    const data = await res.json();
    const dmg = data.assets?.find((a: any) => a.name?.endsWith('.dmg'));
    return {
      version: data.tag_name as string,
      url: (dmg?.browser_download_url as string) ?? null,
      publishedAt: data.published_at as string,
    };
  } catch {
    return null;
  }
}

export default async function Download() {
  const release = await fetchLatestRelease();
  return (
    <section className="pt-12 pb-20 max-w-2xl">
      <h1 className="text-4xl md:text-5xl font-semibold tracking-tight">Download Adia</h1>
      <p className="mt-3 text-ink/70">macOS 14 (Sonoma) or later. Apple Silicon native.</p>

      <div className="card mt-8">
        {release?.url ? (
          <>
            <div className="text-sm text-ink/60">Latest release</div>
            <div className="mt-1 text-2xl font-semibold">Adia {release.version}</div>
            <div className="text-sm text-ink/60">
              Published {new Date(release.publishedAt).toLocaleDateString()}
            </div>
            <a className="btn-primary mt-6" href={release.url}>Download .dmg</a>
            <p className="mt-4 text-xs text-ink/50">
              Verified by Apple notarization. SHA-256 in release notes.
            </p>
          </>
        ) : (
          <>
            <div className="text-2xl font-semibold">Coming soon</div>
            <p className="mt-2 text-sm text-ink/70">
              We're notarizing the first build. Drop your email and we'll send it the moment it's live.
            </p>
            <form method="post" action="/api/waitlist" className="mt-6 flex gap-2">
              <input
                type="email"
                name="email"
                required
                placeholder="you@school.edu"
                className="flex-1 rounded-full border border-ink/20 px-4 py-2 text-sm"
              />
              <button type="submit" className="btn-primary">Notify me</button>
            </form>
          </>
        )}
      </div>

      <ol className="mt-10 space-y-4 text-sm text-ink/80 list-decimal pl-5">
        <li>Open the .dmg and drag <b>Adia</b> to Applications.</li>
        <li>First launch: macOS will ask for <b>Screen Recording</b> permission. Grant it in System Settings → Privacy & Security.</li>
        <li>Adia walks you through entering your OpenAI API key and starts your 7-day trial.</li>
        <li>Click the dot in your notch, type your task, hit Go.</li>
      </ol>
    </section>
  );
}
