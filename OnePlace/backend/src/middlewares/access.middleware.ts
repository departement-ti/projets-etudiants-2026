import type { Request, Response, NextFunction } from "express";
import { prisma } from "../database/db.js";
import { AppError } from "../utils/AppError.js";

/**
 * Validates that the authenticated user has access to the community at :id,
 * based on its pricingModel. Attaches req.communityMembership for downstream use.
 *
 * Rules:
 *   FREE         → membership ACTIVE
 *   FREEMIUM     → membership ACTIVE (premium content filtered by checkPremiumContent)
 *   SUBSCRIPTION → membership ACTIVE + latest subscription SUCCESS + not expired
 *   ONE_TIME     → membership ACTIVE + subscription SUCCESS (no expiry)
 *
 * Must run after protect() so req.user is populated.
 */
export async function checkCommunityAccess(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const rawId = req.params['id'] ?? req.params['communityId'];
    if (!rawId || typeof rawId !== 'string') {
      return next(new AppError("Community ID is required", 400));
    }
    const communityId = rawId;
    const userId = req.user?.id;

    if (!userId) return next(new AppError("Authentication required", 401));

    const community = await prisma.community.findUnique({
      where: { id: communityId },
    });

    if (!community) return next(new AppError("Community not found", 404));

    const membership = await prisma.membership.findUnique({
      where: { userId_communityId: { userId, communityId } },
      include: {
        subscriptions: {
          orderBy: { createdAt: "desc" },
          take: 1,
        },
      },
    });

    if (!membership || membership.status !== "ACTIVE") {
      return next(new AppError("You are not an active member of this community", 403));
    }

    // Creators and admins always have full access regardless of subscription state
    if (membership.role === "creator" || membership.role === "admin") {
      req.communityMembership = {
        id: membership.id,
        membershipTier: membership.membershipTier,
        status: membership.status,
      };
      return next();
    }

    switch (community.pricingModel) {
      case "FREE":
        break; // ACTIVE membership is sufficient

      case "FREEMIUM":
        break; // ACTIVE membership is sufficient; premium posts filtered separately

      case "SUBSCRIPTION": {
        const sub = membership.subscriptions[0];
        if (!sub || sub.paymentStatus !== "SUCCESS") {
          return next(new AppError("An active subscription is required", 403));
        }
        if (sub.subscriptionEnd && sub.subscriptionEnd < new Date()) {
          return next(new AppError("Your subscription has expired", 403));
        }
        break;
      }

      case "ONE_TIME": {
        const payment = membership.subscriptions[0];
        if (!payment || payment.paymentStatus !== "SUCCESS") {
          return next(new AppError("Payment is required to access this community", 403));
        }
        break;
      }

      default:
        return next(new AppError("Unknown pricing model", 500));
    }

    req.communityMembership = {
      id: membership.id,
      membershipTier: membership.membershipTier,
      status: membership.status,
    };

    next();
  } catch (err) {
    next(err);
  }
}

/**
 * Guards course access based on CourseAccessType.
 * Must run after checkCommunityAccess (relies on req.communityMembership).
 * Route param for the course must be :courseId.
 *
 * OPEN        → always allowed
 * BUY_NOW     → requires a CoursePurchase record for this user+course
 * TIME_UNLOCK → requires membership.joinedAt + course.unlockAfterDays <= now
 * PRIVATE     → requires membershipTier = PAID
 * LEVEL_UNLOCK → not yet implemented, treated as OPEN for now
 */
export async function checkCourseAccess(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const courseId = req.params.courseId as string;
    const userId = req.user?.id;

    if (!userId) return next(new AppError("Authentication required", 401));

    const course = await prisma.course.findUnique({ where: { id: courseId } });
    if (!course) return next(new AppError("Course not found", 404));

    const creatorCheck = await prisma.membership.findUnique({
      where: { userId_communityId: { userId, communityId: course.communityId } },
      select: { role: true },
    });
    if (creatorCheck && ["creator", "admin"].includes(creatorCheck.role)) {
      return next();
    }

    switch (course.accessType) {
      case "OPEN":
      case "LEVEL_UNLOCK":
        break;

      case "BUY_NOW": {
        const purchase = await prisma.coursePurchase.findUnique({
          where: { userId_courseId: { userId, courseId } },
        });
        if (!purchase) {
          return next(new AppError("Purchase required to access this course", 403));
        }
        break;
      }

      case "TIME_UNLOCK": {
        const membership = await prisma.membership.findUnique({
          where: { userId_communityId: { userId, communityId: course.communityId } },
        });
        if (!membership) return next(new AppError("Membership not found", 403));

        const daysSinceJoin = Math.floor(
          (Date.now() - membership.joinedAt.getTime()) / (1000 * 60 * 60 * 24)
        );
        if (daysSinceJoin < (course.unlockAfterDays ?? 0)) {
          return next(
            new AppError(
              `This course unlocks ${course.unlockAfterDays} days after joining`,
              403
            )
          );
        }
        break;
      }

      case "PRIVATE": {
        if (req.communityMembership?.membershipTier !== "PAID") {
          return next(new AppError("This course is only available to paid members", 403));
        }
        break;
      }

      default:
        return next(new AppError("Unknown course access type", 500));
    }

    next();
  } catch (err) {
    next(err);
  }
}
