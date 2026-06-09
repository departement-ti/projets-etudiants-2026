import { prisma } from "../database/db.js";
import { AppError } from "../utils/AppError.js";
import type { PostType } from "@prisma/client";
import { createNotification } from "./notification.service.js";
import { addPoints } from "./points.service.js";
import { getEmbedding } from "./embedding.service.js";

async function embedPost(postId: string, title: string, content: string) {
  try {
    const embedding = await getEmbedding(`${title}\n${content}`);
    await prisma.post.update({ where: { id: postId }, data: { embedding } });
  } catch (err) {
    console.error(`[embedding] Post ${postId}:`, err);
  }
}

// ─── Create Post ───────────────────────────────────────────────────────────────
// Any active member can post.

export async function createPost(
  communityId: string,
  authorId: string,
  input: { title: string; content: string; type?: PostType; category?: string }
) {
  if (!input.title?.trim()) throw new AppError("title is required", 400);
  if (!input.content?.trim()) throw new AppError("content is required", 400);

  const community = await prisma.community.findUnique({ where: { id: communityId } });
  if (!community) throw new AppError("Community not found", 404);

  const membership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId: authorId, communityId } },
  });

  if (!membership || membership.status !== "ACTIVE") {
    throw new AppError("You must be an active member to post", 403);
  }

  const post = await prisma.post.create({
    data: {
      communityId,
      authorId,
      title: input.title.trim(),
      content: input.content.trim(),
      type: input.type ?? "TEXT",
      category: input.category?.trim() ?? null,
    },
    include: {
      author: { select: { id: true, firstname: true, lastname: true } },
    },
  });

  // Generate semantic embedding (fire-and-forget — doesn't block the response)
  embedPost(post.id, post.title, post.content);

  // Award XP for creating a post (fire-and-forget)
  addPoints(authorId, communityId, "POST_CREATED").catch(() => {});

  // Notify creator and admins about the new post (skip if author is creator/admin)
  const adminMembers = await prisma.membership.findMany({
    where: {
      communityId,
      role: { in: ["creator", "admin"] },
      status: "ACTIVE",
      userId: { not: authorId },
    },
    select: { userId: true },
  });

  const authorName = `${post.author.firstname} ${post.author.lastname}`;
  for (const m of adminMembers) {
    createNotification({
      userId: m.userId,
      type: "NEW_POST",
      title: "New post",
      body: `${authorName} posted: ${post.title}`,
      link: `/communities/${communityId}/community`,
    }).catch(() => {});
  }

  return post;
}

// ─── Get Post By ID ────────────────────────────────────────────────────────────

export async function getPostById(postId: string, userId?: string) {
  const post = await prisma.post.findUnique({
    where: { id: postId },
    include: {
      author: { select: { id: true, firstname: true, lastname: true } },
      _count: { select: { comments: true, likes: true } },
      ...(userId ? { likes: { where: { userId }, select: { id: true } } } : {}),
    },
  });

  if (!post) throw new AppError("Post not found", 404);

  return {
    ...post,
    likedByMe: userId ? (post as any).likes?.length > 0 : false,
    likes: undefined,
  };
}

// ─── Like / Unlike Post ────────────────────────────────────────────────────────

export async function likePost(postId: string, userId: string) {
  await prisma.postLike.createMany({
    data: [{ postId, userId }],
    skipDuplicates: true,
  });
}

export async function unlikePost(postId: string, userId: string) {
  await prisma.postLike.deleteMany({ where: { postId, userId } });
}

// ─── Toggle Pin Post ───────────────────────────────────────────────────────────
// Community creator only. Pinned posts float to the top of the feed.

export async function togglePinPost(postId: string, requesterId: string) {
  const post = await prisma.post.findUnique({
    where: { id: postId },
    include: { community: { select: { creatorId: true } } },
  });

  if (!post) throw new AppError("Post not found", 404);
  if (post.community.creatorId !== requesterId) {
    throw new AppError("Only the community creator can pin posts", 403);
  }

  return prisma.post.update({
    where: { id: postId },
    data: { isPinned: !post.isPinned },
  });
}

// ─── Delete Post ───────────────────────────────────────────────────────────────
// Author, community creator, or community admin may delete.

export async function deletePost(postId: string, requesterId: string) {
  const post = await prisma.post.findUnique({
    where: { id: postId },
    include: { community: { select: { creatorId: true } } },
  });

  if (!post) throw new AppError("Post not found", 404);

  const isAuthor = post.authorId === requesterId;

  if (!isAuthor) {
    const membership = await prisma.membership.findUnique({
      where: { userId_communityId: { userId: requesterId, communityId: post.communityId } },
    });
    const canModerate = membership && ["creator", "admin"].includes(membership.role);
    if (!canModerate) {
      throw new AppError("You do not have permission to delete this post", 403);
    }
  }

  await prisma.post.delete({ where: { id: postId } });
}

// ─── Create Comment ────────────────────────────────────────────────────────────

export async function createComment(
  postId: string,
  authorId: string,
  content: string
) {
  if (!content?.trim()) throw new AppError("content is required", 400);

  const post = await prisma.post.findUnique({ where: { id: postId } });
  if (!post) throw new AppError("Post not found", 404);

  // Caller must be an active member of the community the post belongs to
  const membership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId: authorId, communityId: post.communityId } },
  });

  if (!membership || membership.status !== "ACTIVE") {
    throw new AppError("You must be an active member to comment", 403);
  }

  const comment = await prisma.comment.create({
    data: { postId, authorId, content: content.trim() },
    include: {
      author: { select: { id: true, firstname: true, lastname: true } },
    },
  });

  // Award XP for commenting (fire-and-forget)
  addPoints(authorId, post.communityId, "COMMENT_CREATED").catch(() => {});

  // Notify the post author if they're not the commenter
  if (post.authorId !== authorId) {
    const authorName = `${comment.author.firstname} ${comment.author.lastname}`;
    createNotification({
      userId: post.authorId,
      type: "NEW_COMMENT",
      title: "New comment",
      body: `${authorName} commented on your post: ${post.title}`,
      link: `/communities/${post.communityId}/post/${postId}`,
    }).catch(() => {});
  }

  return comment;
}

// ─── Get Post Comments ─────────────────────────────────────────────────────────

export async function getPostComments(postId: string) {
  const post = await prisma.post.findUnique({ where: { id: postId } });
  if (!post) throw new AppError("Post not found", 404);

  return prisma.comment.findMany({
    where: { postId },
    orderBy: { createdAt: "asc" },
    include: {
      author: { select: { id: true, firstname: true, lastname: true } },
    },
  });
}

// ─── Delete Comment ────────────────────────────────────────────────────────────
// Author, community creator, or community admin may delete.

export async function deleteComment(commentId: string, requesterId: string) {
  const comment = await prisma.comment.findUnique({
    where: { id: commentId },
    include: { post: { select: { communityId: true } } },
  });

  if (!comment) throw new AppError("Comment not found", 404);

  const isAuthor = comment.authorId === requesterId;

  if (!isAuthor) {
    const membership = await prisma.membership.findUnique({
      where: {
        userId_communityId: { userId: requesterId, communityId: comment.post.communityId },
      },
    });
    const canModerate = membership && ["creator", "admin"].includes(membership.role);
    if (!canModerate) {
      throw new AppError("You do not have permission to delete this comment", 403);
    }
  }

  await prisma.comment.delete({ where: { id: commentId } });
}
