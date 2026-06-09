import Groq from "groq-sdk";
import { prisma } from "../database/db.js";
import { AppError } from "../utils/AppError.js";
import { GROQ_API_KEY } from "../config/env.js";
import { getVideoTranscript } from "./transcription.service.js";
import { getEmbedding, cosineSimilarity, EMBED_THROTTLE_MS } from "./embedding.service.js";

const groq = new Groq({ apiKey: GROQ_API_KEY });

async function ask(prompt: string): Promise<string> {
  const res = await groq.chat.completions.create({
    model: "llama-3.3-70b-versatile",
    messages: [{ role: "user", content: prompt }],
    temperature: 0.7,
  });
  return res.choices[0]?.message?.content?.trim() ?? "";
}

function parseJSON<T>(text: string): T {
  const clean = text.replace(/^```[a-z]*\n?/i, "").replace(/\n?```$/m, "").trim();
  return JSON.parse(clean) as T;
}

async function requireCreatorOrAdmin(communityId: string, userId: string) {
  const membership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId, communityId } },
  });
  if (!membership || !["creator", "admin"].includes(membership.role)) {
    throw new AppError("Only creators and admins can use this feature", 403);
  }
}

// ─── 1. Study Buddy: Generate Quiz from Lesson ────────────────────────────────

export async function generateLessonQuiz(lessonId: string, userId: string) {
  const lesson = await prisma.lesson.findUnique({
    where: { id: lessonId },
    include: { section: { include: { course: { select: { communityId: true } } } } },
  });
  if (!lesson) throw new AppError("Lesson not found", 404);

  const communityId = lesson.section.course.communityId;
  const membership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId, communityId } },
  });
  if (!membership || membership.status !== "ACTIVE") {
    throw new AppError("You must be an active member to use the study buddy", 403);
  }

  // Use cached transcript, or transcribe video now and cache it
  let transcript = lesson.transcript ?? "";
  let transcriptSource = "cached";

  if (!transcript && lesson.videoUrl) {
    console.log(`[AI] No transcript for lesson "${lesson.title}", transcribing video...`);
    const result = await getVideoTranscript(lesson.videoUrl);
    transcript = result.transcript;
    transcriptSource = result.source;

    if (transcript) {
      // Save transcript and generate embedding in parallel
      const embedding = await getEmbedding(`${lesson.title}\n${transcript}`).catch(() => [] as number[]);
      await prisma.lesson.update({
        where: { id: lessonId },
        data: { transcript, embedding },
      });
      console.log(`[AI] Transcript saved (${transcriptSource}, ${transcript.length} chars)`);
    }
  }

  const context = [
    `Lesson title: ${lesson.title}`,
    lesson.description ? `Description: ${lesson.description}` : "",
    lesson.content ? `Content: ${lesson.content.slice(0, 2000)}` : "",
    transcript ? `Transcript: ${transcript.slice(0, 4000)}` : "",
  ]
    .filter(Boolean)
    .join("\n");

  const hasRealContent = !!(lesson.content || transcript);

  const prompt = hasRealContent
    ? `You are a quiz generator for an online learning platform.
Based on the following lesson content, generate exactly 5 multiple-choice questions to test the student's understanding of what was actually taught.

${context}

Respond ONLY with valid JSON in this exact format (no markdown, no explanation):
{
  "questions": [
    {
      "question": "...",
      "options": ["A. ...", "B. ...", "C. ...", "D. ..."],
      "correctIndex": 0,
      "explanation": "..."
    }
  ]
}`
    : `You are a quiz generator for an online learning platform.
The lesson is titled "${lesson.title}". Generate 5 general knowledge multiple-choice questions on this topic that would be relevant to someone studying it.

Respond ONLY with valid JSON in this exact format (no markdown, no explanation):
{
  "questions": [
    {
      "question": "...",
      "options": ["A. ...", "B. ...", "C. ...", "D. ..."],
      "correctIndex": 0,
      "explanation": "..."
    }
  ]
}`;

  try {
    const text = await ask(prompt);
    const result = parseJSON<{ questions: { question: string; options: string[]; correctIndex: number; explanation: string }[] }>(text);
    return { ...result, transcriptSource };
  } catch (err) {
    console.error("[AI] Quiz error:", err);
    throw new AppError("Failed to generate quiz", 502);
  }
}

