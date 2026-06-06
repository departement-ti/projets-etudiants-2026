import { Router } from "express";
import { protect } from "../middlewares/auth.middleware.js";
import { getMe, updateMe, getMyCommunities } from "../controllers/user.controller.js";

const userRouter = Router();

userRouter.get("/me", protect, getMe);
userRouter.put("/me", protect, updateMe);
userRouter.get("/me/communities", protect, getMyCommunities);

export default userRouter;
