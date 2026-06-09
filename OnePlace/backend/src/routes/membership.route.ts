import { Router } from "express";
import { protect } from "../middlewares/auth.middleware.js";
import {
  getMyMemberships,
  getUpcomingRenewals,
  getMembershipById,
  getCommunityMembers,
  exportCommunityMembers,
  banMember,
  unbanMember,
  setMemberRole,
} from "../controllers/membership.controller.js";

const membershipRouter = Router();

// Specific named routes must come before /:id to avoid param conflicts
membershipRouter.get("/me", protect, getMyMemberships);
membershipRouter.get("/upcoming", protect, getUpcomingRenewals);
membershipRouter.get("/community/:communityId", protect, getCommunityMembers);
membershipRouter.get("/community/:communityId/export", protect, exportCommunityMembers);
membershipRouter.put("/community/:communityId/members/:userId/ban", protect, banMember);
membershipRouter.put("/community/:communityId/members/:userId/unban", protect, unbanMember);
membershipRouter.put("/community/:communityId/members/:userId/role", protect, setMemberRole);
membershipRouter.get("/:id", protect, getMembershipById);

export default membershipRouter;
