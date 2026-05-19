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
          <strong>Bring-your-own Anthropic API key.</strong> Adia uses Claude (Anthropic) to watch your screen. You pay Anthropic directly for usage — typical sessions cost a few cents. We never charge you for inference.
        </p>
        <p className="mt-3">
          <strong>Refunds:</strong> 14 days for subscriptions, 30 days for lifetime. Email{' '}
          <a href="mailto:support@adia.app">support@adia.app</a>.
        </p>
        <p className="mt-3">
          <strong>Students:</strong> 50% off with .edu email. Email us for a code.
        </p>
      </div>
    </section>
  );
}
