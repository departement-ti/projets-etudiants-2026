import type { Request, Response, NextFunction } from "express";
import * as membershipService from "../services/membership.service.js";

// GET /api/v1/memberships/me
export async function getMyMemberships(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const memberships = await membershipService.getMyMemberships(req.user!.id);
    res.status(200).json({ success: true, data: { memberships } });
  } catch (err) {
    next(err);
  }
}

// GET /api/v1/memberships/upcoming
export async function getUpcomingRenewals(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const memberships = await membershipService.getUpcomingRenewals(req.user!.id);
    res.status(200).json({ success: true, data: { memberships } });
  } catch (err) {
    next(err);
  }
}

// GET /api/v1/memberships/:id
export async function getMembershipById(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const membership = await membershipService.getMembershipById(
      req.params.id as string,
      req.user!.id
    );
    res.status(200).json({ success: true, data: { membership } });
  } catch (err) {
    next(err);
  }
}

// PUT /api/v1/memberships/community/:communityId/members/:userId/ban
export async function banMember(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const membership = await membershipService.banMember(
      req.params.communityId as string,
      req.params.userId as string,
      req.user!.id
    );
    res.status(200).json({ success: true, data: { membership } });
  } catch (err) {
    next(err);
  }
}

// PUT /api/v1/memberships/community/:communityId/members/:userId/unban
export async function unbanMember(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const membership = await membershipService.unbanMember(
      req.params.communityId as string,
      req.params.userId as string,
      req.user!.id
    );
    res.status(200).json({ success: true, data: { membership } });
  } catch (err) {
    next(err);
  }
}

// PUT /api/v1/memberships/community/:communityId/members/:userId/role
export async function setMemberRole(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const { role } = req.body as { role: unknown };
    if (role !== "admin" && role !== "member") {
      res.status(400).json({ success: false, message: "role must be 'admin' or 'member'" });
      return;
    }
    const membership = await membershipService.setMemberRole(
      req.params.communityId as string,
      req.params.userId as string,
      req.user!.id,
      role
    );
    res.status(200).json({ success: true, data: { membership } });
  } catch (err) {
    next(err);
  }
}

// GET /api/v1/memberships/community/:communityId/export
export async function exportCommunityMembers(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const csv = await membershipService.exportMembersAsCsv(
      req.params.communityId as string,
      req.user!.id
    );
    res.setHeader("Content-Type", "text/csv");
    res.setHeader(
      "Content-Disposition",
      `attachment; filename="members-${req.params.communityId}.csv"`
    );
    res.status(200).send(csv);
  } catch (err) {
    next(err);
  }
}

// GET /api/v1/memberships/community/:communityId
export async function getCommunityMembers(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const members = await membershipService.getCommunityMembers(
      req.params.communityId as string,
      req.user!.id
    );
    res.status(200).json({ success: true, data: { members } });
  } catch (err) {
    next(err);
  }
}
