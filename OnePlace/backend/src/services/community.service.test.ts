import { describe, it, expect, vi, beforeEach } from "vitest";

vi.mock("../database/db.js", () => ({
  prisma: {
    community: { create: vi.fn(), findUnique: vi.fn(), findFirst: vi.fn(), update: vi.fn(), delete: vi.fn() },
    membership: { create: vi.fn(), findUnique: vi.fn(), deleteMany: vi.fn(), update: vi.fn() },
    communityPricing: { upsert: vi.fn() },
    subscription: { findMany: vi.fn(), create: vi.fn() },
    post: { findMany: vi.fn() },
    user: { findUnique: vi.fn() },
    $transaction: vi.fn(),
  },
}));

vi.mock("./payment.service.js", () => ({
  createSubscription: vi.fn().mockReturnValue({ subscriptionId: "mock_sub_123" }),
  createPaymentIntent: vi.fn().mockReturnValue({ paymentIntentId: "mock_pi_123" }),
  cancelSubscription: vi.fn().mockReturnValue({ status: "canceled" }),
}));

vi.mock("../utils/email.utils.js", () => ({
  sendPaymentConfirmationEmail: vi.fn().mockResolvedValue(undefined),
}));

import { prisma } from "../database/db.js";
import * as communityService from "./community.service.js";

function makeCommunity(overrides: Record<string, unknown> = {}) {
  return {
    id: "c-1",
    name: "Test Community",
    creatorId: "creator-1",
    pricingModel: "FREE",
    platformPlan: "BASIC",
    isPrivate: false,
    description: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    pricing: null,
    ...overrides,
  };
}

function makeMembership(overrides: Record<string, unknown> = {}) {
  return {
    id: "m-1",
    userId: "creator-1",
    communityId: "c-1",
    role: "creator",
    status: "ACTIVE",
    pricingModelAtJoin: "FREE",
    membershipTier: "FREE",
    joinedAt: new Date(),
    subscriptions: [],
    ...overrides,
  };
}

// ─── createCommunity ──────────────────────────────────────────────────────────

describe("communityService.createCommunity", () => {
  beforeEach(() => vi.clearAllMocks());

  it("creates a community", async () => {
    vi.mocked(prisma.community.create).mockResolvedValue(makeCommunity() as any);

    const result = await communityService.createCommunity({
      name: "Test Community",
      platformPlan: "BASIC",
      creatorId: "creator-1",
    });

    expect(result.name).toBe("Test Community");
  });

  it("allows a creator to own multiple communities", async () => {
    vi.mocked(prisma.community.create).mockResolvedValue(makeCommunity({ name: "Second Community" }) as any);

    const result = await communityService.createCommunity({
      name: "Second Community",
      platformPlan: "PRO",
      creatorId: "creator-1",
    });

    expect(result.name).toBe("Second Community");
  });

  it("throws 400 when name is missing", async () => {
    await expect(
      communityService.createCommunity({ name: "", platformPlan: "BASIC", creatorId: "creator-1" })
    ).rejects.toMatchObject({ statusCode: 400 });
  });

  it("throws 400 when platformPlan is invalid", async () => {
    await expect(
      communityService.createCommunity({ name: "Test", platformPlan: "INVALID" as any, creatorId: "creator-1" })
    ).rejects.toMatchObject({ statusCode: 400 });
  });
});

// ─── configurePricing ─────────────────────────────────────────────────────────

describe("communityService.configurePricing", () => {
  beforeEach(() => vi.clearAllMocks());

  it("upserts pricing config for the creator", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity({ creatorId: "creator-1" }) as any);
    vi.mocked(prisma.communityPricing.upsert).mockResolvedValue({ id: "p-1", monthlyPrice: 10 } as any);

    const result = await communityService.configurePricing("c-1", "creator-1", { monthlyPrice: 10 });
    expect(result.monthlyPrice).toBe(10);
  });

  it("throws 403 when requester is not the creator", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity({ creatorId: "creator-1" }) as any);
    await expect(
      communityService.configurePricing("c-1", "other-user", { monthlyPrice: 10 })
    ).rejects.toMatchObject({ statusCode: 403 });
  });
});

// ─── changePricingModel ───────────────────────────────────────────────────────

