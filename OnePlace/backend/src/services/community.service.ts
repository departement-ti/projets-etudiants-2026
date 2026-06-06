import { prisma } from "../database/db.js";
import { AppError } from "../utils/AppError.js";
import * as paymentService from "./payment.service.js";
import { sendPaymentConfirmationEmail } from "../utils/email.utils.js";
import { createNotification } from "./notification.service.js";
import { addPoints } from "./points.service.js";
import type {
  Community,
  CommunityPricing,
  PlatformPlan,
  PricingModel,
  BillingInterval,
} from "@prisma/client";

// ─── Create Community ──────────────────────────────────────────────────────────
// Step 2 of onboarding: creator picks platformPlan + community name.
// pricingModel defaults to FREE; everything else is configured later in the dashboard.

export async function createCommunity(input: {
  name: string;
  platformPlan: PlatformPlan;
  creatorId: string;
}): Promise<Community> {
  const { name, platformPlan, creatorId } = input;

  if (!name || !platformPlan) {
    throw new AppError("name and platformPlan are required", 400);
  }

  if (!["BASIC", "PRO"].includes(platformPlan)) {
    throw new AppError("platformPlan must be BASIC or PRO", 400);
  }

  const community = await prisma.community.create({
    data: {
      name,
      platformPlan,
      creatorId,
      pricingModel: "FREE",
      // Creator automatically gets a membership with the creator role
      memberships: {
        create: {
          userId: creatorId,
          role: "creator",
          status: "ACTIVE",
          pricingModelAtJoin: "FREE",
          membershipTier: "FREE",
        },
      },
    },
  });

  return community;
}

// ─── Configure Pricing ─────────────────────────────────────────────────────────
// Called from dashboard after community creation.
// Upserts CommunityPricing — only provided fields are written on update.

export interface PricingInput {
  currency?: string;
  monthlyPrice?: number;
  yearlyPrice?: number;
  oneTimePrice?: number;
  upgradePrice?: number;
}

export async function configurePricing(
  communityId: string,
  requesterId: string,
  input: PricingInput
): Promise<CommunityPricing> {
  await assertCreator(communityId, requesterId);

  return prisma.communityPricing.upsert({
    where: { communityId },
    create: {
      communityId,
      currency: input.currency ?? "USD",
      monthlyPrice: input.monthlyPrice ?? null,
      yearlyPrice: input.yearlyPrice ?? null,
      oneTimePrice: input.oneTimePrice ?? null,
      upgradePrice: input.upgradePrice ?? null,
    },
    update: {
      ...(input.currency !== undefined && { currency: input.currency }),
      ...(input.monthlyPrice !== undefined && { monthlyPrice: input.monthlyPrice }),
      ...(input.yearlyPrice !== undefined && { yearlyPrice: input.yearlyPrice }),
      ...(input.oneTimePrice !== undefined && { oneTimePrice: input.oneTimePrice }),
      ...(input.upgradePrice !== undefined && { upgradePrice: input.upgradePrice }),
    },
  });
}

// ─── Change Pricing Model ──────────────────────────────────────────────────────
// Moving away from SUBSCRIPTION cancels all active subscriptions via the payment
// service. Existing members keep their ACTIVE status; the creator decides separately
// whether to charge them under the new model starting from their next renewal.

export async function changePricingModel(
  communityId: string,
  requesterId: string,
  newModel: PricingModel
): Promise<Community> {
  const community = await assertCreator(communityId, requesterId);

  const validModels: PricingModel[] = ["FREE", "SUBSCRIPTION", "FREEMIUM", "ONE_TIME"];
  if (!validModels.includes(newModel)) {
    throw new AppError("Invalid pricing model", 400);
  }

  if (community.pricingModel === newModel) {
    throw new AppError("Community is already on this pricing model", 400);
  }

  // Cancel active recurring subscriptions when leaving SUBSCRIPTION model
  if (community.pricingModel === "SUBSCRIPTION" && newModel !== "SUBSCRIPTION") {
    const activeSubs = await prisma.subscription.findMany({
      where: {
        membership: { communityId },
        paymentStatus: "SUCCESS",
        OR: [{ subscriptionEnd: null }, { subscriptionEnd: { gt: new Date() } }],
      },
    });

    for (const sub of activeSubs) {
      if (sub.externalId) {
        paymentService.cancelSubscription(sub.externalId);
      }
    }
  }

  return prisma.community.update({
    where: { id: communityId },
    data: { pricingModel: newModel },
  });
}

