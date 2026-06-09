import bcrypt from "bcryptjs";
import { prisma } from "../database/db.js";
import { AppError } from "../utils/AppError.js";

const BCRYPT_ROUNDS = 12;

// ─── Get Own Profile ───────────────────────────────────────────────────────────

export async function getProfile(userId: string) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      firstname: true,
      lastname: true,
      email: true,
      role: true,
      avatarUrl: true,
      isVerified: true,
      isSuspended: true,
      lastLogin: true,
      createdAt: true,
    },
  });

  if (!user) throw new AppError("User not found", 404);
  return user;
}

// ─── Update Own Profile ────────────────────────────────────────────────────────
// Allows updating name and password. Email changes are out of scope for V0.

export async function updateProfile(
  userId: string,
  input: { firstname?: string; lastname?: string; currentPassword?: string; newPassword?: string; avatarUrl?: string | null }
) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) throw new AppError("User not found", 404);

  const data: Record<string, any> = {};

  if (input.firstname !== undefined) {
    if (!input.firstname.trim()) throw new AppError("First name cannot be empty", 400);
    data.firstname = input.firstname.trim();
  }

  if (input.lastname !== undefined) {
    if (!input.lastname.trim()) throw new AppError("Last name cannot be empty", 400);
    data.lastname = input.lastname.trim();
  }

  if ("avatarUrl" in input) {
    data.avatarUrl = input.avatarUrl ?? null;
  }

  if (input.newPassword !== undefined) {
    if (!input.currentPassword) {
      throw new AppError("currentPassword is required to set a new password", 400);
    }
    const matches = await bcrypt.compare(input.currentPassword, user.password);
    if (!matches) throw new AppError("Current password is incorrect", 401);

    if (input.newPassword.length < 8) {
      throw new AppError("New password must be at least 8 characters", 400);
    }
    data.password = await bcrypt.hash(input.newPassword, BCRYPT_ROUNDS);
  }

  if (Object.keys(data).length === 0) {
    throw new AppError("No fields provided to update", 400);
  }

  const updated = await prisma.user.update({
    where: { id: userId },
    data,
    select: {
      id: true,
      firstname: true,
      lastname: true,
      email: true,
      role: true,
      avatarUrl: true,
      isVerified: true,
      createdAt: true,
    },
  });

  return updated;
}

// ─── Get User's Communities ────────────────────────────────────────────────────
// Returns all communities the user is an active member of.

export async function getUserCommunities(userId: string) {
  const memberships = await prisma.membership.findMany({
    where: { userId, status: "ACTIVE" },
    include: {
      community: {
        select: {
          id: true,
          name: true,
          description: true,
          iconUrl: true,
          pricingModel: true,
          platformPlan: true,
          creator: { select: { id: true, firstname: true, lastname: true } },
        },
      },
    },
    orderBy: { joinedAt: "desc" },
  });

  return memberships.map((m) => ({
    membershipId: m.id,
    role: m.role,
    membershipTier: m.membershipTier,
    joinedAt: m.joinedAt,
    community: m.community,
  }));
}
