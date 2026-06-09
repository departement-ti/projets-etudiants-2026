import { Router } from "express";
import { protect } from "../middlewares/auth.middleware.js";
import {
  getNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
} from "../controllers/notification.controller.js";

const notificationRouter = Router();

notificationRouter.use(protect);

notificationRouter.get("/", getNotifications);
notificationRouter.get("/unread-count", getUnreadCount);
notificationRouter.patch("/read-all", markAllAsRead);
notificationRouter.patch("/:id/read", markAsRead);

export default notificationRouter;
