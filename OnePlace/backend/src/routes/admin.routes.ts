import { Router } from "express";
import { protect, requireRole } from "../middlewares/auth.middleware.js";
import {
  listUsers,
  listCommunities,
  suspendUser,
  unsuspendUser,
} from "../controllers/admin.controller.js";
import { getPlatformAnalytics } from "../controllers/analytics.controller.js";

const adminRouter = Router();

// All admin routes require authentication + moderator role
adminRouter.use(protect, requireRole("moderator"));

adminRouter.get("/users", listUsers);
adminRouter.get("/communities", listCommunities);
adminRouter.put("/users/:id/suspend", suspendUser);
adminRouter.put("/users/:id/unsuspend", unsuspendUser);
adminRouter.get("/analytics", getPlatformAnalytics);

export default adminRouter;