// ─── 0. Transcribe Video URL ──────────────────────────────────────────────────

export async function transcribeVideoUrl(videoUrl: string, userId: string) {
  if (!videoUrl?.trim()) throw new AppError("videoUrl is required", 400);
  const result = await getVideoTranscript(videoUrl);
  return result;
}

// ─── 2. Progress Coach ────────────────────────────────────────────────────────

export async function getProgressCoach(communityId: string, userId: string) {
  const membership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId, communityId } },
    include: { user: { select: { firstname: true } } },
  });
  if (!membership || membership.status !== "ACTIVE") {
    throw new AppError("Active membership required", 403);
  }

  const lastProgress = await prisma.lessonProgress.findFirst({
    where: { userId, completedAt: { not: null }, lesson: { section: { course: { communityId } } } },
    orderBy: { completedAt: "desc" },
    include: {
      lesson: {
        select: {
          title: true,
          section: { select: { course: { select: { title: true } } } },
        },
      },
    },
  });

  const allLessonIds = await prisma.lesson.findMany({
    where: { section: { course: { communityId } }, isPublished: true },
    select: { id: true },
  });
  const completedCount = await prisma.lessonProgress.count({
    where: { userId, lessonId: { in: allLessonIds.map((l) => l.id) }, completedAt: { not: null } },
  });

  const daysSinceActive = lastProgress?.completedAt
    ? Math.floor((Date.now() - lastProgress.completedAt.getTime()) / (1000 * 60 * 60 * 24))
    : null;

  const prompt = `You are a friendly progress coach on a learning platform.

Student: ${membership.user.firstname}
Days since last lesson completed: ${daysSinceActive ?? "never started"}
Last lesson: ${lastProgress?.lesson.title ?? "none"}
Last course: ${lastProgress?.lesson.section.course.title ?? "none"}
Total lessons completed: ${completedCount} / ${allLessonIds.length}

Write a short, warm, motivating message (2-3 sentences) to encourage the student to continue learning.
If they haven't started, welcome them. If inactive 5+ days, gently nudge them back. If progressing well, celebrate it.
Plain text only, no markdown.`;

  const message = await ask(prompt);
  return {
    message,
    daysSinceActive,
    completedCount,
    totalLessons: allLessonIds.length,
    lastLesson: lastProgress?.lesson.title ?? null,
    lastCourse: lastProgress?.lesson.section.course.title ?? null,
  };
}

// ─── 3. Community Matchmaking ─────────────────────────────────────────────────

