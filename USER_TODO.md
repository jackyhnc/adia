# Jacky's to-do list (manual steps the build agent can't do)

Everything in this file requires accounts you need to create or actions you need to take yourself. Once these are done, the rest of the stack is automated.

## 1. Accounts (~30 min, $99/yr upfront)

- [ ] Apple Developer Program — apply at developer.apple.com ($99/yr). Approval can take 24-48h.
- [ ] Stripe — sign up, set business details, request live mode.
- [ ] Resend — sign up, free tier is fine.
- [ ] Vercel — sign up with your GitHub.
- [ ] Cloudflare — sign up, add `adia.app` (or whatever domain).
- [ ] Buy `adia.app` (or your domain of choice).

## 2. Apple signing certs (~15 min, after Apple approves you)

- [ ] In Xcode → Settings → Accounts → add your Apple ID → Manage Certificates → "+" → **Developer ID Application**.
- [ ] Export the cert from Keychain Access as `.p12` (with a strong password). Keep it safe.
- [ ] Generate an **app-specific password** at appleid.apple.com → Sign-In and Security → App-Specific Passwords. Label it "notarytool". Save it.
- [ ] Grab your Team ID from developer.apple.com → Membership.

## 3. Stripe products (~10 min)

In the Stripe dashboard, create three products:
- [ ] **Adia Pro Monthly** — recurring, $7/mo
- [ ] **Adia Pro Yearly** — recurring, $59/yr
- [ ] **Adia Pro Lifetime** — one-time, $149

Copy the **price ID** (starts with `price_`) for each.

Then create a webhook:
- [ ] Endpoint: `https://adia.app/api/stripe/webhook`
- [ ] Events: `checkout.session.completed`, `customer.subscription.deleted`
- [ ] Copy the signing secret (starts with `whsec_`).

## 4. Resend (~5 min)

- [ ] Add domain `adia.app`, add the SPF/DKIM records Resend gives you in Cloudflare.
- [ ] Wait ~10 min for verification.
- [ ] Generate an API key.

## 5. Deploy the website (~10 min)

```bash
cd web
npm install
vercel deploy --prod
vercel domains add adia.app
```

In Vercel project settings, add env vars from `web/.env.example` filled in with values from steps 3 + 4.

## 6. GitHub Actions secrets (~5 min)

In your GitHub repo → Settings → Secrets → Actions, add:

- `DEVELOPER_ID_APPLICATION` — `"Developer ID Application: Your Name (TEAMID)"`
- `APPLE_ID` — your Apple ID email
- `APPLE_TEAM_ID` — 10-char team ID
- `APPLE_APP_PASSWORD` — the app-specific password from step 2
- `MAC_CERT_P12_BASE64` — `base64 -i Certificates.p12 | pbcopy`
- `MAC_CERT_PASSWORD` — the password you used when exporting

## 7. Cut the first release

```bash
git tag v0.1.0
git push --tags
```

GitHub Actions builds, signs, notarizes, packages, and creates a Release with the DMG attached. `adia.app/download` reads the latest GitHub release automatically.

## 8. Manual buyer test (~5 min)

- [ ] Buy each plan with a Stripe test card (`4242 4242 4242 4242`, any future date, any CVC).
- [ ] Confirm the license email arrives.
- [ ] Activate in the app.
- [ ] Refund the test purchases in Stripe.

## 9. Launch

- [ ] Tweet/X
- [ ] Reddit r/macapps, r/productivity, r/getdisciplined
- [ ] Show HN
- [ ] Schedule Product Hunt for the following Tuesday

## Always

- [ ] Your `OPENAI_API_KEY` is your responsibility — Adia bills nothing for inference, you pay OpenAI directly.
- [ ] Screen Recording + Accessibility permissions get granted by each user on first launch.
