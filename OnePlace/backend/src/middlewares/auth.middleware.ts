import type { Request, Response, NextFunction } from "express";
import { verifyJwt } from "../utils/token.utils.js";
import { AppError } from "../utils/AppError.js";
import { prisma } from "../database/db.js";
import type { UserRole, CommunityRole } from "@prisma/client";

// Verifies JWT from httpOnly cookie, checks suspension, and attaches user to req
export async function protect(req: Request, res: Response, next: NextFunction): Promise<void> {
  const token: string | undefined = req.cookies["token"];

  if (!token) {
    return next(new AppError("Authentication required. Please log in.", 401));
  }

  try {
    const payload = verifyJwt(token);

    const user = await prisma.user.findUnique({
      where: { id: payload.userId },
      select: { id: true, role: true, isSuspended: true },
    });

    if (!user) {
      return next(new AppError("Invalid or expired session. Please log in again.", 401));
    }

    if (user.isSuspended) {
      return next(new AppError("Your account has been suspended.", 403));
    }

    req.user = { id: user.id, role: user.role };
    next();
  } catch {
    next(new AppError("Invalid or expired session. Please log in again.", 401));
  }
}

// Restricts access to specific platform-level roles (UserRole)
export function requireRole(...roles: UserRole[]) {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      return next(new AppError("Authentication required.", 401));
    }
    if (!roles.includes(req.user.role)) {
      return next(new AppError("You do not have permission to perform this action.", 403));
    }
    next();
  };
}

// Restricts access to specific community-level roles (CommunityRole).
// Reads communityId from req.params.id or req.params.communityId.
// Must run after protect().
export function requireCommunityRole(...roles: CommunityRole[]) {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) return next(new AppError("Authentication required.", 401));

      const rawId = req.params['id'] ?? req.params['communityId'];
      if (!rawId || typeof rawId !== 'string') {
        return next(new AppError("Community ID is required.", 400));
      }
      const communityId = rawId;

      const membership = await prisma.membership.findUnique({
        where: { userId_communityId: { userId, communityId } },
      });

      if (!membership || membership.status !== "ACTIVE") {
        return next(new AppError("You are not an active member of this community.", 403));
      }

      if (!roles.includes(membership.role)) {
        return next(new AppError("You do not have the required community role.", 403));
      }

      next();
    } catch (err) {
      next(err);
    }
  };
}
