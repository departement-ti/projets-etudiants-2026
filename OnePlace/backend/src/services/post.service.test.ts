import { describe, it, expect, vi, beforeEach } from "vitest";

vi.mock("../database/db.js", () => ({
  prisma: {
    community: { findUnique: vi.fn() },
    membership: { findUnique: vi.fn() },
    post: { create: vi.fn(), findUnique: vi.fn(), delete: vi.fn() },
    comment: { create: vi.fn(), findUnique: vi.fn(), findMany: vi.fn(), delete: vi.fn() },
  },
}));

import { prisma } from "../database/db.js";
import * as postService from "./post.service.js";

function makeCommunity(overrides: Record<string, unknown> = {}) {
  return { id: "c-1", name: "Test Community", creatorId: "creator-1", ...overrides };
}

function makeMembership(overrides: Record<string, unknown> = {}) {
  return { id: "m-1", userId: "user-1", communityId: "c-1", role: "member", status: "ACTIVE", ...overrides };
}

function makePost(overrides: Record<string, unknown> = {}) {
  return {
    id: "p-1",
    communityId: "c-1",
    authorId: "user-1",
    title: "Hello",
    content: "World",
    type: "TEXT",
    category: null,
    isPinned: false,
    community: { creatorId: "creator-1" },
    ...overrides,
  };
}

function makeComment(overrides: Record<string, unknown> = {}) {
  return {
    id: "cmt-1",
    postId: "p-1",
    authorId: "user-1",
    content: "Nice post",
    post: { communityId: "c-1" },
    ...overrides,
  };
}

// ─── createPost ───────────────────────────────────────────────────────────────

describe("postService.createPost", () => {
  beforeEach(() => vi.clearAllMocks());

  it("creates a post for an active member", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity() as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(makeMembership() as any);
    vi.mocked(prisma.post.create).mockResolvedValue(makePost() as any);

    const result = await postService.createPost("c-1", "user-1", { title: "Hello", content: "World" });
    expect(result.title).toBe("Hello");
  });

  it("throws 400 when title is missing", async () => {
    await expect(
      postService.createPost("c-1", "user-1", { title: "", content: "World" })
    ).rejects.toMatchObject({ statusCode: 400 });
  });

  it("throws 400 when content is missing", async () => {
    await expect(
      postService.createPost("c-1", "user-1", { title: "Hello", content: "" })
    ).rejects.toMatchObject({ statusCode: 400 });
  });

  it("throws 404 when community does not exist", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(null);
    await expect(
      postService.createPost("ghost", "user-1", { title: "Hello", content: "World" })
    ).rejects.toMatchObject({ statusCode: 404 });
  });

  it("throws 403 when user is not an active member", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity() as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(null);
    await expect(
      postService.createPost("c-1", "user-1", { title: "Hello", content: "World" })
    ).rejects.toMatchObject({ statusCode: 403 });
  });

  it("creates a post with a category", async () => {
    vi.mocked(prisma.community.findUnique).mockResolvedValue(makeCommunity() as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(makeMembership() as any);
    vi.mocked(prisma.post.create).mockResolvedValue(makePost({ category: "Get Advice" }) as any);

    const result = await postService.createPost("c-1", "user-1", { title: "Hello", content: "World", category: "Get Advice" });
    expect(result.category).toBe("Get Advice");
  });
});

// ─── getPostById ──────────────────────────────────────────────────────────────

describe("postService.getPostById", () => {
  beforeEach(() => vi.clearAllMocks());

  it("returns the post", async () => {
    vi.mocked(prisma.post.findUnique).mockResolvedValue(makePost() as any);
    const result = await postService.getPostById("p-1");
    expect(result.id).toBe("p-1");
  });

  it("throws 404 when post does not exist", async () => {
    vi.mocked(prisma.post.findUnique).mockResolvedValue(null);
    await expect(postService.getPostById("ghost")).rejects.toMatchObject({ statusCode: 404 });
  });
});

// ─── deletePost ───────────────────────────────────────────────────────────────

