import type { Request, Response, NextFunction } from "express";
import * as communityService from "../services/community.service.js";
import type { PlatformPlan, PricingModel, BillingInterval } from "@prisma/client";

// GET /api/v1/communities
export async function listCommunities(
  _req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const page = parseInt(String(_req.query.page ?? 1), 10) || 1;
    const limit = parseInt(String(_req.query.limit ?? 30), 10) || 30;
    const result = await communityService.listCommunities(page, limit);
    res.status(200).json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

// GET /api/v1/communities/:id
export async function getCommunityById(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const community = await communityService.getCommunityById(req.params.id as string);
    res.status(200).json({ success: true, data: { community } });
  } catch (err) {
    next(err);
  }
}

// PUT /api/v1/communities/:id
export async function updateCommunity(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const community = await communityService.updateCommunity(
      req.params.id as string,
      req.user!.id,
      req.body
    );
    res.status(200).json({ success: true, data: { community } });
  } catch (err) {
    next(err);
  }
}

// DELETE /api/v1/communities/:id
export async function deleteCommunity(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    await communityService.deleteCommunity(req.params.id as string, req.user!.id);
    res.status(200).json({ success: true, message: "Community deleted." });
  } catch (err) {
    next(err);
  }
}

// POST /api/v1/communities
export async function createCommunity(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { name, platformPlan } = req.body as { name: string; platformPlan: PlatformPlan };
    const community = await communityService.createCommunity({
      name,
      platformPlan,
      creatorId: req.user!.id,
    });
    res.status(201).json({
      success: true,
      message: "Community created. Head to the dashboard to complete configuration.",
      data: {
        community,
        redirectTo: `/dashboard/communities/${community.id}`,
      },
    });
  } catch (err) {
    next(err);
  }
}

// PUT /api/v1/communities/:id/pricing
export async function configurePricing(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const pricing = await communityService.configurePricing(
      req.params.id as string,
      req.user!.id,
      req.body
    );
    res.status(200).json({ success: true, data: { pricing } });
  } catch (err) {
    next(err);
  }
}

// PUT /api/v1/communities/:id/pricing-model
export async function changePricingModel(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { pricingModel } = req.body as { pricingModel: PricingModel };
    const community = await communityService.changePricingModel(
      req.params.id as string,
      req.user!.id,
      pricingModel
    );
    res.status(200).json({ success: true, data: { community } });
  } catch (err) {
    next(err);
  }
}

// POST /api/v1/communities/:id/media
export async function addCommunityMedia(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { url, type, thumbnailUrl } = req.body as { url: string; type: "IMAGE" | "VIDEO"; thumbnailUrl?: string };
    const media = await communityService.addCommunityMedia(
      req.params.id as string,
      req.user!.id,
      { url, type, thumbnailUrl }
    );
    res.status(201).json({ success: true, data: { media } });
  } catch (err) {
    next(err);
  }
}

// DELETE /api/v1/communities/:id/media/:mediaId
export async function deleteCommunityMedia(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    await communityService.deleteCommunityMedia(
      req.params.id as string,
      req.user!.id,
      req.params.mediaId as string
    );
    res.status(200).json({ success: true });
  } catch (err) {
    next(err);
  }
}

// GET /api/v1/communities/:id/my-membership
export async function getMyMembership(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const membership = await communityService.getMyMembership(
      req.params.id as string,
      req.user!.id
    );
    res.status(200).json({ success: true, data: { membership } });
  } catch (err) {
    next(err);
  }
}

// POST /api/v1/communities/:id/join
export async function joinCommunity(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { billingInterval } = (req.body ?? {}) as { billingInterval?: BillingInterval };
    const membership = await communityService.joinCommunity(
      req.params.id as string,
      req.user!.id,
      billingInterval
    );
    res.status(201).json({ success: true, data: { membership } });
  } catch (err) {
    next(err);
  }
}

// POST /api/v1/communities/:id/upgrade
export async function upgradeFreemium(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const membership = await communityService.upgradeFreemiumMember(
      req.params.id as string,
      req.user!.id
    );
    res.status(200).json({ success: true, data: { membership } });
  } catch (err) {
    next(err);
  }
}

// DELETE /api/v1/communities/:id/leave
export async function leaveCommunity(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    await communityService.leaveCommunity(req.params.id as string, req.user!.id);
    res.status(200).json({ success: true, message: "You have left the community." });
  } catch (err) {
    next(err);
  }
}

// POST /api/v1/communities/:id/renew
export async function renewSubscription(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { billingInterval } = (req.body ?? {}) as { billingInterval?: BillingInterval };
    const result = await communityService.renewSubscription(
      req.params.id as string,
      req.user!.id,
      billingInterval
    );
    res.status(200).json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

// GET /api/v1/communities/:id/subscription
export async function getSubscriptionDetails(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const details = await communityService.getSubscriptionDetails(
      req.params.id as string,
      req.user!.id
    );
    res.status(200).json({ success: true, data: details });
  } catch (err) {
    next(err);
  }
}

// GET /api/v1/communities/:id/members
export async function getCommunityMembers(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const members = await communityService.getCommunityMembers(req.params.id as string);
    res.status(200).json({ success: true, data: { members } });
  } catch (err) {
    next(err);
  }
}

// GET /api/v1/communities/:communityId/posts  (nested router — param is communityId)
export async function getCommunityPosts(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const q = req.query.q as string | undefined;
    const page = parseInt(String(req.query.page ?? 1), 10) || 1;
    const limit = parseInt(String(req.query.limit ?? 30), 10) || 30;
    const result = await communityService.getCommunityPosts(req.params.communityId as string, req.user?.id, q || undefined, page, limit);
    res.status(200).json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}
