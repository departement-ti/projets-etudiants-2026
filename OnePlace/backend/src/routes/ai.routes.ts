import { Router } from "express";
import { protect } from "../middlewares/auth.middleware.js";
import {
  generateQuiz,
  progressCoach,
  communityMatchmaking,
  churnRisk,
  analyticsSummary,
  communityQA,
  postAssist,
  sentimentAnalysis,
  reindexCommunity,
  transcribeVideo,
} from "../controllers/ai.controller.js";

const router = Router();

router.use(protect);

router.post("/lessons/:lessonId/quiz", generateQuiz);
router.get("/communities/:communityId/progress-coach", progressCoach);
router.get("/matchmaking", communityMatchmaking);
router.get("/communities/:communityId/churn-risk", churnRisk);
router.get("/communities/:communityId/analytics-summary", analyticsSummary);
router.post("/communities/:communityId/qa", communityQA);
router.post("/post-assist", postAssist);
router.post("/transcribe", transcribeVideo);
router.get("/communities/:communityId/sentiment", sentimentAnalysis);
router.post("/communities/:communityId/reindex", reindexCommunity);

export default router;