// ─── Join Community ────────────────────────────────────────────────────────────

export async function joinCommunity(
  communityId: string,
  userId: string,
  billingInterval?: BillingInterval
) {
  const community = await prisma.community.findUnique({
    where: { id: communityId },
    include: { pricing: true },
  });

  if (!community) throw new AppError("Community not found", 404);

  const existing = await prisma.membership.findUnique({
    where: { userId_communityId: { userId, communityId } },
  });

  if (existing?.status === "ACTIVE") {
    throw new AppError("You are already a member of this community", 409);
  }
  if (existing?.status === "BANNED") {
    throw new AppError("You have been banned from this community", 403);
  }
  // If EXPIRED or CANCELLED, existing membership will be reactivated below

  let membership;
  switch (community.pricingModel) {
    case "FREE":
      membership = existing
        ? await prisma.membership.update({ where: { id: existing.id }, data: { status: "ACTIVE" } })
        : await joinFree(communityId, userId);
      break;

    case "FREEMIUM":
      membership = existing
        ? await prisma.membership.update({ where: { id: existing.id }, data: { status: "ACTIVE" } })
        : await joinFreemium(communityId, userId);
      break;

    case "SUBSCRIPTION":
      if (!billingInterval) {
        throw new AppError("billingInterval (MONTHLY | YEARLY) is required", 400);
      }
      membership = await joinSubscription(community, userId, billingInterval, existing?.id);
      break;

    case "ONE_TIME":
      membership = await joinOneTime(community, userId, existing?.id);
      break;

    default:
      throw new AppError("Unsupported pricing model", 500);
  }

  // Award XP for joining (fire-and-forget)
  addPoints(userId, communityId, "MEMBERSHIP_JOINED").catch(() => {});

  // Notify the community creator (fire-and-forget)
  if (community.creatorId !== userId) {
    createNotification({
      userId: community.creatorId,
      type: "MEMBER_JOINED",
      title: "New member",
      body: `A new member joined ${community.name}`,
      link: `/communities/${communityId}/settings/members`,
    }).catch(() => {});
  }

  return membership;
}

async function joinFree(communityId: string, userId: string) {
  return prisma.membership.create({
    data: {
      userId,
      communityId,
      role: "member",
      status: "ACTIVE",
      pricingModelAtJoin: "FREE",
      membershipTier: "FREE",
    },
  });
}

async function joinFreemium(communityId: string, userId: string) {
  return prisma.membership.create({
    data: {
      userId,
      communityId,
      role: "member",
      status: "ACTIVE",
      pricingModelAtJoin: "FREEMIUM",
      membershipTier: "FREE",
    },
  });
}

async function joinSubscription(
  community: Community & { pricing: CommunityPricing | null },
  userId: string,
  billingInterval: BillingInterval,
  existingMembershipId?: string
) {
  if (!community.pricing) {
    throw new AppError("This community has not configured pricing yet", 400);
  }

  const amount =
    billingInterval === "MONTHLY"
      ? Number(community.pricing.monthlyPrice)
      : Number(community.pricing.yearlyPrice);

  if (!amount) {
    throw new AppError(
      `No ${billingInterval.toLowerCase()} price configured for this community`,
      400
    );
  }

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { email: true, firstname: true },
  });

  const result = paymentService.createSubscription(community.id, userId, billingInterval);

  const now = new Date();
  const subscriptionEnd =
    billingInterval === "MONTHLY"
      ? new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000)
      : new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000);

  const newSub = {
    externalId: result.subscriptionId,
    billingInterval,
    subscriptionStart: now,
    subscriptionEnd,
    pricePaid: amount,
    paymentStatus: "SUCCESS" as const,
  };

  const membership = existingMembershipId
    ? await prisma.membership.update({
        where: { id: existingMembershipId },
        data: {
          status: "ACTIVE",
          membershipTier: "PAID",
          subscriptions: { create: newSub },
        },
        include: { subscriptions: true },
      })
    : await prisma.membership.create({
        data: {
          userId,
          communityId: community.id,
          role: "member",
          status: "ACTIVE",
          pricingModelAtJoin: "SUBSCRIPTION",
          membershipTier: "PAID",
          subscriptions: { create: newSub },
        },
        include: { subscriptions: true },
      });

  if (user) {
    await sendPaymentConfirmationEmail(user.email, user.firstname, community.name, amount, billingInterval);
  }

  return membership;
}

