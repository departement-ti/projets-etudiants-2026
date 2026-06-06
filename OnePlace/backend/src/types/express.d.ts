import type { MembershipStatus, MembershipTier, UserRole } from "@prisma/client";

declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string;
        role: UserRole;
      };
      // Attached by checkCommunityAccess middleware
      communityMembership?: {
        id: string;
        membershipTier: MembershipTier;
        status: MembershipStatus;
      };
    }
  }
}

export {};
