import { prisma } from "../database/db.js";
import { AppError } from "../utils/AppError.js";
import { getEmbedding } from "./embedding.service.js";

async function requireCreatorOrAdmin(communityId: string, userId: string) {
  const membership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId, communityId } },
  });
  if (!membership || !["creator", "admin"].includes(membership.role)) {
    throw new AppError("Only creators and admins can manage the knowledge base", 403);
  }
}

function embedDoc(docId: string, text: string) {
  getEmbedding(text)
    .then((embedding) => prisma.knowledgeDoc.update({ where: { id: docId }, data: { embedding } }))
    .catch((err) => console.error("[embed] KnowledgeDoc embedding failed:", err));
}

export async function listDocs(communityId: string, userId: string) {
  await requireCreatorOrAdmin(communityId, userId);
  return prisma.knowledgeDoc.findMany({
    where: { communityId },
    select: { id: true, name: true, createdAt: true, embedding: true },
    orderBy: { createdAt: "desc" },
  });
}

export async function createDoc(
  communityId: string,
  userId: string,
  input: { name: string; content: string }
) {
  if (!input.name?.trim()) throw new AppError("name is required", 400);
  if (!input.content?.trim()) throw new AppError("content is required", 400);

  await requireCreatorOrAdmin(communityId, userId);

  const doc = await prisma.knowledgeDoc.create({
    data: {
      communityId,
      name: input.name.trim(),
      content: input.content.trim(),
    },
  });

  embedDoc(doc.id, doc.content);
  return doc;
}

export async function deleteDoc(docId: string, communityId: string, userId: string) {
  const doc = await prisma.knowledgeDoc.findUnique({ where: { id: docId } });
  if (!doc || doc.communityId !== communityId) throw new AppError("Document not found", 404);

  await requireCreatorOrAdmin(communityId, userId);
  await prisma.knowledgeDoc.delete({ where: { id: docId } });
}
