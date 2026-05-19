# Adia web — marketing + license API

Next.js 14 app. One deployable serves the landing page, pricing, download, legal pages, and the license/billing API.

## Local dev

```bash
cd web
npm install
cp .env.example .env.local        # fill in what you have, leave the rest blank
npm run dev                       # http://localhost:3000
```

The site works without any keys — `/pricing` shows the plans, `/api/checkout` redirects back to `/pricing?stripe=unconfigured` until you set Stripe envs.

## Deploy

```bash
npm i -g vercel
vercel deploy --prod
```

Set these env vars in the Vercel project:

| Var | Required? | Notes |
|---|---|---|
| `STRIPE_SECRET_KEY` | for payments | from Stripe dashboard |
| `STRIPE_WEBHOOK_SECRET` | for payments | from Stripe webhook setup |
| `STRIPE_PRICE_MONTHLY` | for payments | price ID, recurring $7/mo |
| `STRIPE_PRICE_YEARLY` | for payments | price ID, recurring $59/yr |
| `STRIPE_PRICE_LIFETIME` | for payments | price ID, one-time $149 |
| `RESEND_API_KEY` | for email | from resend.com |
| `RESEND_FROM` | optional | `Adia <hello@adia.app>` |
| `LICENSE_DB_PATH` | optional | only for self-hosting; on Vercel switch to Postgres |

### Switching off SQLite

`lib/db.ts` uses `better-sqlite3` for v1. On Vercel that won't persist across deploys. For production:

1. Create a Neon Postgres in Vercel.
2. Replace the queries in `lib/db.ts` with `@vercel/postgres` (already in `package.json`).
3. Run the schema (see top of `db.ts`).

## Stripe setup

1. Create 3 products in Stripe: Monthly ($7), Yearly ($59), Lifetime ($149).
2. Copy the price IDs into `STRIPE_PRICE_*`.
3. Add a webhook endpoint pointing at `https://adia.app/api/stripe/webhook` listening for `checkout.session.completed` and `customer.subscription.deleted`.
4. Copy the signing secret into `STRIPE_WEBHOOK_SECRET`.

## Resend setup

1. Add domain `adia.app` in Resend.
2. Verify DNS.
3. Drop the API key into `RESEND_API_KEY`.