export async function getCommunityMatches(userId: string) {
  const myMemberships = await prisma.membership.findMany({
    where: { userId, status: "ACTIVE" },
    include: { community: { select: { id: true, name: true, description: true } } },
  });

  const myIds = myMemberships.map((m) => m.community.id);

  const candidates = await prisma.community.findMany({
    where: { id: { notIn: myIds }, isPrivate: false },
    select: {
      id: true,
      name: true,
      description: true,
      pricingModel: true,
      _count: { select: { memberships: true } },
    },
    take: 20,
    orderBy: { createdAt: "desc" },
  });

  if (candidates.length === 0) return { matches: [] };

  const myContext = myMemberships
    .map((m) => `- ${m.community.name}: ${m.community.description ?? "no description"}`)
    .join("\n");

  const candidateContext = candidates
    .map((c, i) => `${i}. [${c.id}] ${c.name}: ${c.description ?? "no description"} (${c._count.memberships} members, ${c.pricingModel})`)
    .join("\n");

  const prompt = `You are a community recommendation engine.

User's current communities:
${myContext || "None yet"}

Available communities (format: index. [id] name: description):
${candidateContext}

Pick the top 3 best matches for this user based on interest overlap.
Respond ONLY with valid JSON (no markdown):
{
  "matches": [
    { "id": "...", "reason": "one sentence why this is a good match" }
  ]
}`;

  try {
    const text = await ask(prompt);
    const parsed = parseJSON<{ matches: { id: string; reason: string }[] }>(text);
    return {
      matches: parsed.matches
        .map((m) => {
          const community = candidates.find((c) => c.id === m.id);
          return community
            ? { id: community.id, name: community.name, description: community.description, pricingModel: community.pricingModel, memberCount: community._count.memberships, reason: m.reason }
            : null;
        })
        .filter(Boolean),
    };
  } catch (err) {
    console.error("[AI] Matchmaking error:", err);
    throw new AppError("Failed to generate recommendations", 502);
  }
}

// ─── 4. Churn Prediction ──────────────────────────────────────────────────────

export async function getChurnRisk(communityId: string, requesterId: string) {
  await requireCreatorOrAdmin(communityId, requesterId);

  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

  const members = await prisma.membership.findMany({
    where: { communityId, status: "ACTIVE" },
    include: {
      user: { select: { id: true, firstname: true, lastname: true, email: true } },
      subscriptions: { orderBy: { createdAt: "desc" }, take: 1, select: { subscriptionEnd: true, paymentStatus: true } },
    },
  });

  const memberIds = members.map((m) => m.userId);

  const [recentPosts, recentComments] = await Promise.all([
    prisma.post.groupBy({
      by: ["authorId"],
      where: { communityId, authorId: { in: memberIds }, createdAt: { gte: thirtyDaysAgo } },
      _count: { id: true },
    }),
    prisma.comment.groupBy({
      by: ["authorId"],
      where: { post: { communityId }, authorId: { in: memberIds }, createdAt: { gte: thirtyDaysAgo } },
      _count: { id: true },
    }),
  ]);

  const postMap = Object.fromEntries(recentPosts.map((p) => [p.authorId, p._count.id]));
  const commentMap = Object.fromEntries(recentComments.map((c) => [c.authorId, c._count.id]));

  const atRisk = members
    .map((m) => {
      const posts = postMap[m.userId] ?? 0;
      const comments = commentMap[m.userId] ?? 0;
      const sub = m.subscriptions[0];
      const expiringIn7Days = !!(
        sub?.subscriptionEnd &&
        sub.subscriptionEnd >= new Date() &&
        sub.subscriptionEnd <= new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
      );
      const riskScore =
        (posts === 0 ? 40 : posts < 2 ? 20 : 0) +
        (comments === 0 ? 30 : comments < 3 ? 15 : 0) +
        (expiringIn7Days ? 30 : 0);
      return {
        userId: m.userId,
        name: `${m.user.firstname} ${m.user.lastname}`,
        email: m.user.email,
        posts,
        comments,
        expiringIn7Days,
        riskScore,
        riskLevel: riskScore >= 70 ? "high" : riskScore >= 40 ? "medium" : "low",
      };
    })
    .filter((m) => m.riskLevel !== "low")
    .sort((a, b) => b.riskScore - a.riskScore)
    .slice(0, 20);

  if (atRisk.length === 0) return { atRisk: [], summary: "All members appear engaged — no churn risk detected." };

  const memberContext = atRisk
    .map((m) => `- ${m.name}: ${m.posts} posts, ${m.comments} comments in 30 days, risk: ${m.riskLevel}${m.expiringIn7Days ? ", subscription expiring soon" : ""}`)
    .join("\n");

  const prompt = `You are a retention analyst for an online community platform.
These members are showing churn risk signals in the last 30 days:

${memberContext}

Write a brief summary (2-3 sentences) of the churn situation and one actionable recommendation for the creator.
Plain text only, no markdown.`;

  const summary = await ask(prompt);
  return { atRisk, summary };
}

