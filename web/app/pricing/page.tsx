import Link from 'next/link';

const plans = [
  {
    id: 'monthly',
    name: 'Monthly',
    price: '$7',
    cadence: '/month',
    highlight: false,
    features: ['Full Adia Pro', 'Cancel anytime', 'Email support'],
  },
  {
    id: 'yearly',
    name: 'Yearly',
    price: '$59',
    cadence: '/year',
    highlight: true,
    badge: 'Save 30%',
    features: ['Full Adia Pro', '2 months free vs monthly', 'Priority email support'],
  },
  {
    id: 'lifetime',
    name: 'Lifetime',
    price: '$149',
    cadence: 'one time',
    highlight: false,
    badge: 'Early bird — first 500',
    features: ['Adia Pro forever', 'All future v1 updates', 'Founder Discord'],
  },
];

export default function Pricing() {
  return (
    <section className="pt-12 pb-20">
      <h1 className="text-4xl md:text-5xl font-semibold tracking-tight">Pricing</h1>
      <p className="mt-3 text-ink/70 max-w-xl">
        7-day free trial, no card required. Then $7/mo, $59/yr, or buy once.
      </p>

      <div className="grid md:grid-cols-3 gap-4 mt-10">
        {plans.map((p) => (
          <div
            key={p.id}
            className={`card ${p.highlight ? 'ring-2 ring-accent' : ''} flex flex-col`}
          >
            <div className="flex items-baseline justify-between">
              <h2 className="text-xl font-semibold">{p.name}</h2>
              {p.badge && (
                <span className="text-xs bg-accent/10 text-accent rounded-full px-2 py-0.5">
                  {p.badge}
                </span>
              )}
            </div>
            <div className="mt-4 text-4xl font-semibold">
              {p.price}
              <span className="text-base font-normal text-ink/60 ml-1">{p.cadence}</span>
            </div>
            <ul className="mt-6 space-y-2 text-sm text-ink/80 flex-1">
              {p.features.map((f) => (
                <li key={f}>· {f}</li>
              ))}
            </ul>
            <Link
              href={`/api/checkout?plan=${p.id}`}
              className={`mt-6 ${p.highlight ? 'btn-primary' : 'btn-secondary'} justify-center`}
            >
              Buy {p.name}
            </Link>
          </div>
        ))}
      </div>

      <div className="mt-10 text-sm text-ink/60 max-w-2xl">
        <p>
          <strong>Bring-your-own OpenAI API key.</strong> Adia uses OpenAI vision models to watch your screen. You pay OpenAI directly for usage — typical sessions cost a few cents. We never charge you for inference.
        </p>
        <p className="mt-3">
          <strong>Refunds:</strong> 14 days for subscriptions, 30 days for lifetime. Email{' '}
          <a href="mailto:support@adia.app">support@adia.app</a>.
        </p>
        <p className="mt-3">
          <strong>Students:</strong> 50% off with .edu email. Email us for a code.
        </p>
      </div>

      <FAQ />
    </section>
  );
}

function FAQ() {
  const items = [
    {
      q: 'How much does OpenAI usage cost me?',
      a: 'Typical sessions run a few cents of OpenAI usage. A heavy day of deep work may cost more depending on model pricing and session length. You pay OpenAI directly — we don\'t mark it up.',
    },
    {
      q: 'Can I share a license across my Mac and my laptop?',
      a: 'Yes. Each license activates on up to 3 of your personal machines. If you switch hardware, email support@adia.app and we\'ll reset a seat.',
    },
    {
      q: 'What happens at the end of the 7-day trial?',
      a: 'Adia stops starting new sessions until you enter a license. We never auto-charge — there\'s no card on file during the trial.',
    },
    {
      q: 'What if Adia falsely verifies my work as done?',
      a: 'Tell us and we\'ll refund the session\'s worth of trust. The model is strict by default and looks for concrete evidence (submission pages, file metadata, timestamps). It\'s wrong sometimes — it\'s a tool, not a judge.',
    },
    {
      q: 'Does Adia work without a notch?',
      a: 'Yes — on any macOS 14+ Mac the panel sits at the top of the screen where the notch would be. It just looks nicest on a notched MacBook.',
    },
    {
      q: 'Windows?',
      a: 'Not yet. On the roadmap once we hit 1,000 paying users.',
    },
    {
      q: 'Will you train on my screen?',
      a: 'No. We never see your screen — it goes from your Mac directly to OpenAI\'s API with your key. We have no server you could leak to.',
    },
    {
      q: 'Can I cancel anytime?',
      a: 'Yes. Use /billing to open the Stripe portal. Lifetime is, well, lifetime — no need to cancel.',
    },
  ];
  return (
    <div className="mt-16 max-w-2xl">
      <h2 className="text-2xl font-semibold tracking-tight">Questions</h2>
      <div className="mt-6 space-y-3">
        {items.map((it) => (
          <details key={it.q} className="card group">
            <summary className="cursor-pointer font-medium list-none flex justify-between items-center">
              <span>{it.q}</span>
              <span className="text-ink/40 group-open:rotate-45 transition">+</span>
            </summary>
            <p className="mt-3 text-sm text-ink/70">{it.a}</p>
          </details>
        ))}
      </div>
    </div>
  );
}