describe("communityService.changePricingModel", () => {
  beforeEach(() => vi.clearAllMocks());

  it("changes the pricing model", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity({ pricingModel: "FREE" }) as any);
    vi.mocked(prisma.community.update).mockResolvedValue(makeCommunity({ pricingModel: "FREEMIUM" }) as any);

    const result = await communityService.changePricingModel("c-1", "creator-1", "FREEMIUM");
    expect(result.pricingModel).toBe("FREEMIUM");
  });

  it("throws 400 when model is already set to the requested value", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity({ pricingModel: "FREE" }) as any);
    await expect(
      communityService.changePricingModel("c-1", "creator-1", "FREE")
    ).rejects.toMatchObject({ statusCode: 400 });
  });

  it("throws 400 when pricing model is invalid", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity() as any);
    await expect(
      communityService.changePricingModel("c-1", "creator-1", "INVALID" as any)
    ).rejects.toMatchObject({ statusCode: 400 });
  });

  it("throws 403 when requester is not the creator", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity({ creatorId: "creator-1" }) as any);
    await expect(
      communityService.changePricingModel("c-1", "other-user", "FREEMIUM")
    ).rejects.toMatchObject({ statusCode: 403 });
  });
});

// ─── joinCommunity ────────────────────────────────────────────────────────────

describe("communityService.joinCommunity", () => {
  beforeEach(() => vi.clearAllMocks());

  it("joins a FREE community", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity({ pricingModel: "FREE" }) as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(null);
    vi.mocked(prisma.membership.create).mockResolvedValue(makeMembership({ userId: "user-1" }) as any);

    const result = await communityService.joinCommunity("c-1", "user-1");
    expect(prisma.membership.create).toHaveBeenCalled();
  });

  it("joins a FREEMIUM community", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity({ pricingModel: "FREEMIUM" }) as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(null);
    vi.mocked(prisma.membership.create).mockResolvedValue(makeMembership({ pricingModelAtJoin: "FREEMIUM" }) as any);

    await communityService.joinCommunity("c-1", "user-1");
    expect(prisma.membership.create).toHaveBeenCalled();
  });

  it("throws 409 when user is already a member", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity() as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(makeMembership() as any);

    await expect(communityService.joinCommunity("c-1", "creator-1")).rejects.toMatchObject({ statusCode: 409 });
  });

  it("throws 404 when community does not exist", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(null);
    await expect(communityService.joinCommunity("ghost", "user-1")).rejects.toMatchObject({ statusCode: 404 });
  });

  it("throws 400 when joining SUBSCRIPTION without billingInterval", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity({ pricingModel: "SUBSCRIPTION" }) as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(null);

    await expect(communityService.joinCommunity("c-1", "user-1")).rejects.toMatchObject({ statusCode: 400 });
  });
});

// ─── leaveCommunity ───────────────────────────────────────────────────────────

describe("communityService.leaveCommunity", () => {
  beforeEach(() => vi.clearAllMocks());

  it("sets membership to CANCELLED", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity({ creatorId: "creator-1" }) as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(
      makeMembership({ userId: "user-1", role: "member", status: "ACTIVE", subscriptions: [] }) as any
    );
    vi.mocked(prisma.membership.update).mockResolvedValue(makeMembership({ status: "CANCELLED" }) as any);

    await communityService.leaveCommunity("c-1", "user-1");
    expect(prisma.membership.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { status: "CANCELLED" } })
    );
  });

  it("throws 400 when the creator tries to leave", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity({ creatorId: "creator-1" }) as any);
    await expect(communityService.leaveCommunity("c-1", "creator-1")).rejects.toMatchObject({ statusCode: 400 });
  });

  it("throws 400 when membership is already cancelled", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity({ creatorId: "creator-1" }) as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(
      makeMembership({ userId: "user-1", status: "CANCELLED" }) as any
    );
    await expect(communityService.leaveCommunity("c-1", "user-1")).rejects.toMatchObject({ statusCode: 400 });
  });
});

// ─── deleteCommunity ──────────────────────────────────────────────────────────

describe("communityService.deleteCommunity", () => {
  beforeEach(() => vi.clearAllMocks());

  it("deletes memberships then the community", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity({ creatorId: "creator-1" }) as any);
    vi.mocked(prisma.membership.deleteMany).mockResolvedValue({ count: 2 } as any);
    vi.mocked(prisma.community.delete).mockResolvedValue(makeCommunity() as any);

    await communityService.deleteCommunity("c-1", "creator-1");
    expect(prisma.membership.deleteMany).toHaveBeenCalledWith({ where: { communityId: "c-1" } });
    expect(prisma.community.delete).toHaveBeenCalled();
  });

  it("throws 403 when requester is not the creator", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity({ creatorId: "creator-1" }) as any);
    await expect(communityService.deleteCommunity("c-1", "other-user")).rejects.toMatchObject({ statusCode: 403 });
  });
});