async function joinOneTime(
  community: Community & { pricing: CommunityPricing | null },
  userId: string,
  existingMembershipId?: string
) {
  if (!community.pricing) {
    throw new AppError("This community has not configured pricing yet", 400);
  }

  const amount = Number(community.pricing.oneTimePrice);
  if (!amount) {
    throw new AppError("No one-time price configured for this community", 400);
  }

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { email: true, firstname: true },
  });

  const result = paymentService.createPaymentIntent(community.id, userId, amount);

  const newSub = {
    externalId: result.paymentIntentId,
    subscriptionStart: new Date(),
    subscriptionEnd: null as null,
    pricePaid: amount,
    paymentStatus: "SUCCESS" as const,
  };

  const membership = existingMembershipId
    ? await prisma.membership.update({
        where: { id: existingMembershipId },
        data: {
          status: "ACTIVE",
          membershipTier: "PAID",
          subscriptions: { create: newSub },
        },
        include: { subscriptions: true },
      })
    : await prisma.membership.create({
        data: {
          userId,
          communityId: community.id,
          role: "member",
          status: "ACTIVE",
          pricingModelAtJoin: "ONE_TIME",
          membershipTier: "PAID",
          subscriptions: { create: newSub },
        },
        include: { subscriptions: true },
      });

  if (user) {
    await sendPaymentConfirmationEmail(user.email, user.firstname, community.name, amount);
  }

  return membership;
}

// ─── Upgrade Freemium Member ───────────────────────────────────────────────────
// Moves an existing FREE-tier member to PAID via a one-time payment.

export async function upgradeFreemiumMember(communityId: string, userId: string) {
  const community = await prisma.community.findUnique({
    where: { id: communityId },
    include: { pricing: true },
  });

  if (!community) throw new AppError("Community not found", 404);

  if (community.pricingModel !== "FREEMIUM") {
    throw new AppError("This community does not support freemium upgrades", 400);
  }

  const membership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId, communityId } },
  });

  if (!membership || membership.status !== "ACTIVE") {
    throw new AppError("You must be an active member to upgrade", 403);
  }

  if (membership.membershipTier === "PAID") {
    throw new AppError("You are already on the paid tier", 409);
  }

  const amount = Number(community.pricing?.upgradePrice);
  if (!amount) {
    throw new AppError("No upgrade price configured for this community", 400);
  }

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { email: true, firstname: true },
  });

  const result = paymentService.createPaymentIntent(communityId, userId, amount);

  const [updatedMembership] = await prisma.$transaction([
    prisma.membership.update({
      where: { id: membership.id },
      data: { membershipTier: "PAID" },
    }),
    prisma.subscription.create({
      data: {
        membershipId: membership.id,
        externalId: result.paymentIntentId,
        subscriptionStart: new Date(),
        subscriptionEnd: null,
        pricePaid: amount,
        paymentStatus: "SUCCESS",
      },
    }),
  ]);

  if (user) {
    await sendPaymentConfirmationEmail(user.email, user.firstname, community.name, amount);
  }

  return updatedMembership;
}

// ─── Get Community Members ────────────────────────────────────────────────────

