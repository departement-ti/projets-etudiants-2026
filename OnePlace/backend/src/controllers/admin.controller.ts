import type { Request, Response, NextFunction } from "express";
import * as adminService from "../services/admin.service.js";

// GET /api/v1/admin/users
export async function listUsers(_req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const users = await adminService.listUsers();
    res.status(200).json({ success: true, data: { users } });
  } catch (err) {
    next(err);
  }
}

// GET /api/v1/admin/communities
export async function listCommunities(
  _req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const communities = await adminService.listAllCommunities();
    res.status(200).json({ success: true, data: { communities } });
  } catch (err) {
    next(err);
  }
}

// PUT /api/v1/admin/users/:id/suspend
export async function suspendUser(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const user = await adminService.setSuspended(req.params.id as string, true);
    res.status(200).json({ success: true, message: "User suspended.", data: { user } });
  } catch (err) {
    next(err);
  }
}

// PUT /api/v1/admin/users/:id/unsuspend
export async function unsuspendUser(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const user = await adminService.setSuspended(req.params.id as string, false);
    res.status(200).json({ success: true, message: "User unsuspended.", data: { user } });
  } catch (err) {
    next(err);
  }
}
