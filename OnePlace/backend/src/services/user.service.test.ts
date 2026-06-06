import { describe, it, expect, vi, beforeEach } from "vitest";

const bcryptMock = vi.hoisted(() => ({
  hash: vi.fn().mockResolvedValue("new_hashed_password"),
  compare: vi.fn(),
}));

vi.mock("bcryptjs", () => ({
  default: bcryptMock,
  ...bcryptMock,
}));

vi.mock("../database/db.js", () => ({
  prisma: {
    user: {
      findUnique: vi.fn(),
      update: vi.fn(),
    },
    membership: {
      findMany: vi.fn(),
    },
  },
}));

import { prisma } from "../database/db.js";
import * as userService from "./user.service.js";

function makeUser(overrides: Record<string, unknown> = {}) {
  return {
    id: "user-1",
    firstname: "Jane",
    lastname: "Doe",
    email: "jane@example.com",
    password: "hashed_password",
    role: "user" as const,
    isVerified: true,
    isSuspended: false,
    lastLogin: null,
    createdAt: new Date("2024-01-01"),
    ...overrides,
  };
}

// ─── getProfile ───────────────────────────────────────────────────────────────

describe("userService.getProfile", () => {
  beforeEach(() => vi.clearAllMocks());

  it("returns the user profile", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(makeUser() as any);
    const result = await userService.getProfile("user-1");
    expect(result.email).toBe("jane@example.com");
  });

  it("throws 404 when user does not exist", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(null);
    await expect(userService.getProfile("ghost")).rejects.toMatchObject({ statusCode: 404 });
  });
});

// ─── updateProfile ────────────────────────────────────────────────────────────

describe("userService.updateProfile", () => {
  beforeEach(() => vi.clearAllMocks());

  it("updates firstname", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(makeUser() as any);
    vi.mocked(prisma.user.update).mockResolvedValue(makeUser({ firstname: "Updated" }) as any);

    const result = await userService.updateProfile("user-1", { firstname: "Updated" });
    expect(result.firstname).toBe("Updated");
  });

  it("throws 400 when no fields provided", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(makeUser() as any);
    await expect(userService.updateProfile("user-1", {})).rejects.toMatchObject({ statusCode: 400 });
  });

  it("throws 400 when firstname is blank", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(makeUser() as any);
    await expect(
      userService.updateProfile("user-1", { firstname: "   " })
    ).rejects.toMatchObject({ statusCode: 400 });
  });

  it("throws 400 when newPassword provided without currentPassword", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(makeUser() as any);
    await expect(
      userService.updateProfile("user-1", { newPassword: "newpass123" })
    ).rejects.toMatchObject({ statusCode: 400 });
  });

  it("throws 401 when currentPassword is wrong", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(makeUser() as any);
    bcryptMock.compare.mockResolvedValueOnce(false);
    await expect(
      userService.updateProfile("user-1", { currentPassword: "wrong", newPassword: "newpass123" })
    ).rejects.toMatchObject({ statusCode: 401 });
  });

  it("throws 400 when new password is too short", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(makeUser() as any);
    bcryptMock.compare.mockResolvedValueOnce(true);
    await expect(
      userService.updateProfile("user-1", { currentPassword: "correct", newPassword: "short" })
    ).rejects.toMatchObject({ statusCode: 400 });
  });

  it("updates password when currentPassword matches", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(makeUser() as any);
    bcryptMock.compare.mockResolvedValueOnce(true);
    vi.mocked(prisma.user.update).mockResolvedValue(makeUser() as any);

    await userService.updateProfile("user-1", {
      currentPassword: "correct",
      newPassword: "newpassword123",
    });

    expect(prisma.user.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ password: "new_hashed_password" }) })
    );
  });

  it("throws 404 when user does not exist", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(null);
    await expect(
      userService.updateProfile("ghost", { firstname: "X" })
    ).rejects.toMatchObject({ statusCode: 404 });
  });
});

// ─── getUserCommunities ───────────────────────────────────────────────────────

describe("userService.getUserCommunities", () => {
  beforeEach(() => vi.clearAllMocks());

  it("returns the user's active communities", async () => {
    vi.mocked(prisma.membership.findMany).mockResolvedValue([
      {
        id: "m-1",
        role: "member",
        membershipTier: "FREE",
        joinedAt: new Date(),
        community: { id: "c-1", name: "Community A", description: null, pricingModel: "FREE", platformPlan: "BASIC", creator: { id: "u-2", firstname: "Bob", lastname: "Smith" } },
      },
    ] as any);

    const result = await userService.getUserCommunities("user-1");
    expect(result).toHaveLength(1);
    expect(result[0]!.community.name).toBe("Community A");
  });
});