export async function getCommunityMembers(communityId: string) {
  const community = await prisma.community.findUnique({ where: { id: communityId } });
  if (!community) throw new AppError("Community not found", 404);

  return prisma.membership.findMany({
    where: { communityId, status: "ACTIVE" },
    select: {
      id: true,
      role: true,
      membershipTier: true,
      joinedAt: true,
      user: {
        select: { id: true, firstname: true, lastname: true, avatarUrl: true },
      },
    },
    orderBy: [{ role: "asc" }, { joinedAt: "asc" }],
  });
}

// ─── Get Community Posts ───────────────────────────────────────────────────────
// Posts are public to all active members — no tier-based gating on the forum.

export async function getCommunityPosts(communityId: string, userId?: string, q?: string, page = 1, limit = 30) {
  const community = await prisma.community.findUnique({ where: { id: communityId } });
  if (!community) throw new AppError("Community not found", 404);

  const where = {
    communityId,
    ...(q
      ? {
          OR: [
            { title: { contains: q, mode: "insensitive" as const } },
            { content: { contains: q, mode: "insensitive" as const } },
          ],
        }
      : {}),
  };

  const [posts, total] = await Promise.all([
    prisma.post.findMany({
      where,
      orderBy: [{ isPinned: "desc" }, { createdAt: "desc" }],
      skip: (page - 1) * limit,
      take: limit,
      include: {
        author: { select: { id: true, firstname: true, lastname: true } },
        _count: { select: { comments: true, likes: true } },
        ...(userId ? { likes: { where: { userId }, select: { id: true } } } : {}),
      },
    }),
    prisma.post.count({ where }),
  ]);

  return {
    posts: posts.map((p) => ({
      ...p,
      likedByMe: userId ? (p as any).likes?.length > 0 : false,
      likes: undefined,
    })),
    total,
    page,
    limit,
    totalPages: Math.ceil(total / limit),
  };
}

// ─── List Communities ──────────────────────────────────────────────────────────
// Public endpoint — returns all non-private communities with basic info.

export async function listCommunities(page = 1, limit = 30) {
  const where = { isPrivate: false };
  const [communities, total] = await Promise.all([
    prisma.community.findMany({
      where,
      orderBy: { createdAt: "desc" },
      skip: (page - 1) * limit,
      take: limit,
      select: {
        id: true,
        name: true,
        description: true,
        pricingModel: true,
        platformPlan: true,
        isPrivate: true,
        coverUrl: true,
        iconUrl: true,
        createdAt: true,
        creator: { select: { id: true, firstname: true, lastname: true } },
        _count: { select: { memberships: true } },
      },
    }),
    prisma.community.count({ where }),
  ]);
  return { communities, total, page, limit, totalPages: Math.ceil(total / limit) };
}

// ─── Get My Membership ────────────────────────────────────────────────────────

export async function getMyMembership(communityId: string, userId: string) {
  const community = await prisma.community.findUnique({ where: { id: communityId } });
  if (!community) throw new AppError("Community not found", 404);

  const membership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId, communityId } },
    select: { id: true, role: true, status: true, membershipTier: true, joinedAt: true },
  });

  return membership ?? null;
}

// ─── Get Community By ID ───────────────────────────────────────────────────────
// Public — returns full community info including pricing config.

export async function getCommunityById(communityId: string) {
  const community = await prisma.community.findUnique({
    where: { id: communityId },
    include: {
      pricing: true,
      creator: { select: { id: true, firstname: true, lastname: true } },
      media: { orderBy: { order: "asc" } },
      _count: { select: { memberships: true, posts: true } },
    },
  });

  if (!community) throw new AppError("Community not found", 404);
  return community;
}

// ─── Add Community Media ───────────────────────────────────────────────────────
// Creator only. Appends a media item (image URL or video URL) to the gallery.

export async function addCommunityMedia(
  communityId: string,
  requesterId: string,
  input: { url: string; type: "IMAGE" | "VIDEO"; thumbnailUrl?: string | null }
) {
  await assertCreator(communityId, requesterId);

  const last = await prisma.communityMedia.findFirst({
    where: { communityId },
    orderBy: { order: "desc" },
    select: { order: true },
  });

  return prisma.communityMedia.create({
    data: {
      communityId,
      url: input.url,
      type: input.type,
      thumbnailUrl: input.thumbnailUrl ?? null,
      order: (last?.order ?? -1) + 1,
    },
  });
}

