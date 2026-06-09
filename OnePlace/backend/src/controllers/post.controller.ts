import type { Request, Response, NextFunction } from "express";
import * as postService from "../services/post.service.js";
import type { PostType } from "@prisma/client";

// POST /api/v1/communities/:communityId/posts
export async function createPost(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const post = await postService.createPost(
      req.params.communityId as string,
      req.user!.id,
      req.body as { title: string; content: string; type?: PostType; category?: string }
    );
    res.status(201).json({ success: true, data: { post } });
  } catch (err) {
    next(err);
  }
}

// GET /api/v1/communities/:communityId/posts/:postId
export async function getPostById(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const post = await postService.getPostById(req.params.postId as string, req.user?.id);
    res.status(200).json({ success: true, data: { post } });
  } catch (err) {
    next(err);
  }
}

// POST /api/v1/communities/:communityId/posts/:postId/like
export async function likePost(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    await postService.likePost(req.params.postId as string, req.user!.id);
    res.status(200).json({ success: true });
  } catch (err) {
    next(err);
  }
}

// DELETE /api/v1/communities/:communityId/posts/:postId/like
export async function unlikePost(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    await postService.unlikePost(req.params.postId as string, req.user!.id);
    res.status(200).json({ success: true });
  } catch (err) {
    next(err);
  }
}

// PATCH /api/v1/communities/:communityId/posts/:postId/pin
export async function togglePinPost(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const post = await postService.togglePinPost(req.params.postId as string, req.user!.id);
    res.status(200).json({ success: true, data: { post } });
  } catch (err) {
    next(err);
  }
}

// DELETE /api/v1/communities/:communityId/posts/:postId
export async function deletePost(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    await postService.deletePost(req.params.postId as string, req.user!.id);
    res.status(200).json({ success: true, message: "Post deleted." });
  } catch (err) {
    next(err);
  }
}

// POST /api/v1/communities/:communityId/posts/:postId/comments
export async function createComment(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const comment = await postService.createComment(
      req.params.postId as string,
      req.user!.id,
      req.body.content
    );
    res.status(201).json({ success: true, data: { comment } });
  } catch (err) {
    next(err);
  }
}

// GET /api/v1/communities/:communityId/posts/:postId/comments
export async function getPostComments(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const comments = await postService.getPostComments(req.params.postId as string);
    res.status(200).json({ success: true, data: { comments } });
  } catch (err) {
    next(err);
  }
}

// DELETE /api/v1/communities/:communityId/posts/:postId/comments/:commentId
export async function deleteComment(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    await postService.deleteComment(req.params.commentId as string, req.user!.id);
    res.status(200).json({ success: true, message: "Comment deleted." });
  } catch (err) {
    next(err);
  }
}
