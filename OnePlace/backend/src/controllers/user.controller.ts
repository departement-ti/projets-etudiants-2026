import type { Request, Response, NextFunction } from "express";
import * as userService from "../services/user.service.js";

// GET /api/v1/user/me
export async function getMe(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const user = await userService.getProfile(req.user!.id);
    res.status(200).json({ success: true, data: { user } });
  } catch (err) {
    next(err);
  }
}

// PUT /api/v1/user/me
export async function updateMe(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const user = await userService.updateProfile(req.user!.id, req.body);
    res.status(200).json({ success: true, data: { user } });
  } catch (err) {
    next(err);
  }
}

// GET /api/v1/user/me/communities
export async function getMyCommunities(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const communities = await userService.getUserCommunities(req.user!.id);
    res.status(200).json({ success: true, data: { communities } });
  } catch (err) {
    next(err);
  }
}
