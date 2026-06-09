import { describe, it, expect, vi, beforeEach } from "vitest";

vi.mock("../database/db.js", () => ({
  prisma: {
    community: { findUnique: vi.fn(), findMany: vi.fn() },
    membership: { findUnique: vi.fn(), findMany: vi.fn() },
    user: { findMany: vi.fn() },
    subscription: { findMany: vi.fn() },
  },
}));

import { prisma } from "../database/db.js";
import * as analyticsService from "./analytics.service.js";

function makeCommunity(overrides: Record<string, unknown> = {}) {
  return {
    id: "c-1",
    name: "Test Community",
    pricingModel: "SUBSCRIPTION",
    platformPlan: "BASIC",
    creatorId: "creator-1",
    ...overrides,
  };
}

function makeMembership(overrides: Record<string, unknown> = {}) {
  return {
    id: "m-1",
    userId: "user-1",
    communityId: "c-1",
    role: "member",
    status: "ACTIVE",
    membershipTier: "PAID",
    joinedAt: new Date(),
    subscriptions: [],
    ...overrides,
  };
}

// ─── getCommunityAnalytics ────────────────────────────────────────────────────

describe("analyticsService.getCommunityAnalytics", () => {
  beforeEach(() => vi.clearAllMocks());

  it("returns analytics for the community creator", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity() as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(
      makeMembership({ userId: "creator-1", role: "creator" }) as any
    );
    vi.mocked(prisma.membership.findMany).mockResolvedValue([
      makeMembership({ status: "ACTIVE", membershipTier: "PAID", subscriptions: [{ pricePaid: 10, billingInterval: "MONTHLY", createdAt: new Date() }] }),
      makeMembership({ id: "m-2", status: "CANCELLED", membershipTier: "FREE", subscriptions: [] }),
    ] as any);

    const result = await analyticsService.getCommunityAnalytics("c-1", "creator-1");

    expect(result.members.total).toBe(2);
    expect(result.members.active).toBe(1);
    expect(result.members.byStatus["ACTIVE"]).toBe(1);
    expect(result.members.byStatus["CANCELLED"]).toBe(1);
    expect(result.revenue.total).toBe(10);
    expect(result.revenue.byInterval["MONTHLY"]).toBe(10);
    expect(result.members.growthLast6Months).toHaveLength(6);
    expect(result.revenue.last6Months).toHaveLength(6);
  });

  it("returns zero revenue for a community with no payments", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity({ pricingModel: "FREE" }) as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(
      makeMembership({ role: "creator" }) as any
    );
    vi.mocked(prisma.membership.findMany).mockResolvedValue([
      makeMembership({ subscriptions: [] }),
    ] as any);

    const result = await analyticsService.getCommunityAnalytics("c-1", "creator-1");
    expect(result.revenue.total).toBe(0);
    expect(result.revenue.thisMonth).toBe(0);
  });

  it("counts newThisMonth correctly", async () => {
    const now = new Date();
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity() as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(
      makeMembership({ role: "creator" }) as any
    );
    vi.mocked(prisma.membership.findMany).mockResolvedValue([
      makeMembership({ joinedAt: now }), // this month
      makeMembership({ id: "m-2", joinedAt: new Date("2020-01-01") }), // old
    ] as any);

    const result = await analyticsService.getCommunityAnalytics("c-1", "creator-1");
    expect(result.members.newThisMonth).toBe(1);
  });

  it("throws 404 when community does not exist", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(null);
    await expect(
      analyticsService.getCommunityAnalytics("ghost", "creator-1")
    ).rejects.toMatchObject({ statusCode: 404 });
  });

  it("throws 403 when requester is a regular member", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity() as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(
      makeMembership({ role: "member" }) as any
    );
    await expect(
      analyticsService.getCommunityAnalytics("c-1", "user-1")
    ).rejects.toMatchObject({ statusCode: 403 });
  });

  it("throws 403 when requester has no membership", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity() as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(null);
    await expect(
      analyticsService.getCommunityAnalytics("c-1", "stranger")
    ).rejects.toMatchObject({ statusCode: 403 });
  });
});

// ─── getPlatformAnalytics ─────────────────────────────────────────────────────

describe("analyticsService.getPlatformAnalytics", () => {
  beforeEach(() => vi.clearAllMocks());

  it("returns aggregated platform stats", async () => {
    vi.mocked(prisma.user.findMany).mockResolvedValue([
      { isVerified: true, isSuspended: false, createdAt: new Date() },
      { isVerified: false, isSuspended: true, createdAt: new Date("2020-01-01") },
    ] as any);

    vi.mocked(prisma.community.findMany).mockResolvedValue([
      { createdAt: new Date(), memberships: [{ id: "m-1" }] }, // active
      { createdAt: new Date("2020-01-01"), memberships: [] },  // no members
    ] as any);

    vi.mocked(prisma.subscription.findMany).mockResolvedValue([
      { pricePaid: 20, createdAt: new Date(), billingInterval: "MONTHLY" },
      { pricePaid: 50, createdAt: new Date("2020-01-01"), billingInterval: "YEARLY" },
    ] as any);

    const result = await analyticsService.getPlatformAnalytics();

    expect(result.users.total).toBe(2);
    expect(result.users.verified).toBe(1);
    expect(result.users.suspended).toBe(1);
    expect(result.communities.total).toBe(2);
    expect(result.communities.active).toBe(1);
    expect(result.revenue.total).toBe(70);
    expect(result.revenue.byInterval["MONTHLY"]).toBe(20);
    expect(result.revenue.byInterval["YEARLY"]).toBe(50);
    expect(result.users.growthLast6Months).toHaveLength(6);
    expect(result.revenue.last6Months).toHaveLength(6);
  });

  it("returns zeros when no data exists", async () => {
    vi.mocked(prisma.user.findMany).mockResolvedValue([] as any);
    vi.mocked(prisma.community.findMany).mockResolvedValue([] as any);
    vi.mocked(prisma.subscription.findMany).mockResolvedValue([] as any);

    const result = await analyticsService.getPlatformAnalytics();

    expect(result.users.total).toBe(0);
    expect(result.communities.total).toBe(0);
    expect(result.revenue.total).toBe(0);
  });
});