// ─── 6. AI Q&A Bot — semantic RAG ────────────────────────────────────────────

export async function answerCommunityQuestion(
  communityId: string,
  userId: string,
  question: string,
  history: { role: "user" | "assistant"; content: string }[]
) {
  const membership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId, communityId } },
  });
  if (!membership) throw new AppError("Membership required", 403);
  const isPrivileged = ["creator", "admin"].includes(membership.role);
  if (!isPrivileged && membership.status !== "ACTIVE") {
    throw new AppError("Active membership required", 403);
  }

  // Embed the question, then fetch all community content with their embeddings
  const [questionEmbedding, posts, lessons, knowledgeDocs] = await Promise.all([
    getEmbedding(question),
    prisma.post.findMany({
      where: { communityId },
      select: { title: true, content: true, embedding: true },
      orderBy: { createdAt: "desc" },
    }),
    prisma.lesson.findMany({
      where: { section: { course: { communityId } }, isPublished: true },
      select: { title: true, content: true, transcript: true, embedding: true },
    }),
    prisma.knowledgeDoc.findMany({
      where: { communityId },
      select: { name: true, content: true, embedding: true },
    }),
  ]);

  // Rank by cosine similarity — fall back to recency order (index) when no embedding
  const THRESHOLD = 0.25;

  const topPosts = posts
    .map((p, i) => ({ ...p, score: p.embedding.length ? cosineSimilarity(questionEmbedding, p.embedding) : 1 / (i + 1) }))
    .sort((a, b) => b.score - a.score)
    .filter((p) => p.score >= THRESHOLD)
    .slice(0, 6);

  const topLessons = lessons
    .map((l) => ({ ...l, score: l.embedding.length ? cosineSimilarity(questionEmbedding, l.embedding) : 0 }))
    .sort((a, b) => b.score - a.score)
    .filter((l) => l.score >= THRESHOLD)
    .slice(0, 4);

  const topDocs = knowledgeDocs
    .map((d) => ({ ...d, score: d.embedding.length ? cosineSimilarity(questionEmbedding, d.embedding) : 0 }))
    .sort((a, b) => b.score - a.score)
    .filter((d) => d.score >= THRESHOLD)
    .slice(0, 4);

  const chunks = [
    ...topPosts.map((p) => `[Post] ${p.title}: ${p.content.slice(0, 400)}`),
    ...topLessons.map((l) => {
      const text = (l.transcript || l.content || "").slice(0, 600);
      return `[Lesson] ${l.title}${text ? `: ${text}` : ""}`;
    }),
    ...topDocs.map((d) => `[Knowledge] ${d.name}: ${d.content.slice(0, 600)}`),
  ];

  const contextBlock =
    chunks.length > 0
      ? chunks.join("\n\n")
      : "No relevant posts or lessons found yet.";

  const systemPrompt = `You are an AI assistant embedded in an online community. Answer member questions using the community knowledge base below.
If the answer isn't clearly in the content, say so honestly and offer general guidance.
Be concise, friendly, and direct. Plain text only.

Knowledge base:
${contextBlock}`;

  const res = await groq.chat.completions.create({
    model: "llama-3.3-70b-versatile",
    messages: [
      { role: "system", content: systemPrompt },
      ...history.map((h) => ({ role: h.role as "user" | "assistant", content: h.content })),
      { role: "user", content: question },
    ],
    temperature: 0.4,
    max_tokens: 512,
  });

  return {
    answer:
      res.choices[0]?.message?.content?.trim() ??
      "Sorry, I couldn't generate a response.",
  };
}

// ─── Reindex: generate embeddings for all community content ───────────────────

