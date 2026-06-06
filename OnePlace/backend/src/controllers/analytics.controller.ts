import type { Request, Response, NextFunction } from "express";
import * as analyticsService from "../services/analytics.service.js";

// GET /api/v1/communities/:id/analytics
export async function getCommunityAnalytics(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const data = await analyticsService.getCommunityAnalytics(
      req.params.id as string,
      req.user!.id
    );
    res.status(200).json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

// GET /api/v1/admin/analytics
export async function getPlatformAnalytics(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const data = await analyticsService.getPlatformAnalytics();
    res.status(200).json({ success: true, data });
  } catch (err) {
    next(err);
  }
}
