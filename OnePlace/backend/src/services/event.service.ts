import { prisma } from "../database/db.js";
import { AppError } from "../utils/AppError.js";
import type { EventAccess } from "@prisma/client";

export interface CreateEventInput {
  title: string;
  description?: string;
  coverUrl?: string;
  location?: string;
  startAt: string; // ISO string from client
  duration?: number; // minutes
  timezone?: string;
  isRecurring?: boolean;
  accessType?: EventAccess;
  emailReminder?: boolean;
}

// ─── Daily.co room creation ────────────────────────────────────────────────────

async function createDailyRoom(): Promise<string> {
  const apiKey = process.env.DAILY_API_KEY;
  if (!apiKey) throw new AppError("DAILY_API_KEY is not configured", 500);

  const res = await fetch("https://api.daily.co/v1/rooms", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
    },
  });

  if (!res.ok) throw new AppError("Failed to create call room", 500);
  const data = (await res.json()) as { url: string };
  return data.url;
}

// ─── List events for a community in a given month ──────────────────────────────
export async function listEvents(
  communityId: string,
  year: number,
  month: number // 1-based
) {
  const start = new Date(year, month - 1, 1);
  const end = new Date(year, month, 1);

  return prisma.event.findMany({
    where: {
      communityId,
      startAt: { gte: start, lt: end },
    },
    orderBy: { startAt: "asc" },
    include: {
      creator: { select: { id: true, firstname: true, lastname: true } },
    },
  });
}

// ─── Create event ──────────────────────────────────────────────────────────────
export async function createEvent(
  communityId: string,
  creatorId: string,
  input: CreateEventInput
) {
  if (!input.title?.trim()) throw new AppError("title is required", 400);
  if (!input.startAt) throw new AppError("startAt is required", 400);

  const community = await prisma.community.findUnique({ where: { id: communityId } });
  if (!community) throw new AppError("Community not found", 404);

  const membership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId: creatorId, communityId } },
  });

  if (!membership || !["creator", "admin"].includes(membership.role)) {
    throw new AppError("Only creators and admins can create events", 403);
  }

  const isOnePlaceCall = input.location?.trim() === "OnePlace Call";
  const callRoomUrl = isOnePlaceCall ? await createDailyRoom() : null;

  return prisma.event.create({
    data: {
      communityId,
      creatorId,
      title: input.title.trim(),
      description: input.description?.trim() ?? null,
      coverUrl: input.coverUrl ?? null,
      location: input.location?.trim() ?? null,
      callRoomUrl,
      startAt: new Date(input.startAt),
      duration: input.duration ?? null,
      timezone: input.timezone ?? "UTC",
      isRecurring: input.isRecurring ?? false,
      accessType: input.accessType ?? "ALL_MEMBERS",
      emailReminder: input.emailReminder ?? false,
    },
    include: {
      creator: { select: { id: true, firstname: true, lastname: true } },
    },
  });
}

// ─── Delete event ──────────────────────────────────────────────────────────────
export async function deleteEvent(eventId: string, requesterId: string) {
  const event = await prisma.event.findUnique({ where: { id: eventId } });
  if (!event) throw new AppError("Event not found", 404);

  const membership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId: requesterId, communityId: event.communityId } },
  });

  const canDelete =
    event.creatorId === requesterId ||
    (membership && ["creator", "admin"].includes(membership.role));

  if (!canDelete) throw new AppError("You do not have permission to delete this event", 403);

  await prisma.event.delete({ where: { id: eventId } });
}
