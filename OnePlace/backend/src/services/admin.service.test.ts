import { describe, it, expect, vi, beforeEach } from "vitest";
import { AppError } from "../utils/AppError.js";

vi.mock("../database/db.js", () => ({
  prisma: {
    user: {
      findMany: vi.fn(),
      findUnique: vi.fn(),
      update: vi.fn(),
    },
    community: {
      findMany: vi.fn(),
    },
  },
}));

import { prisma } from "../database/db.js";
import * as adminService from "./admin.service.js";

function makeUser(overrides: Record<string, unknown> = {}) {
  return {
    id: "user-1",
    firstname: "Jane",
    lastname: "Doe",
    email: "jane@example.com",
    role: "user" as const,
    isVerified: true,
    isSuspended: false,
    lastLogin: null,
    createdAt: new Date("2024-01-01"),
    ...overrides,
  };
}

// ─── listUsers ────────────────────────────────────────────────────────────────

describe("adminService.listUsers", () => {
  beforeEach(() => vi.clearAllMocks());

  it("returns all users", async () => {
    vi.mocked(prisma.user.findMany).mockResolvedValue([makeUser()] as any);
    const result = await adminService.listUsers();
    expect(result).toHaveLength(1);
    expect(prisma.user.findMany).toHaveBeenCalledOnce();
  });
});

// ─── listAllCommunities ───────────────────────────────────────────────────────

describe("adminService.listAllCommunities", () => {
  beforeEach(() => vi.clearAllMocks());

  it("returns all communities", async () => {
    vi.mocked(prisma.community.findMany).mockResolvedValue([
      { id: "c-1", name: "Test Community" },
    ] as any);
    const result = await adminService.listAllCommunities();
    expect(result).toHaveLength(1);
    expect(prisma.community.findMany).toHaveBeenCalledOnce();
  });
});

// ─── setSuspended ─────────────────────────────────────────────────────────────

describe("adminService.setSuspended", () => {
  beforeEach(() => vi.clearAllMocks());

  it("suspends a regular user", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(makeUser() as any);
    vi.mocked(prisma.user.update).mockResolvedValue(makeUser({ isSuspended: true }) as any);

    const result = await adminService.setSuspended("user-1", true);
    expect(prisma.user.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { isSuspended: true } })
    );
    expect(result.isSuspended).toBe(true);
  });

  it("unsuspends a user", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(makeUser({ isSuspended: true }) as any);
    vi.mocked(prisma.user.update).mockResolvedValue(makeUser({ isSuspended: false }) as any);

    const result = await adminService.setSuspended("user-1", false);
    expect(result.isSuspended).toBe(false);
  });

  it("throws 404 when user does not exist", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(null);
    await expect(adminService.setSuspended("ghost", true)).rejects.toMatchObject({ statusCode: 404 });
  });

  it("throws 403 when trying to suspend another moderator", async () => {
    vi.mocked(prisma.user.findUnique).mockResolvedValue(makeUser({ role: "moderator" }) as any);
    await expect(adminService.setSuspended("user-1", true)).rejects.toMatchObject({ statusCode: 403 });
  });
});