export async function reindexCommunity(communityId: string, requesterId: string) {
  await requireCreatorOrAdmin(communityId, requesterId);

  const [posts, lessons, knowledgeDocs] = await Promise.all([
    prisma.post.findMany({
      where: { communityId },
      select: { id: true, title: true, content: true, embedding: true },
    }),
    prisma.lesson.findMany({
      where: { section: { course: { communityId } }, isPublished: true },
      select: { id: true, title: true, content: true, transcript: true, embedding: true },
    }),
    prisma.knowledgeDoc.findMany({
      where: { communityId },
      select: { id: true, name: true, content: true, embedding: true },
    }),
  ]);

  let indexed = 0;

  for (const p of posts) {
    try {
      const text = `${p.title}\n${p.content}`;
      const embedding = await getEmbedding(text);
      await prisma.post.update({ where: { id: p.id }, data: { embedding } });
      indexed++;
      await new Promise((r) => setTimeout(r, EMBED_THROTTLE_MS));
    } catch (err) {
      console.error(`[reindex] Post ${p.id} failed:`, err);
    }
  }

  for (const l of lessons) {
    try {
      const text = `${l.title}\n${l.transcript || l.content || ""}`;
      const embedding = await getEmbedding(text);
      await prisma.lesson.update({ where: { id: l.id }, data: { embedding } });
      indexed++;
      await new Promise((r) => setTimeout(r, EMBED_THROTTLE_MS));
    } catch (err) {
      console.error(`[reindex] Lesson ${l.id} failed:`, err);
    }
  }

  for (const d of knowledgeDocs) {
    try {
      const embedding = await getEmbedding(d.content);
      await prisma.knowledgeDoc.update({ where: { id: d.id }, data: { embedding } });
      indexed++;
      await new Promise((r) => setTimeout(r, EMBED_THROTTLE_MS));
    } catch (err) {
      console.error(`[reindex] KnowledgeDoc ${d.id} failed:`, err);
    }
  }

  console.log(`[reindex] Community ${communityId}: ${indexed} items indexed`);
  return { indexed, posts: posts.length, lessons: lessons.length, knowledgeDocs: knowledgeDocs.length };
}

// ─── 7. Smart Post Assistant ──────────────────────────────────────────────────

export async function improvePost(
  content: string,
  action: "improve" | "fix_grammar" | "expand"
) {
  if (!content.trim()) throw new AppError("Content is required", 400);

  const instructions: Record<string, string> = {
    improve:
      "Improve the wording and clarity. Keep the same ideas but make it more engaging and well-written.",
    fix_grammar:
      "Fix all grammar, spelling, and punctuation errors. Keep the original meaning and tone intact.",
    expand:
      "Expand this text with more detail, context, and depth. Make it about 2x longer while staying focused.",
  };

  const prompt = `${instructions[action]}

Original text:
${content}

Respond with ONLY the improved text — no explanation, no intro, no meta-commentary.`;

  const improved = await ask(prompt);
  return { improved };
}

// ─── 8. Sentiment Analysis ────────────────────────────────────────────────────

export async function getSentimentAnalysis(communityId: string, requesterId: string) {
  await requireCreatorOrAdmin(communityId, requesterId);

  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  const posts = await prisma.post.findMany({
    where: { communityId, createdAt: { gte: thirtyDaysAgo } },
    select: { title: true, content: true },
    orderBy: { createdAt: "desc" },
    take: 50,
  });

  if (posts.length === 0) {
    return {
      overall: "neutral",
      breakdown: { positive: 0, neutral: 100, negative: 0 },
      themes: [],
      summary: "No posts in the last 30 days to analyze.",
      postCount: 0,
    };
  }

  const postContext = posts
    .map((p) => `"${p.title}": ${p.content.slice(0, 200)}`)
    .join("\n");

  const prompt = `You are a sentiment analyst for an online community platform.
Analyze the overall mood and themes of these community posts from the last 30 days:

${postContext}

Respond ONLY with valid JSON (no markdown):
{
  "overall": "positive",
  "breakdown": { "positive": 65, "neutral": 25, "negative": 10 },
  "themes": ["topic1", "topic2", "topic3"],
  "summary": "2-3 sentence plain-text summary of the community mood and key topics"
}`;

  try {
    const text = await ask(prompt);
    const result = parseJSON<{
      overall: string;
      breakdown: { positive: number; neutral: number; negative: number };
      themes: string[];
      summary: string;
    }>(text);
    return { ...result, postCount: posts.length };
  } catch (err) {
    console.error("[AI] Sentiment error:", err);
    throw new AppError("Failed to analyze sentiment", 502);
  }
}


