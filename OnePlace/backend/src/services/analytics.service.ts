import { prisma } from "../database/db.js";
import { AppError } from "../utils/AppError.js";

// ─── Helpers ───────────────────────────────────────────────────────────────────

function toMonthKey(date: Date): string {
  return date.toISOString().slice(0, 7); // e.g. "2026-04"
}

function last6MonthKeys(): string[] {
  const keys: string[] = [];
  const now = new Date();
  for (let i = 5; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    keys.push(toMonthKey(d));
  }
  return keys;
}

function groupByMonth<T>(
  items: T[],
  getDate: (item: T) => Date,
  getValue: (item: T) => number = () => 1
): Array<{ month: string; value: number }> {
  const months = last6MonthKeys();
  const map: Record<string, number> = Object.fromEntries(months.map((m) => [m, 0]));

  for (const item of items) {
    const key = toMonthKey(getDate(item));
    if (key in map) map[key] = (map[key] ?? 0) + getValue(item);
  }

  return months.map((month) => ({ month, value: map[month] ?? 0 }));
}

// ─── Community Analytics ───────────────────────────────────────────────────────
// Accessible by the community creator and admins.

export async function getCommunityAnalytics(communityId: string, requesterId: string) {
  const community = await prisma.community.findUnique({
    where: { id: communityId },
    select: { id: true, name: true, pricingModel: true, platformPlan: true, creatorId: true },
  });

  if (!community) throw new AppError("Community not found", 404);

  const requesterMembership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId: requesterId, communityId } },
  });

  if (
    !requesterMembership ||
    !["creator", "admin"].includes(requesterMembership.role)
  ) {
    throw new AppError("Only creators and admins can view analytics", 403);
  }

  // Fetch all memberships with their subscriptions
  const memberships = await prisma.membership.findMany({
    where: { communityId },
    select: {
      status: true,
      membershipTier: true,
      joinedAt: true,
      subscriptions: {
        where: { paymentStatus: "SUCCESS" },
        select: { pricePaid: true, billingInterval: true, createdAt: true },
      },
    },
  });

  // ── Member stats ──────────────────────────────────────────────────────────────
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

  const byStatus: Record<string, number> = {};
  const byTier: Record<string, number> = {};
  let newThisMonth = 0;

  for (const m of memberships) {
    byStatus[m.status] = (byStatus[m.status] ?? 0) + 1;
    byTier[m.membershipTier] = (byTier[m.membershipTier] ?? 0) + 1;
    if (m.joinedAt >= startOfMonth) newThisMonth++;
  }

  const memberGrowth = groupByMonth(memberships, (m) => m.joinedAt);

  // ── Revenue stats ─────────────────────────────────────────────────────────────
  const allSubs = memberships.flatMap((m) => m.subscriptions);

  const totalRevenue = allSubs.reduce((sum, s) => sum + Number(s.pricePaid), 0);

  const revenueThisMonth = allSubs
    .filter((s) => s.createdAt >= startOfMonth)
    .reduce((sum, s) => sum + Number(s.pricePaid), 0);

  const revenueGrowth = groupByMonth(
    allSubs,
    (s) => s.createdAt,
    (s) => Number(s.pricePaid)
  );

  const revenueByInterval: Record<string, number> = {};
  for (const s of allSubs) {
    const key = s.billingInterval ?? "ONE_TIME";
    revenueByInterval[key] = (revenueByInterval[key] ?? 0) + Number(s.pricePaid);
  }

  return {
    community: {
      id: community.id,
      name: community.name,
      pricingModel: community.pricingModel,
      platformPlan: community.platformPlan,
    },
    members: {
      total: memberships.length,
      active: byStatus["ACTIVE"] ?? 0,
      byStatus,
      byTier,
      newThisMonth,
      growthLast6Months: memberGrowth,
    },
    revenue: {
      total: totalRevenue,
      thisMonth: revenueThisMonth,
      last6Months: revenueGrowth,
      byInterval: revenueByInterval,
    },
  };
}

// ─── Platform Analytics ────────────────────────────────────────────────────────
// Accessible by platform moderators only (enforced in the route via requireRole).

export async function getPlatformAnalytics() {
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

  const [users, communities, subscriptions] = await Promise.all([
    prisma.user.findMany({
      select: { isVerified: true, isSuspended: true, createdAt: true },
    }),
    prisma.community.findMany({
      select: {
        createdAt: true,
        memberships: { where: { status: "ACTIVE" }, select: { id: true }, take: 1 },
      },
    }),
    prisma.subscription.findMany({
      where: { paymentStatus: "SUCCESS" },
      select: { pricePaid: true, createdAt: true, billingInterval: true },
    }),
  ]);

  // ── User stats ────────────────────────────────────────────────────────────────
  const newUsersThisMonth = users.filter((u) => u.createdAt >= startOfMonth).length;
  const verifiedUsers = users.filter((u) => u.isVerified).length;
  const suspendedUsers = users.filter((u) => u.isSuspended).length;

  const userGrowth = groupByMonth(users, (u) => u.createdAt);

  // ── Community stats ───────────────────────────────────────────────────────────
  const activeCommunities = communities.filter((c) => c.memberships.length > 0).length;
  const newCommunitiesThisMonth = communities.filter((c) => c.createdAt >= startOfMonth).length;

  const communityGrowth = groupByMonth(communities, (c) => c.createdAt);

  // ── Revenue stats ─────────────────────────────────────────────────────────────
  const totalRevenue = subscriptions.reduce((sum, s) => sum + Number(s.pricePaid), 0);
  const revenueThisMonth = subscriptions
    .filter((s) => s.createdAt >= startOfMonth)
    .reduce((sum, s) => sum + Number(s.pricePaid), 0);

  const revenueGrowth = groupByMonth(
    subscriptions,
    (s) => s.createdAt,
    (s) => Number(s.pricePaid)
  );

  const revenueByInterval: Record<string, number> = {};
  for (const s of subscriptions) {
    const key = s.billingInterval ?? "ONE_TIME";
    revenueByInterval[key] = (revenueByInterval[key] ?? 0) + Number(s.pricePaid);
  }

  return {
    users: {
      total: users.length,
      verified: verifiedUsers,
      suspended: suspendedUsers,
      newThisMonth: newUsersThisMonth,
      growthLast6Months: userGrowth,
    },
    communities: {
      total: communities.length,
      active: activeCommunities,
      newThisMonth: newCommunitiesThisMonth,
      growthLast6Months: communityGrowth,
    },
    revenue: {
      total: totalRevenue,
      thisMonth: revenueThisMonth,
      last6Months: revenueGrowth,
      byInterval: revenueByInterval,
    },
  };
}
