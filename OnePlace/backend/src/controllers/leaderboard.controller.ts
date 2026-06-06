import type { Request, Response, NextFunction } from "express";
import { getLeaderboard } from "../services/points.service.js";

export async function getCommunityLeaderboard(req: Request, res: Response, next: NextFunction) {
  try {
    const communityId = req.params["communityId"] as string;
    const data = await getLeaderboard(communityId, req.user!.id);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}
