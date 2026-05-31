# Deploy Adia

What it takes to go from "swift build works" to "users can pay and download."

## 0. One-time accounts

| Service | Why | Cost |
|---|---|---|
| Apple Developer Program | Code-sign + notarize the macOS app | $99/yr |
| Stripe | Payments | 2.9% + 30¢ per transaction |
| Resend | License delivery email | Free up to 3k/mo |
| Vercel | Host `adia.app` + license API | Free tier fine |
| Cloudflare | DNS for `adia.app` | Free |
| GitHub | Code + release artifacts | Free |

## 1. Domain + DNS (Cloudflare)

1. Buy `adia.app` (or hand-me-down).
2. Point nameservers to Cloudflare.
3. Add an `A` record `@` → Vercel anycast IP (Vercel will give you one).
4. Add CNAME `www` → `cname.vercel-dns.com`.
5. Verify domain on Resend, add the suggested SPF / DKIM records.

## 2. Web app (Vercel)

```bash
cd web
npm install
cp .env.example .env.local        # leave everything blank for now
npm run dev                       # sanity check at localhost:3000

npm i -g vercel
vercel login
vercel link                       # create a new Vercel project
vercel deploy --prod              # first deploy — your URL appears
vercel domains add adia.app       # attach the domain
```

Set env vars in Vercel dashboard (`Settings → Environment Variables`). For the first deploy you can ship with everything blank — landing/pricing/legal pages all work; payment falls back to a "coming soon" state.

When you're ready to take money:

1. Create Stripe products: Monthly ($7/mo), Yearly ($59/yr), Lifetime ($149 one-time).
2. Copy each price ID into `STRIPE_PRICE_MONTHLY` / `_YEARLY` / `_LIFETIME`.
3. In Stripe → Developers → Webhooks → add endpoint `https://adia.app/api/stripe/webhook` listening for `checkout.session.completed` and `customer.subscription.deleted`. Copy the signing secret into `STRIPE_WEBHOOK_SECRET`.
4. Paste your Stripe secret key (`STRIPE_SECRET_KEY`).
5. Paste your Resend key (`RESEND_API_KEY`).
6. Redeploy.

> SQLite on Vercel doesn't persist across deploys. For production, swap `lib/db.ts` to use `@vercel/postgres` + a Neon Postgres add-on. The schema at the top of the file is portable.

## 3. macOS app: signing + notarization

You need:
- An Apple Developer account.
- A **Developer ID Application** certificate (Xcode → Settings → Accounts → Manage Certificates → +).
- An app-specific password from appleid.apple.com (Sign-In and Security → App-Specific Passwords).

### Local

```bash
export DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)"
export APPLE_ID="you@example.com"
export APPLE_TEAM_ID="TEAMID"
export APPLE_APP_PASSWORD="abcd-efgh-ijkl-mnop"

VERSION=0.1.0 scripts/release.sh
# → dist/Adia-0.1.0.dmg
```

Production releases fail fast if signing or notarization credentials are missing. For a private local test DMG only, you can set `ADIA_ALLOW_UNSIGNED_RELEASE=1`; do not upload that artifact to GitHub releases or distribute it to users.

### CI (GitHub Actions)

Add these repository secrets:

| Secret | Value |
|---|---|
| `DEVELOPER_ID_APPLICATION` | `Developer ID Application: Your Name (TEAMID)` |
| `APPLE_ID` | your Apple ID email |
| `APPLE_TEAM_ID` | your team ID (10 chars) |
| `APPLE_APP_PASSWORD` | app-specific password |
| `MAC_CERT_P12_BASE64` | `base64 -i Certificates.p12` (export from Keychain) |
| `MAC_CERT_PASSWORD` | the password you set when exporting |

Then:

```bash
git tag v0.1.0
git push --tags
```

Actions will build, sign, notarize, package, and publish a GitHub Release with the `.dmg` attached. The Vercel `/download` page reads the latest GitHub release and surfaces the link automatically.

## 4. Launch checklist

- [ ] Apple Developer account paid up
- [ ] Domain `adia.app` resolves, HTTPS works
- [ ] `/pricing` shows three plans
- [ ] Buy each plan with a Stripe test card → license email arrives → activates in app
- [ ] Refund the test purchases in Stripe
- [ ] `/download` shows the latest .dmg from GitHub
- [ ] Install the .dmg on a clean Mac → no Gatekeeper warning → onboarding flow works
- [ ] Submit Show HN, post on Reddit r/macapps, Twitter, schedule Product Hunt
- [ ] Open support@adia.app, privacy@adia.app, legal@adia.app aliases

## 5. Day 2

- Switch SQLite → Postgres (`lib/db.ts`)
- Add PostHog (or Plausible) for site analytics
- Add Sentry for app crash reports (opt-in)
- Set up Stripe Billing customer portal at `/billing`
- Build a tiny admin page for license lookup at `/admin` (NextAuth or basic-auth)
