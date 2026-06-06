import { describe, it, expect, vi, beforeEach } from "vitest";

vi.mock("../database/db.js", () => ({
  prisma: {
    community: { findUnique: vi.fn() },
    membership: { findUnique: vi.fn(), findMany: vi.fn(), update: vi.fn() },
  },
}));

import { prisma } from "../database/db.js";
import * as membershipService from "./membership.service.js";

function makeCommunity(overrides: Record<string, unknown> = {}) {
  return { id: "c-1", name: "Test Community", creatorId: "creator-1", pricingModel: "SUBSCRIPTION", ...overrides };
}

function makeMembership(overrides: Record<string, unknown> = {}) {
  return {
    id: "m-1",
    userId: "user-1",
    communityId: "c-1",
    role: "member",
    status: "ACTIVE",
    membershipTier: "FREE",
    joinedAt: new Date(),
    community: { id: "c-1", name: "Test Community", creatorId: "creator-1" },
    subscriptions: [],
    user: { id: "user-1", firstname: "Jane", lastname: "Doe", email: "jane@example.com" },
    ...overrides,
  };
}

// ─── getMembershipById ────────────────────────────────────────────────────────

describe("membershipService.getMembershipById", () => {
  beforeEach(() => vi.clearAllMocks());

  it("returns membership to the owner", async () => {
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(makeMembership({ userId: "user-1" }) as any);
    const result = await membershipService.getMembershipById("m-1", "user-1");
    expect(result.id).toBe("m-1");
  });

  it("returns membership to the community creator", async () => {
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(makeMembership({ userId: "user-1" }) as any);
    const result = await membershipService.getMembershipById("m-1", "creator-1");
    expect(result.id).toBe("m-1");
  });

  it("throws 403 for an unrelated user", async () => {
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(makeMembership({ userId: "user-1" }) as any);
    await expect(membershipService.getMembershipById("m-1", "stranger")).rejects.toMatchObject({ statusCode: 403 });
  });

  it("throws 404 when membership does not exist", async () => {
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(null);
    await expect(membershipService.getMembershipById("ghost", "user-1")).rejects.toMatchObject({ statusCode: 404 });
  });
});

// ─── getUpcomingRenewals ──────────────────────────────────────────────────────

describe("membershipService.getUpcomingRenewals", () => {
  beforeEach(() => vi.clearAllMocks());

  it("returns memberships expiring within 7 days", async () => {
    const soon = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);
    vi.mocked(prisma.membership.findMany).mockResolvedValue([
      makeMembership({ subscriptions: [{ paymentStatus: "SUCCESS", subscriptionEnd: soon }] }),
    ] as any);

    const result = await membershipService.getUpcomingRenewals("user-1");
    expect(result).toHaveLength(1);
  });

  it("excludes memberships with no active subscription", async () => {
    vi.mocked(prisma.membership.findMany).mockResolvedValue([
      makeMembership({ subscriptions: [] }),
    ] as any);

    const result = await membershipService.getUpcomingRenewals("user-1");
    expect(result).toHaveLength(0);
  });

  it("excludes memberships already expired", async () => {
    const past = new Date(Date.now() - 1000);
    vi.mocked(prisma.membership.findMany).mockResolvedValue([
      makeMembership({ subscriptions: [{ paymentStatus: "SUCCESS", subscriptionEnd: past }] }),
    ] as any);

    const result = await membershipService.getUpcomingRenewals("user-1");
    expect(result).toHaveLength(0);
  });
});

// ─── banMember ────────────────────────────────────────────────────────────────

