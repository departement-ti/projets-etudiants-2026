/**
 * Subscription expiry job.
 *
 * Runs on an interval to keep the database consistent with wall-clock time.
 * Marks ACTIVE memberships as EXPIRED when their latest subscription has
 * passed its end date — so the DB state matches what checkCommunityAccess
 * already enforces at request time.
 *
 * Only processes SUBSCRIPTION-model communities; FREE, FREEMIUM, and ONE_TIME
 * communities are not affected.
 */

import { prisma } from "../database/db.js";
import { sendExpiryReminderEmail } from "../utils/email.utils.js";
import { createNotification } from "../services/notification.service.js";

const INTERVAL_MS = 60 * 60 * 1000; // run every hour

// Send a reminder exactly once: when the subscription end falls within the next
// job-run window (1 hour). We target memberships expiring ~3 days out so the
// window is [now+3days, now+3days+1hour]. Each membership crosses this window
// exactly once, so users receive exactly one reminder email.
const REMINDER_LEAD_MS = 3 * 24 * 60 * 60 * 1000; // 3 days

async function sendExpiryReminders(now: Date): Promise<void> {
  const windowStart = new Date(now.getTime() + REMINDER_LEAD_MS);
  const windowEnd = new Date(now.getTime() + REMINDER_LEAD_MS + INTERVAL_MS);

  const upcoming = await prisma.membership.findMany({
    where: {
      status: "ACTIVE",
      role: "member", // creators and admins never receive expiry reminders
      community: { pricingModel: "SUBSCRIPTION" },
      subscriptions: {
        some: {
          paymentStatus: "SUCCESS",
          subscriptionEnd: { gte: windowStart, lt: windowEnd },
        },
      },
    },
    select: {
      userId: true,
      communityId: true,
      community: { select: { name: true } },
      user: { select: { email: true, firstname: true } },
      subscriptions: {
        where: { paymentStatus: "SUCCESS" },
        orderBy: { createdAt: "desc" },
        take: 1,
        select: { subscriptionEnd: true },
      },
    },
  });

  for (const m of upcoming) {
    const expiryDate = m.subscriptions[0]?.subscriptionEnd;
    if (!expiryDate) continue;
    sendExpiryReminderEmail(m.user.email, m.user.firstname, m.community.name, expiryDate).catch(
      (err) => console.error("[expiry-job] Failed to send reminder email:", err)
    );
    createNotification({
      userId: m.userId,
      type: "SUBSCRIPTION_EXPIRING",
      title: "Subscription expiring soon",
      body: `Your subscription to ${m.community.name} expires in 3 days`,
      link: `/communities/${m.communityId}/subscription`,
    }).catch(() => {});
  }

  if (upcoming.length > 0) {
    console.log(`[expiry-job] Sent ${upcoming.length} expiry reminder(s)`);
  }
}

export async function runExpiryJob(): Promise<void> {
  const now = new Date();

  // Heal any creator/admin memberships that were wrongly set to EXPIRED before
  // the role filter was added to this job.
  const healed = await prisma.membership.updateMany({
    where: { role: { in: ["creator", "admin"] }, status: "EXPIRED" },
    data: { status: "ACTIVE" },
  });
  if (healed.count > 0) {
    console.log(`[expiry-job] Reactivated ${healed.count} creator/admin membership(s) that were wrongly expired`);
  }

  // Load all ACTIVE memberships in SUBSCRIPTION communities.
  // Fetching the latest subscription per membership lets us decide in JS
  // rather than writing a complex subquery, which is acceptable for V0.
  const activeMemberships = await prisma.membership.findMany({
    where: {
      status: "ACTIVE",
      role: "member", // creators and admins are never subject to expiry
      community: { pricingModel: "SUBSCRIPTION" },
    },
    select: {
      id: true,
      userId: true,
      communityId: true,
      community: { select: { name: true } },
      subscriptions: {
        orderBy: { createdAt: "desc" },
        take: 1,
        select: {
          paymentStatus: true,
          subscriptionEnd: true,
        },
      },
    },
  });

  const toExpire = activeMemberships.filter(({ subscriptions }) => {
    const latest = subscriptions[0];
    if (!latest || latest.paymentStatus !== "SUCCESS") return true;
    if (latest.subscriptionEnd && latest.subscriptionEnd < now) return true;
    return false;
  });

  const toExpireIds = toExpire.map(({ id }) => id);

  await sendExpiryReminders(now);

  if (toExpireIds.length === 0) return;

  await prisma.membership.updateMany({
    where: { id: { in: toExpireIds } },
    data: { status: "EXPIRED" },
  });

  // In-app notification for each expired member
  for (const m of toExpire) {
    createNotification({
      userId: m.userId,
      type: "SUBSCRIPTION_EXPIRED",
      title: "Subscription expired",
      body: `Your subscription to ${m.community.name} has expired`,
      link: `/communities/${m.communityId}/subscription`,
    }).catch(() => {});
  }

  console.log(`[expiry-job] Marked ${toExpireIds.length} membership(s) as EXPIRED`);
}

export function startExpiryJob(): void {
  runExpiryJob().catch((err) =>
    console.error("[expiry-job] Error on startup run:", err)
  );

  setInterval(() => {
    runExpiryJob().catch((err) =>
      console.error("[expiry-job] Error:", err)
    );
  }, INTERVAL_MS);
}
