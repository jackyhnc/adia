import { Resend } from 'resend';

const apiKey = process.env.RESEND_API_KEY;
const from = process.env.RESEND_FROM ?? 'Adia <hello@adia.app>';

export async function sendPaymentFailedEmail(to: string, key: string, plan: string) {
  if (!apiKey) {
    console.log('[email] RESEND_API_KEY not set; would have sent payment failed:', { to, key, plan });
    return;
  }
  const resend = new Resend(apiKey);
  await resend.emails.send({
    from,
    to,
    subject: 'Adia — payment failed',
    html: `
      <p>Hey — your Adia ${plan} payment failed.</p>
      <p>Your license (<code>${key}</code>) has been paused. Update your payment method to restore access.</p>
      <p><a href="https://adia.app/billing">Update payment method →</a></p>
      <p>If you think this is a mistake, reply to this email.</p>
      <p>— The Adia team</p>
    `,
    text: `Your Adia ${plan} payment failed.\nYour license (${key}) has been paused.\nUpdate your payment: https://adia.app/billing`,
  });
}

export async function sendLicenseEmail(to: string, key: string, plan: string) {
  if (!apiKey) {
    console.log('[email] RESEND_API_KEY not set; would have sent:', { to, key, plan });
    return;
  }
  const resend = new Resend(apiKey);
  await resend.emails.send({
    from,
    to,
    subject: `Your Adia license — ${plan}`,
    html: `
      <p>Thanks for buying Adia.</p>
      <p>Your license key is:</p>
      <pre style="font-size:18px;background:#f3f3f3;padding:12px;border-radius:6px;">${key}</pre>
      <p>Open Adia, click the notch, and paste it with this email (<b>${to}</b>).</p>
      <p>Plan: <b>${plan}</b></p>
      <p>If you don't have Adia yet: <a href="https://adia.app/download">download here</a>.</p>
      <p>— The Adia team</p>
    `,
    text: `Your Adia license: ${key}\nPlan: ${plan}\nDownload: https://adia.app/download`,
  });
}