// ─── Delete Community Media ────────────────────────────────────────────────────
// Creator only. Removes a media item by ID.

export async function deleteCommunityMedia(
  communityId: string,
  requesterId: string,
  mediaId: string
) {
  await assertCreator(communityId, requesterId);

  const item = await prisma.communityMedia.findFirst({
    where: { id: mediaId, communityId },
  });
  if (!item) throw new AppError("Media item not found", 404);

  await prisma.communityMedia.delete({ where: { id: mediaId } });
}

// ─── Update Community ──────────────────────────────────────────────────────────
// Creator only. Allows updating name, description, and isPrivate.

export async function updateCommunity(
  communityId: string,
  requesterId: string,
  input: { name?: string; description?: string; isPrivate?: boolean; coverUrl?: string | null; iconUrl?: string | null }
) {
  await assertCreator(communityId, requesterId);

  if (input.name !== undefined && !input.name.trim()) {
    throw new AppError("Community name cannot be empty", 400);
  }

  return prisma.community.update({
    where: { id: communityId },
    data: {
      ...(input.name !== undefined && { name: input.name.trim() }),
      ...(input.description !== undefined && { description: input.description }),
      ...(input.isPrivate !== undefined && { isPrivate: input.isPrivate }),
      ...(input.coverUrl !== undefined && { coverUrl: input.coverUrl }),
      ...(input.iconUrl !== undefined && { iconUrl: input.iconUrl }),
    },
  });
}

// ─── Delete Community ──────────────────────────────────────────────────────────
// Creator only. Cascades to memberships, subscriptions, pricing, and posts.

export async function deleteCommunity(communityId: string, requesterId: string) {
  await assertCreator(communityId, requesterId);

  // Delete memberships first (Membership has no onDelete: Cascade on the community relation).
  // Subscriptions cascade from Membership automatically.
  await prisma.membership.deleteMany({ where: { communityId } });
  await prisma.community.delete({ where: { id: communityId } });
}

// ─── Leave Community ──────────────────────────────────────────────────────────
// Sets membership to CANCELLED. For SUBSCRIPTION communities, also cancels the
// active subscription via the payment service.
// Creators cannot leave their own community.

export async function leaveCommunity(communityId: string, userId: string) {
  const community = await prisma.community.findUnique({ where: { id: communityId } });
  if (!community) throw new AppError("Community not found", 404);

  if (community.creatorId === userId) {
    throw new AppError("As the creator you cannot leave your own community", 400);
  }

  const membership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId, communityId } },
    include: {
      subscriptions: {
        where: { paymentStatus: "SUCCESS" },
        orderBy: { createdAt: "desc" },
        take: 1,
      },
    },
  });

  if (!membership || membership.status === "BANNED") {
    throw new AppError("Membership not found", 404);
  }

  if (membership.status === "CANCELLED") {
    throw new AppError("You have already left this community", 400);
  }

  // Cancel the active recurring subscription when leaving a SUBSCRIPTION community
  if (community.pricingModel === "SUBSCRIPTION") {
    const activeSub = membership.subscriptions[0];
    if (activeSub?.externalId) {
      paymentService.cancelSubscription(activeSub.externalId);
    }
  }

  return prisma.membership.update({
    where: { id: membership.id },
    data: { status: "CANCELLED" },
  });
}

// ─── Renew Subscription ───────────────────────────────────────────────────────
// Only valid for SUBSCRIPTION communities.
// Works for both ACTIVE members (early renewal) and EXPIRED members (re-activation).
// If billingInterval is not provided, the existing interval is reused.
// New subscriptionEnd extends from the previous end date (if still in the future)
// or from now (if already expired), so no days are lost on early renewal.

