import { prisma } from "../database/db.js";
import { AppError } from "../utils/AppError.js";

// ─── Get Own Memberships ───────────────────────────────────────────────────────

export async function getMyMemberships(userId: string) {
  return prisma.membership.findMany({
    where: { userId },
    include: {
      community: {
        select: {
          id: true,
          name: true,
          pricingModel: true,
          platformPlan: true,
        },
      },
      subscriptions: {
        orderBy: { createdAt: "desc" },
        take: 1,
      },
    },
    orderBy: { joinedAt: "desc" },
  });
}

// ─── Get Membership By ID ──────────────────────────────────────────────────────
// Only the membership owner or a community creator/admin may read it.

export async function getMembershipById(membershipId: string, requesterId: string) {
  const membership = await prisma.membership.findUnique({
    where: { id: membershipId },
    include: {
      community: { select: { id: true, name: true, creatorId: true } },
      subscriptions: { orderBy: { createdAt: "desc" }, take: 1 },
    },
  });

  if (!membership) throw new AppError("Membership not found", 404);

  const isOwner = membership.userId === requesterId;
  const isCommunityCreator = membership.community.creatorId === requesterId;

  if (!isOwner && !isCommunityCreator) {
    throw new AppError("You do not have access to this membership", 403);
  }

  return membership;
}

// ─── Upcoming Renewals ─────────────────────────────────────────────────────────
// Returns memberships whose subscription ends within the next 7 days.

export async function getUpcomingRenewals(userId: string) {
  const now = new Date();
  const in7Days = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

  const memberships = await prisma.membership.findMany({
    where: {
      userId,
      status: "ACTIVE",
      community: { pricingModel: "SUBSCRIPTION" },
    },
    include: {
      community: { select: { id: true, name: true } },
      subscriptions: {
        orderBy: { createdAt: "desc" },
        take: 1,
      },
    },
  });

  return memberships.filter(({ subscriptions }) => {
    const latest = subscriptions[0];
    return (
      latest &&
      latest.paymentStatus === "SUCCESS" &&
      latest.subscriptionEnd !== null &&
      latest.subscriptionEnd >= now &&
      latest.subscriptionEnd <= in7Days
    );
  });
}

// ─── Ban Member ────────────────────────────────────────────────────────────────
// Sets membership status to BANNED. Creator and admins can ban; only creators
// can ban admins. Creators cannot be banned.

export async function banMember(communityId: string, targetUserId: string, requesterId: string) {
  const community = await prisma.community.findUnique({ where: { id: communityId } });
  if (!community) throw new AppError("Community not found", 404);

  if (community.creatorId === targetUserId) {
    throw new AppError("The community creator cannot be banned", 400);
  }

  const requesterMembership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId: requesterId, communityId } },
  });

  if (!requesterMembership || !["creator", "admin"].includes(requesterMembership.role)) {
    throw new AppError("Only creators and admins can ban members", 403);
  }

  const targetMembership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId: targetUserId, communityId } },
  });

  if (!targetMembership) throw new AppError("Membership not found", 404);

  // Admins cannot ban other admins — only the creator can
  if (targetMembership.role === "admin" && requesterMembership.role !== "creator") {
    throw new AppError("Only the creator can ban an admin", 403);
  }

  if (targetMembership.status === "BANNED") {
    throw new AppError("This member is already banned", 409);
  }

  return prisma.membership.update({
    where: { id: targetMembership.id },
    data: { status: "BANNED" },
    select: { id: true, userId: true, communityId: true, role: true, status: true },
  });
}

// ─── Unban Member ──────────────────────────────────────────────────────────────
// Restores a BANNED membership to ACTIVE.

export async function unbanMember(communityId: string, targetUserId: string, requesterId: string) {
  const community = await prisma.community.findUnique({ where: { id: communityId } });
  if (!community) throw new AppError("Community not found", 404);

  const requesterMembership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId: requesterId, communityId } },
  });

  if (!requesterMembership || !["creator", "admin"].includes(requesterMembership.role)) {
    throw new AppError("Only creators and admins can unban members", 403);
  }

  const targetMembership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId: targetUserId, communityId } },
  });

  if (!targetMembership) throw new AppError("Membership not found", 404);

  if (targetMembership.status !== "BANNED") {
    throw new AppError("This member is not banned", 400);
  }

  return prisma.membership.update({
    where: { id: targetMembership.id },
    data: { status: "ACTIVE" },
    select: { id: true, userId: true, communityId: true, role: true, status: true },
  });
}

// ─── Set Member Role ───────────────────────────────────────────────────────────
// Promotes a member to admin or demotes an admin back to member.
// Only the creator can change roles. Creator role itself cannot be changed.

export async function setMemberRole(
  communityId: string,
  targetUserId: string,
  requesterId: string,
  newRole: "admin" | "member"
) {
  const community = await prisma.community.findUnique({ where: { id: communityId } });
  if (!community) throw new AppError("Community not found", 404);

  if (community.creatorId !== requesterId) {
    throw new AppError("Only the creator can change member roles", 403);
  }

  if (community.creatorId === targetUserId) {
    throw new AppError("The creator's role cannot be changed", 400);
  }

  const targetMembership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId: targetUserId, communityId } },
  });

  if (!targetMembership || targetMembership.status !== "ACTIVE") {
    throw new AppError("Active membership not found", 404);
  }

  if (targetMembership.role === newRole) {
    throw new AppError(`Member is already ${newRole}`, 409);
  }

  return prisma.membership.update({
    where: { id: targetMembership.id },
    data: { role: newRole },
    select: { id: true, userId: true, communityId: true, role: true, status: true },
  });
}

// ─── Export Members as CSV ────────────────────────────────────────────────────
// Creator/admin use — returns a CSV string of all community members.

export async function exportMembersAsCsv(communityId: string, requesterId: string): Promise<string> {
  const members = await getCommunityMembers(communityId, requesterId);

  const escape = (v: string | null | undefined) => {
    if (v == null) return "";
    const s = String(v);
    return s.includes(",") || s.includes('"') || s.includes("\n")
      ? `"${s.replace(/"/g, '""')}"`
      : s;
  };

  const header = "id,firstname,lastname,email,role,status,membershipTier,joinedAt,subscriptionEnd,pricePaid";

  const rows = members.map((m) => {
    const latest = m.subscriptions[0] ?? null;
    return [
      escape(m.id),
      escape(m.user.firstname),
      escape(m.user.lastname),
      escape(m.user.email),
      escape(m.role),
      escape(m.status),
      escape(m.membershipTier),
      escape(m.joinedAt.toISOString()),
      escape(latest?.subscriptionEnd?.toISOString() ?? null),
      escape(latest?.pricePaid != null ? String(latest.pricePaid) : null),
    ].join(",");
  });

  return [header, ...rows].join("\n");
}

// ─── List Community Members ────────────────────────────────────────────────────
// Creator/admin use — lists all members of a community with their status.

export async function getCommunityMembers(communityId: string, requesterId: string) {
  const community = await prisma.community.findUnique({ where: { id: communityId } });
  if (!community) throw new AppError("Community not found", 404);

  const requesterMembership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId: requesterId, communityId } },
  });

  if (
    !requesterMembership ||
    !["creator", "admin"].includes(requesterMembership.role)
  ) {
    throw new AppError("Only creators and admins can view the member list", 403);
  }

  return prisma.membership.findMany({
    where: { communityId },
    include: {
      user: { select: { id: true, firstname: true, lastname: true, email: true } },
      subscriptions: { orderBy: { createdAt: "desc" }, take: 1 },
    },
    orderBy: { joinedAt: "desc" },
  });
}
