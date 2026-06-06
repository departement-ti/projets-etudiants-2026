import { Router } from "express";
import { protect } from "../middlewares/auth.middleware.js";
import { presign } from "../controllers/upload.controller.js";

const uploadRouter = Router();

// POST /api/v1/upload/presign
// Any authenticated user can request a presigned URL.
// The frontend uploads directly to S3/R2 — files never pass through our server.
uploadRouter.post("/presign", protect, presign);

export default uploadRouter;
