import nodemailer from "nodemailer";
import { EMAIL_HOST, EMAIL_PORT, EMAIL_USER, EMAIL_PASS, EMAIL_FROM, CLIENT_URL, NODE_ENV } from "../config/env.js";

// ─── Transporter ──────────────────────────────────────────────────────────────

function createTransporter() {
  if (!EMAIL_HOST || !EMAIL_USER || !EMAIL_PASS) return null;
  return nodemailer.createTransport({
    host: EMAIL_HOST,
    port: EMAIL_PORT,
    secure: EMAIL_PORT === 465,
    auth: { user: EMAIL_USER, pass: EMAIL_PASS },
    tls: { rejectUnauthorized: false },
  });
}

async function sendMail(to: string, subject: string, html: string, devUrl?: string): Promise<void> {
  const transporter = createTransporter();

  if (!transporter) {
    if (NODE_ENV !== "production") {
      console.log("\n" + "─".repeat(60));
      console.log(`📧  [DEV EMAIL]  To: ${to}`);
      console.log(`    Subject: ${subject}`);
      if (devUrl) console.log(`\n    👉  COPY THIS URL:\n    ${devUrl}\n`);
      console.log("─".repeat(60) + "\n");
      return;
    }
    throw new Error("Email transport is not configured.");
  }

  await transporter.sendMail({ from: EMAIL_FROM, to, subject, html });
}

// ─── Shared layout ────────────────────────────────────────────────────────────

function layout(content: string): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>OnePlace</title>
</head>
<body style="margin:0;padding:0;background-color:#f4f4f7;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f4f7;padding:40px 16px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" style="max-width:580px;">

          <!-- Header -->
          <tr>
            <td align="center" style="padding-bottom:24px;">
              <span style="font-size:22px;font-weight:800;color:#6d28d9;letter-spacing:-0.5px;">OnePlace</span>
            </td>
          </tr>

          <!-- Card -->
          <tr>
            <td style="background:#ffffff;border-radius:12px;padding:40px 40px 32px;box-shadow:0 1px 3px rgba(0,0,0,0.08);">
              ${content}
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding-top:24px;">
              <p style="margin:0;font-size:12px;color:#9ca3af;">
                © ${new Date().getFullYear()} OnePlace · You received this email because you have an account with us.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>`
}

function button(label: string, url: string): string {
  return `<a href="${url}" style="display:inline-block;margin-top:24px;padding:13px 28px;background-color:#6d28d9;color:#ffffff;text-decoration:none;border-radius:8px;font-size:15px;font-weight:600;">${label}</a>`
}

function heading(text: string): string {
  return `<h1 style="margin:0 0 16px;font-size:22px;font-weight:700;color:#111827;">${text}</h1>`
}

function paragraph(text: string): string {
  return `<p style="margin:0 0 12px;font-size:15px;line-height:1.6;color:#374151;">${text}</p>`
}

function note(text: string): string {
  return `<p style="margin:20px 0 0;font-size:13px;color:#9ca3af;">${text}</p>`
}

function divider(): string {
  return `<hr style="margin:24px 0;border:none;border-top:1px solid #e5e7eb;" />`
}

function infoRow(label: string, value: string): string {
  return `<tr>
    <td style="padding:8px 0;font-size:14px;color:#6b7280;width:140px;">${label}</td>
    <td style="padding:8px 0;font-size:14px;color:#111827;font-weight:500;">${value}</td>
  </tr>`
}

// ─── Templates ────────────────────────────────────────────────────────────────

export async function sendVerificationEmail(to: string, token: string): Promise<void> {
  const link = `${CLIENT_URL}/verify-email?token=${token}`
  const html = layout(`
    ${heading("Verify your email address")}
    ${paragraph("Thanks for signing up for OnePlace! Please confirm your email address to activate your account and start exploring communities.")}
    <div style="text-align:center;">
      ${button("Verify Email Address", link)}
    </div>
    ${divider()}
    ${note("This link expires in 24 hours. If you didn't create an account, you can safely ignore this email.")}
  `)
  await sendMail(to, "Verify your OnePlace account", html, link)
}

export async function sendPasswordResetEmail(to: string, token: string): Promise<void> {
  const link = `${CLIENT_URL}/reset-password?token=${token}`
  const html = layout(`
    ${heading("Reset your password")}
    ${paragraph("We received a request to reset the password for your OnePlace account. Click the button below to choose a new password.")}
    <div style="text-align:center;">
      ${button("Reset Password", link)}
    </div>
    ${divider()}
    ${note("This link expires in 1 hour. If you didn't request a password reset, please ignore this email — your account is safe.")}
  `)
  await sendMail(to, "Reset your OnePlace password", html, link)
}

export async function sendWelcomeEmail(to: string, firstname: string): Promise<void> {
  const html = layout(`
    ${heading(`Welcome aboard, ${firstname}! 🎉`)}
    ${paragraph("Your email has been verified and your OnePlace account is ready to go.")}
    ${paragraph("You can now join communities, access courses, connect with creators, and build your own space.")}
    <div style="text-align:center;">
      ${button("Explore Communities", `${CLIENT_URL}/communities`)}
    </div>
    ${divider()}
    ${note("If you have any questions, just reply to this email — we're happy to help.")}
  `)
  await sendMail(to, "Welcome to OnePlace!", html)
}

export async function sendPaymentConfirmationEmail(
  to: string,
  firstname: string,
  communityName: string,
  amount: number,
  billingInterval?: string
): Promise<void> {
  const intervalLabel = billingInterval === "YEARLY" ? "/ year" : billingInterval === "MONTHLY" ? "/ month" : ""
  const html = layout(`
    ${heading("Payment confirmed")}
    ${paragraph(`Hi ${firstname}, your payment was successful and you now have full access to <strong>${communityName}</strong>.`)}
    ${divider()}
    <table width="100%" cellpadding="0" cellspacing="0">
      ${infoRow("Community", communityName)}
      ${infoRow("Amount", `$${amount.toFixed(2)} ${intervalLabel}`)}
      ${infoRow("Status", "✅ Paid")}
    </table>
    ${divider()}
    <div style="text-align:center;">
      ${button("Go to Community", `${CLIENT_URL}/communities`)}
    </div>
    ${note("Keep this email as your payment receipt.")}
  `)
  await sendMail(to, `Payment confirmed — ${communityName}`, html)
}

export async function sendExpiryReminderEmail(
  to: string,
  firstname: string,
  communityName: string,
  expiryDate: Date
): Promise<void> {
  const formatted = expiryDate.toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  })
  const html = layout(`
    ${heading("Your subscription is expiring soon")}
    ${paragraph(`Hi ${firstname}, your subscription to <strong>${communityName}</strong> expires on <strong>${formatted}</strong>.`)}
    ${paragraph("Renew now to keep access to all content, courses, and community features without interruption.")}
    <div style="text-align:center;">
      ${button("Renew Subscription", `${CLIENT_URL}/communities`)}
    </div>
    ${divider()}
    ${note("If you no longer wish to renew, no action is needed — your access will end on the expiry date.")}
  `)
  await sendMail(to, `Your ${communityName} subscription expires soon`, html)
}