export async function renewSubscription(
  communityId: string,
  userId: string,
  billingInterval?: BillingInterval
) {
  const community = await prisma.community.findUnique({
    where: { id: communityId },
    include: { pricing: true },
  });

  if (!community) throw new AppError("Community not found", 404);

  if (community.pricingModel !== "SUBSCRIPTION") {
    throw new AppError("This community does not use a subscription pricing model", 400);
  }

  const membership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId, communityId } },
    include: {
      subscriptions: {
        orderBy: { createdAt: "desc" },
        take: 1,
      },
    },
  });

  if (!membership || membership.status === "BANNED" || membership.status === "CANCELLED") {
    throw new AppError("No eligible membership found to renew", 404);
  }

  const latestSub = membership.subscriptions[0] ?? null;

  // Use provided interval, fall back to the interval on the last subscription
  const interval = billingInterval ?? latestSub?.billingInterval ?? null;
  if (!interval) {
    throw new AppError("billingInterval (MONTHLY | YEARLY) is required", 400);
  }

  const amount =
    interval === "MONTHLY"
      ? Number(community.pricing?.monthlyPrice)
      : Number(community.pricing?.yearlyPrice);

  if (!amount) {
    throw new AppError(`No ${interval.toLowerCase()} price configured for this community`, 400);
  }

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { email: true, firstname: true },
  });

  const result = paymentService.createSubscription(communityId, userId, interval);

  const now = new Date();
  // Extend from the previous end date if it hasn't passed yet (early renewal = no lost days)
  const baseDate =
    latestSub?.subscriptionEnd && latestSub.subscriptionEnd > now
      ? latestSub.subscriptionEnd
      : now;

  const subscriptionEnd =
    interval === "MONTHLY"
      ? new Date(baseDate.getTime() + 30 * 24 * 60 * 60 * 1000)
      : new Date(baseDate.getTime() + 365 * 24 * 60 * 60 * 1000);

  const renewResult = await prisma.$transaction(async (tx) => {
    const newSub = await tx.subscription.create({
      data: {
        membershipId: membership.id,
        externalId: result.subscriptionId,
        billingInterval: interval,
        subscriptionStart: now,
        subscriptionEnd,
        pricePaid: amount,
        paymentStatus: "SUCCESS",
      },
    });

    // Re-activate membership if the expiry job had already marked it EXPIRED
    if (membership.status === "EXPIRED") {
      await tx.membership.update({
        where: { id: membership.id },
        data: { status: "ACTIVE" },
      });
    }

    return { subscription: newSub, subscriptionEnd };
  });

  if (user) {
    await sendPaymentConfirmationEmail(user.email, user.firstname, community.name, amount, interval);
  }

  return renewResult;
}

// ─── Get Subscription Details ──────────────────────────────────────────────────
// Returns the member's current membership state, latest subscription record,
// and the community's configured pricing — useful for the account/billing UI.

export async function getSubscriptionDetails(communityId: string, userId: string) {
  const community = await prisma.community.findUnique({
    where: { id: communityId },
    include: { pricing: true },
  });

  if (!community) throw new AppError("Community not found", 404);

  const membership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId, communityId } },
    include: {
      subscriptions: {
        orderBy: { createdAt: "desc" },
        take: 1,
      },
    },
  });

  if (!membership) throw new AppError("You are not a member of this community", 404);

  const latestSub = membership.subscriptions[0] ?? null;
  const now = new Date();

  return {
    membershipId: membership.id,
    status: membership.status,
    membershipTier: membership.membershipTier,
    pricingModel: community.pricingModel,
    subscription: latestSub
      ? {
          id: latestSub.id,
          billingInterval: latestSub.billingInterval,
          subscriptionStart: latestSub.subscriptionStart,
          subscriptionEnd: latestSub.subscriptionEnd,
          pricePaid: latestSub.pricePaid,
          paymentStatus: latestSub.paymentStatus,
          isExpired: latestSub.subscriptionEnd ? latestSub.subscriptionEnd < now : false,
        }
      : null,
    pricing: community.pricing,
  };
}

// ─── Helpers ───────────────────────────────────────────────────────────────────

async function assertCreator(communityId: string, userId: string): Promise<Community> {
  const community = await prisma.community.findUnique({ where: { id: communityId } });
  if (!community) throw new AppError("Community not found", 404);
  if (community.creatorId !== userId) {
    throw new AppError("Only the community creator can perform this action", 403);
  }
  return community;
}
