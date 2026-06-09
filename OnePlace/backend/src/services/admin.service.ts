import { prisma } from "../database/db.js";
import { AppError } from "../utils/AppError.js";

// ─── List Users ────────────────────────────────────────────────────────────────

export async function listUsers() {
  return prisma.user.findMany({
    orderBy: { createdAt: "desc" },
    select: {
      id: true,
      firstname: true,
      lastname: true,
      email: true,
      role: true,
      isVerified: true,
      isSuspended: true,
      lastLogin: true,
      createdAt: true,
      _count: { select: { memberships: true, communities: true } },
    },
  });
}

// ─── List Communities ──────────────────────────────────────────────────────────

export async function listAllCommunities() {
  return prisma.community.findMany({
    orderBy: { createdAt: "desc" },
    include: {
      creator: { select: { id: true, firstname: true, lastname: true, email: true } },
      pricing: true,
      _count: { select: { memberships: true, posts: true } },
    },
  });
}

// ─── Suspend / Unsuspend User ─────────────────────────────────────────────────

export async function setSuspended(targetUserId: string, suspend: boolean) {
  const user = await prisma.user.findUnique({ where: { id: targetUserId } });
  if (!user) throw new AppError("User not found", 404);

  if (user.role === "moderator" && suspend) {
    throw new AppError("Cannot suspend another moderator", 403);
  }

  return prisma.user.update({
    where: { id: targetUserId },
    data: { isSuspended: suspend },
    select: {
      id: true,
      firstname: true,
      lastname: true,
      email: true,
      isSuspended: true,
    },
  });
}
