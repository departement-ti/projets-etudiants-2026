import { Router } from "express";
import { protect } from "../middlewares/auth.middleware.js";
import { listDocs, createDoc, deleteDoc } from "../controllers/knowledge.controller.js";

const router = Router({ mergeParams: true });

router.use(protect);

router.get("/", listDocs);
router.post("/", createDoc);
router.delete("/:docId", deleteDoc);

export default router;
