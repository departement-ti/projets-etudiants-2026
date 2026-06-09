import type { Request, Response, NextFunction } from "express";
import * as knowledgeService from "../services/knowledge.service.js";

export async function listDocs(req: Request, res: Response, next: NextFunction) {
  try {
    const communityId = req.params.communityId as string;
    const userId = req.user!.id;
    const docs = await knowledgeService.listDocs(communityId, userId);
    res.json({ success: true, data: { docs } });
  } catch (err) {
    next(err);
  }
}

export async function createDoc(req: Request, res: Response, next: NextFunction) {
  try {
    const communityId = req.params.communityId as string;
    const userId = req.user!.id;
    const { name, content } = req.body;
    const doc = await knowledgeService.createDoc(communityId, userId, { name, content });
    res.status(201).json({ success: true, data: { doc } });
  } catch (err) {
    next(err);
  }
}

export async function deleteDoc(req: Request, res: Response, next: NextFunction) {
  try {
    const communityId = req.params.communityId as string;
    const docId = req.params.docId as string;
    const userId = req.user!.id;
    await knowledgeService.deleteDoc(docId, communityId, userId);
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
}
