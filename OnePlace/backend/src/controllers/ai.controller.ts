import type { Request, Response, NextFunction } from "express";
import * as aiService from "../services/ai.service.js";

export async function transcribeVideo(req: Request, res: Response, next: NextFunction) {
  try {
    const { videoUrl } = req.body;
    const userId = req.user!.id;
    const data = await aiService.transcribeVideoUrl(videoUrl, userId);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

export async function communityQA(req: Request, res: Response, next: NextFunction) {
  try {
    const communityId = req.params.communityId as string;
    const userId = req.user!.id;
    const { question, history = [] } = req.body;
    const data = await aiService.answerCommunityQuestion(communityId, userId, question, history);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

export async function postAssist(req: Request, res: Response, next: NextFunction) {
  try {
    const { content, action } = req.body;
    const data = await aiService.improvePost(content, action);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

export async function sentimentAnalysis(req: Request, res: Response, next: NextFunction) {
  try {
    const communityId = req.params.communityId as string;
    const requesterId = req.user!.id;
    const data = await aiService.getSentimentAnalysis(communityId, requesterId);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

export async function reindexCommunity(req: Request, res: Response, next: NextFunction) {
  try {
    const communityId = req.params.communityId as string;
    const requesterId = req.user!.id;
    // Kick off in background — respond immediately so the request doesn't time out
    res.json({ success: true, message: "Reindexing started in background" });
    aiService.reindexCommunity(communityId, requesterId).catch((err) =>
      console.error("[reindex] Error:", err)
    );
  } catch (err) {
    next(err);
  }
}

export async function generateQuiz(req: Request, res: Response, next: NextFunction) {
  try {
    const lessonId = req.params.lessonId as string;
    const userId = req.user!.id;
    const data = await aiService.generateLessonQuiz(lessonId, userId);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

export async function progressCoach(req: Request, res: Response, next: NextFunction) {
  try {
    const communityId = req.params.communityId as string;
    const userId = req.user!.id;
    const data = await aiService.getProgressCoach(communityId, userId);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

export async function communityMatchmaking(req: Request, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.id;
    const data = await aiService.getCommunityMatches(userId);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

export async function churnRisk(req: Request, res: Response, next: NextFunction) {
  try {
    const communityId = req.params.communityId as string;
    const requesterId = req.user!.id;
    const data = await aiService.getChurnRisk(communityId, requesterId);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

export async function analyticsSummary(req: Request, res: Response, next: NextFunction) {
  try {
    const communityId = req.params.communityId as string;
    const requesterId = req.user!.id;
    const data = await aiService.getAnalyticsSummary(communityId, requesterId);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}
