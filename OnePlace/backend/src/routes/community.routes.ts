import { Router } from "express";
import { protect } from "../middlewares/auth.middleware.js";
import { checkCommunityAccess } from "../middlewares/access.middleware.js";
import courseRouter from "./course.routes.js";
import eventRouter from "./event.routes.js";
import {
  createPost,
  getPostById,
  deletePost,
  togglePinPost,
  createComment,
  getPostComments,
  deleteComment,
  likePost,
  unlikePost,
} from "../controllers/post.controller.js";
import {
  listCommunities,
  getCommunityById,
  getMyMembership,
  createCommunity,
  updateCommunity,
  deleteCommunity,
  configurePricing,
  changePricingModel,
  joinCommunity,
  upgradeFreemium,
  leaveCommunity,
  renewSubscription,
  getSubscriptionDetails,
  getCommunityPosts,
  getCommunityMembers,
  addCommunityMedia,
  deleteCommunityMedia,
} from "../controllers/community.controller.js";
import { getCommunityAnalytics } from "../controllers/analytics.controller.js";
import { getCommunityLeaderboard } from "../controllers/leaderboard.controller.js";

const communityRouter = Router();

// ─── Community CRUD ────────────────────────────────────────────────────────────
communityRouter.get("/", listCommunities);
communityRouter.get("/:id", getCommunityById);
communityRouter.get("/:id/my-membership", protect, getMyMembership);
communityRouter.post("/", protect, createCommunity);
communityRouter.put("/:id", protect, updateCommunity);
communityRouter.delete("/:id", protect, deleteCommunity);

// ─── Analytics (creator/admin — enforced in service) ──────────────────────────
communityRouter.get("/:id/analytics", protect, getCommunityAnalytics);
communityRouter.get("/:id/members", protect, checkCommunityAccess, getCommunityMembers);

// ─── Media gallery (creator only — enforced in service) ───────────────────────
communityRouter.post("/:id/media", protect, addCommunityMedia);
communityRouter.delete("/:id/media/:mediaId", protect, deleteCommunityMedia);

// ─── Dashboard configuration (creator only — enforced in service) ──────────────
communityRouter.put("/:id/pricing", protect, configurePricing);
communityRouter.put("/:id/pricing-model", protect, changePricingModel);

// ─── Member actions ────────────────────────────────────────────────────────────
// join: open to any authenticated user who is not yet a member
communityRouter.post("/:id/join", protect, joinCommunity);
// upgrade: freemium only — moves FREE tier member to PAID
communityRouter.post("/:id/upgrade", protect, upgradeFreemium);

// ─── Subscription management ──────────────────────────────────────────────────
// leave: cancels subscription (if SUBSCRIPTION community) + sets membership CANCELLED
communityRouter.delete("/:id/leave", protect, leaveCommunity);
// renew: SUBSCRIPTION communities only — creates a new Subscription record
communityRouter.post("/:id/renew", protect, renewSubscription);
// subscription: returns current membership state, latest sub record, and pricing config
communityRouter.get("/:id/subscription", protect, getSubscriptionDetails);

// ─── Posts & comments (nested under community) ────────────────────────────────
// mergeParams lets the post handlers access :communityId from this router.
const postRouter = Router({ mergeParams: true });

postRouter.get("/", protect, checkCommunityAccess, getCommunityPosts);
postRouter.post("/", protect, checkCommunityAccess, createPost);
postRouter.get("/:postId", protect, checkCommunityAccess, getPostById);
postRouter.delete("/:postId", protect, deletePost)
postRouter.patch("/:postId/pin", protect, togglePinPost);

postRouter.post("/:postId/like", protect, likePost);
postRouter.delete("/:postId/like", protect, unlikePost);

postRouter.get("/:postId/comments", protect, checkCommunityAccess, getPostComments);
postRouter.post("/:postId/comments", protect, checkCommunityAccess, createComment);
postRouter.delete("/:postId/comments/:commentId", protect, deleteComment);

communityRouter.get("/:communityId/leaderboard", protect, checkCommunityAccess, getCommunityLeaderboard);

communityRouter.use("/:communityId/posts", postRouter);
communityRouter.use("/:communityId/courses", courseRouter);
communityRouter.use("/:communityId/events", eventRouter);

export default communityRouter;
