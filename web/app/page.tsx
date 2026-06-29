import Link from 'next/link';

export default function Home() {
  return (
    <>
      <section className="pt-12 pb-20 max-w-3xl">
        <div className="inline-flex items-center gap-2 rounded-full border border-ink/15 px-3 py-1 text-xs text-ink/70 mb-6">
          <span className="inline-block w-1.5 h-1.5 rounded-full bg-accent" />
          Now in early access for macOS
        </div>
        <h1 className="text-5xl md:text-6xl font-semibold leading-[1.05] tracking-tight">
          The friend in your notch
          <br />
          who keeps you on task.
        </h1>
        <p className="mt-6 text-lg text-ink/70 max-w-xl">
          Tell Adia what you're working on. It watches your screen, blocks distractions, and calls you out when you wander — like a friend sitting next to you. Then verifies you actually finished.
        </p>
        <div className="mt-8 flex flex-wrap gap-3">
          <Link href="/download" className="btn-primary">Download for macOS →</Link>
          <Link href="/pricing" className="btn-secondary">See pricing</Link>
        </div>
        <p className="mt-3 text-xs text-ink/50">7-day free trial · No card required · macOS 14+</p>
      </section>

      <section className="grid md:grid-cols-3 gap-4 pb-20">
        <Feature
          title="It watches your screen."
          body="ScreenCaptureKit + Claude vision classifies what you're doing every second. Local until it hits Anthropic — never sent to us."
        />
        <Feature
          title="It calls you out."
          body="Drift to Twitter? The notch lights up: yo, what are you doing? Not a notification — a friend."
        />
        <Feature
          title="It blocks the rest."
          body="Distracting sites go into /etc/hosts the moment your session starts. Want one back? Argue with Adia."
        />
        <Feature
          title="It verifies the finish."
          body="Tap Done. Adia looks at your screen and checks against the success criteria you set. Submission receipt? Verified. Vibes? Not verified."
        />
        <Feature
          title="It lives in the notch."
          body="No browser tab, no second window. Click the dot to expand. Click away to collapse."
        />
        <Feature
          title="You own your key."
          body="Bring your Anthropic API key. We never see your screen, your task, or your usage. Costs scale with your work, not our pricing."
        />
      </section>

      {/* Demo / how-it-works */}
      <section className="pb-20">
        <h2 className="text-3xl font-semibold tracking-tight">A session, end to end.</h2>
        <p className="mt-2 text-ink/70 max-w-xl">
          Four steps. About a second of friction. Then you're locked in.
        </p>
        <ol className="mt-8 grid md:grid-cols-2 gap-4">
          <Step
            n={1}
            title="Click the notch."
            body="The pill expands. Type the task — 'write ENGL 101 essay'. Type the proof — 'submit to Canvas'. Hit Go."
          />
          <Step
            n={2}
            title="Distractions disappear."
            body="Default blocklist drops into /etc/hosts. Twitter, Reddit, YouTube, TikTok — all served the 'get back to work' page."
          />
          <Step
            n={3}
            title="Wander, get called out."
            body="After two off-task frames, the notch lights up: yo, what are you doing? Soft enough to ignore, sharp enough to sting."
          />
          <Step
            n={4}
            title="Done? Adia checks."
            body="Tap Done. Last screenshot goes to Claude with your success criteria. Submission page on screen? Verified. Vibes? Try again."
          />
        </ol>
      </section>

      <section className="rounded-2xl bg-ink text-paper p-10 md:p-14 mb-12">
        <h2 className="text-3xl font-semibold tracking-tight">Built for the next hour.</h2>
        <p className="mt-4 text-paper/80 max-w-xl">
          Adia is for the essay due tonight, the deck due tomorrow, the launch due Friday. Not a productivity philosophy — a punch list.
        </p>
        <Link href="/download" className="btn-primary mt-8 bg-paper text-ink">
          Get Adia →
        </Link>
      </section>
    </>
  );
}

function Feature({ title, body }: { title: string; body: string }) {
  return (
    <div className="card">
      <h3 className="font-semibold">{title}</h3>
      <p className="mt-2 text-sm text-ink/70">{body}</p>
    </div>
  );
}

function Step({ n, title, body }: { n: number; title: string; body: string }) {
  return (
    <li className="card flex gap-4">
      <div className="text-3xl font-semibold text-ink/30 leading-none">{n}</div>
      <div>
        <h3 className="font-semibold">{title}</h3>
        <p className="mt-1 text-sm text-ink/70">{body}</p>
      </div>
    </li>
  );
}