describe("postService.deletePost", () => {
  beforeEach(() => vi.clearAllMocks());

  it("allows the author to delete their post", async () => {
    vi.mocked(prisma.post.findUnique).mockResolvedValue(makePost({ authorId: "user-1" }) as any);
    vi.mocked(prisma.post.delete).mockResolvedValue(makePost() as any);

    await expect(postService.deletePost("p-1", "user-1")).resolves.toBeUndefined();
    expect(prisma.post.delete).toHaveBeenCalled();
  });

  it("allows the community creator to delete any post", async () => {
    vi.mocked(prisma.post.findUnique).mockResolvedValue(makePost({ authorId: "other-user" }) as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(makeMembership({ userId: "creator-1", role: "creator" }) as any);
    vi.mocked(prisma.post.delete).mockResolvedValue(makePost() as any);

    await expect(postService.deletePost("p-1", "creator-1")).resolves.toBeUndefined();
  });

  it("throws 403 when a non-author regular member tries to delete", async () => {
    vi.mocked(prisma.post.findUnique).mockResolvedValue(makePost({ authorId: "other-user" }) as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(makeMembership({ role: "member" }) as any);

    await expect(postService.deletePost("p-1", "user-1")).rejects.toMatchObject({ statusCode: 403 });
  });

  it("throws 404 when post does not exist", async () => {
    vi.mocked(prisma.post.findUnique).mockResolvedValue(null);
    await expect(postService.deletePost("ghost", "user-1")).rejects.toMatchObject({ statusCode: 404 });
  });
});

// ─── createComment ────────────────────────────────────────────────────────────

describe("postService.createComment", () => {
  beforeEach(() => vi.clearAllMocks());

  it("creates a comment for an active member", async () => {
    vi.mocked(prisma.post.findUnique).mockResolvedValue(makePost() as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(makeMembership() as any);
    vi.mocked(prisma.comment.create).mockResolvedValue(makeComment() as any);

    const result = await postService.createComment("p-1", "user-1", "Nice post");
    expect(result.content).toBe("Nice post");
  });

  it("throws 400 when content is empty", async () => {
    await expect(postService.createComment("p-1", "user-1", "")).rejects.toMatchObject({ statusCode: 400 });
  });

  it("throws 404 when post does not exist", async () => {
    vi.mocked(prisma.post.findUnique).mockResolvedValue(null);
    await expect(postService.createComment("ghost", "user-1", "Hello")).rejects.toMatchObject({ statusCode: 404 });
  });

  it("throws 403 when user is not an active member", async () => {
    vi.mocked(prisma.post.findUnique).mockResolvedValue(makePost() as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(null);
    await expect(postService.createComment("p-1", "user-1", "Hello")).rejects.toMatchObject({ statusCode: 403 });
  });
});

// ─── getPostComments ──────────────────────────────────────────────────────────

describe("postService.getPostComments", () => {
  beforeEach(() => vi.clearAllMocks());

  it("returns comments for an existing post", async () => {
    vi.mocked(prisma.post.findUnique).mockResolvedValue(makePost() as any);
    vi.mocked(prisma.comment.findMany).mockResolvedValue([makeComment()] as any);

    const result = await postService.getPostComments("p-1");
    expect(result).toHaveLength(1);
  });

  it("throws 404 when post does not exist", async () => {
    vi.mocked(prisma.post.findUnique).mockResolvedValue(null);
    await expect(postService.getPostComments("ghost")).rejects.toMatchObject({ statusCode: 404 });
  });
});

// ─── deleteComment ────────────────────────────────────────────────────────────

describe("postService.deleteComment", () => {
  beforeEach(() => vi.clearAllMocks());

  it("allows the author to delete their comment", async () => {
    vi.mocked(prisma.comment.findUnique).mockResolvedValue(makeComment({ authorId: "user-1" }) as any);
    vi.mocked(prisma.comment.delete).mockResolvedValue(makeComment() as any);

    await expect(postService.deleteComment("cmt-1", "user-1")).resolves.toBeUndefined();
    expect(prisma.comment.delete).toHaveBeenCalled();
  });

  it("throws 403 when a non-author regular member tries to delete", async () => {
    vi.mocked(prisma.comment.findUnique).mockResolvedValue(makeComment({ authorId: "other" }) as any);
    vi.mocked(prisma.membership.findUnique).mockResolvedValue(makeMembership({ role: "member" }) as any);

    await expect(postService.deleteComment("cmt-1", "user-1")).rejects.toMatchObject({ statusCode: 403 });
  });

  it("throws 404 when comment does not exist", async () => {
    vi.mocked(prisma.comment.findUnique).mockResolvedValue(null);
    await expect(postService.deleteComment("ghost", "user-1")).rejects.toMatchObject({ statusCode: 404 });
  });
});