// ─── 5. AI Analytics Summary ──────────────────────────────────────────────────

export async function getAnalyticsSummary(communityId: string, requesterId: string) {
  await requireCreatorOrAdmin(communityId, requesterId);

  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const endOfLastMonth = new Date(now.getFullYear(), now.getMonth(), 0);

  const [memberships, posts, comments, postLikes] = await Promise.all([
    prisma.membership.findMany({
      where: { communityId },
      select: { status: true, joinedAt: true, subscriptions: { where: { paymentStatus: "SUCCESS" }, select: { pricePaid: true, createdAt: true } } },
    }),
    prisma.post.findMany({ where: { communityId, createdAt: { gte: startOfMonth } }, select: { createdAt: true } }),
    prisma.comment.findMany({ where: { post: { communityId }, createdAt: { gte: startOfMonth } }, select: { createdAt: true } }),
    prisma.postLike.findMany({ where: { post: { communityId }, createdAt: { gte: startOfMonth } }, select: { createdAt: true } }),
  ]);

  const totalMembers = memberships.length;
  const activeMembers = memberships.filter((m) => m.status === "ACTIVE").length;
  const newThisMonth = memberships.filter((m) => m.joinedAt >= startOfMonth).length;
  const newLastMonth = memberships.filter((m) => m.joinedAt >= lastMonth && m.joinedAt <= endOfLastMonth).length;
  const allSubs = memberships.flatMap((m) => m.subscriptions);
  const revenueThisMonth = allSubs.filter((s) => s.createdAt >= startOfMonth).reduce((sum, s) => sum + Number(s.pricePaid), 0);
  const revenueLastMonth = allSubs.filter((s) => s.createdAt >= lastMonth && s.createdAt <= endOfLastMonth).reduce((sum, s) => sum + Number(s.pricePaid), 0);
  const totalRevenue = allSubs.reduce((sum, s) => sum + Number(s.pricePaid), 0);
  const growthPct = newLastMonth > 0 ? Math.round(((newThisMonth - newLastMonth) / newLastMonth) * 100) : newThisMonth > 0 ? 100 : 0;

  const prompt = `You are an analytics assistant for an online creator community platform.
Write a clear, concise summary (3-4 sentences) of this month's performance for the community creator.
Use specific numbers. Be honest about trends. End with one actionable insight.
Plain text only, no markdown, no bullet points.

Data:
- Total members: ${totalMembers} (${activeMembers} active)
- New members this month: ${newThisMonth} (last month: ${newLastMonth}, ${growthPct > 0 ? "+" : ""}${growthPct}% change)
- Revenue this month: $${revenueThisMonth.toFixed(2)} (last month: $${revenueLastMonth.toFixed(2)})
- Total revenue: $${totalRevenue.toFixed(2)}
- Posts this month: ${posts.length}
- Comments this month: ${comments.length}
- Likes this month: ${postLikes.length}`;

  const summary = await ask(prompt);
  return {
    summary,
    data: { totalMembers, activeMembers, newThisMonth, newLastMonth, growthPct, revenueThisMonth, revenueLastMonth, totalRevenue, postsThisMonth: posts.length, commentsThisMonth: comments.length, likesThisMonth: postLikes.length },
  };
}