describe("membershipService.banMember", () => {
  beforeEach(() => vi.clearAllMocks());

  it("bans a regular member", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity() as any);
    vi.mocked(prisma.membership.findUnique)
      .mockResolvedValueOnce(makeMembership({ userId: "creator-1", role: "creator" }) as any) // requester
      .mockResolvedValueOnce(makeMembership({ userId: "user-1", role: "member" }) as any); // target
    vi.mocked(prisma.membership.update).mockResolvedValue(makeMembership({ status: "BANNED" }) as any);

    const result = await membershipService.banMember("c-1", "user-1", "creator-1");
    expect(prisma.membership.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { status: "BANNED" } })
    );
  });

  it("throws 400 when trying to ban the creator", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity({ creatorId: "creator-1" }) as any);
    await expect(membershipService.banMember("c-1", "creator-1", "creator-1")).rejects.toMatchObject({ statusCode: 400 });
  });

  it("throws 403 when requester is not creator or admin", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity() as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValueOnce(makeMembership({ role: "member" }) as any);
    await expect(membershipService.banMember("c-1", "user-2", "user-1")).rejects.toMatchObject({ statusCode: 403 });
  });

  it("throws 403 when an admin tries to ban another admin", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity() as any);
    vi.mocked(prisma.membership.findUnique)
      .mockResolvedValueOnce(makeMembership({ userId: "admin-1", role: "admin" }) as any) // requester
      .mockResolvedValueOnce(makeMembership({ userId: "admin-2", role: "admin" }) as any); // target
    await expect(membershipService.banMember("c-1", "admin-2", "admin-1")).rejects.toMatchObject({ statusCode: 403 });
  });

  it("throws 409 when member is already banned", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity() as any);
    vi.mocked(prisma.membership.findUnique)
      .mockResolvedValueOnce(makeMembership({ role: "creator" }) as any)
      .mockResolvedValueOnce(makeMembership({ status: "BANNED" }) as any);
    await expect(membershipService.banMember("c-1", "user-1", "creator-1")).rejects.toMatchObject({ statusCode: 409 });
  });
});

// ─── unbanMember ──────────────────────────────────────────────────────────────

describe("membershipService.unbanMember", () => {
  beforeEach(() => vi.clearAllMocks());

  it("restores a banned member to active", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity() as any);
    vi.mocked(prisma.membership.findUnique)
      .mockResolvedValueOnce(makeMembership({ role: "creator" }) as any)
      .mockResolvedValueOnce(makeMembership({ status: "BANNED" }) as any);
    vi.mocked(prisma.membership.update).mockResolvedValue(makeMembership({ status: "ACTIVE" }) as any);

    await membershipService.unbanMember("c-1", "user-1", "creator-1");
    expect(prisma.membership.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { status: "ACTIVE" } })
    );
  });

  it("throws 400 when member is not banned", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity() as any);
    vi.mocked(prisma.membership.findUnique)
      .mockResolvedValueOnce(makeMembership({ role: "creator" }) as any)
      .mockResolvedValueOnce(makeMembership({ status: "ACTIVE" }) as any);
    await expect(membershipService.unbanMember("c-1", "user-1", "creator-1")).rejects.toMatchObject({ statusCode: 400 });
  });
});

// ─── setMemberRole ────────────────────────────────────────────────────────────

describe("membershipService.setMemberRole", () => {
  beforeEach(() => vi.clearAllMocks());

  it("promotes a member to admin", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity({ creatorId: "creator-1" }) as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(makeMembership({ role: "member" }) as any);
    vi.mocked(prisma.membership.update).mockResolvedValue(makeMembership({ role: "admin" }) as any);

    await membershipService.setMemberRole("c-1", "user-1", "creator-1", "admin");
    expect(prisma.membership.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { role: "admin" } })
    );
  });

  it("throws 403 when requester is not the creator", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity({ creatorId: "creator-1" }) as any);
    await expect(
      membershipService.setMemberRole("c-1", "user-1", "not-creator", "admin")
    ).rejects.toMatchObject({ statusCode: 403 });
  });

  it("throws 400 when trying to change the creator's own role", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity({ creatorId: "creator-1" }) as any);
    await expect(
      membershipService.setMemberRole("c-1", "creator-1", "creator-1", "admin")
    ).rejects.toMatchObject({ statusCode: 400 });
  });

  it("throws 409 when member already has the target role", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity({ creatorId: "creator-1" }) as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(makeMembership({ role: "admin" }) as any);
    await expect(
      membershipService.setMemberRole("c-1", "user-1", "creator-1", "admin")
    ).rejects.toMatchObject({ statusCode: 409 });
  });
});
