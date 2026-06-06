import { Router } from "express";
import { protect } from "../middlewares/auth.middleware.js";
import { checkCommunityAccess } from "../middlewares/access.middleware.js";
import { listEvents, createEvent, deleteEvent } from "../controllers/event.controller.js";

const eventRouter = Router({ mergeParams: true });

eventRouter.get("/", protect, checkCommunityAccess, listEvents);
eventRouter.post("/", protect, createEvent);
eventRouter.delete("/:eventId", protect, deleteEvent);

export default eventRouter;
