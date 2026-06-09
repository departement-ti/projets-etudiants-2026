import { prisma } from "../database/db.js";
import { AppError } from "../utils/AppError.js";
import type { AttachmentType, CourseAccessType } from "@prisma/client";
import { addPoints } from "./points.service.js";
import { getEmbedding } from "./embedding.service.js";

function embedLesson(lessonId: string, title: string, transcript: string) {
  getEmbedding(`${title}\n${transcript}`)
    .then((embedding) => prisma.lesson.update({ where: { id: lessonId }, data: { embedding } }))
    .catch((err) => console.error("[embed] Lesson embedding failed:", err));
}

// ─── Helpers ───────────────────────────────────────────────────────────────────

async function requireCreatorOrAdmin(communityId: string, userId: string) {
  const membership = await prisma.membership.findUnique({
    where: { userId_communityId: { userId, communityId } },
  });
  if (!membership || !["creator", "admin"].includes(membership.role)) {
    throw new AppError("Only creators and admins can manage courses", 403);
  }
  return membership;
}

// ─── List Courses ──────────────────────────────────────────────────────────────

export async function listCourses(communityId: string, userId?: string) {
  const community = await prisma.community.findUnique({ where: { id: communityId } });
  if (!community) throw new AppError("Community not found", 404);

  let isManager = false;
  if (userId) {
    const membership = await prisma.membership.findUnique({
      where: { userId_communityId: { userId, communityId } },
      select: { role: true },
    });
    isManager = !!membership && ["creator", "admin"].includes(membership.role);
  }

  return prisma.course.findMany({
    where: { communityId, ...(isManager ? {} : { isPublished: true }) },
    orderBy: { order: "asc" },
    include: {
      _count: { select: { sections: true } },
    },
  });
}

// ─── Get Course ────────────────────────────────────────────────────────────────

export async function getCourse(courseId: string, userId?: string) {
  let isManager = false;
  if (userId) {
    const base = await prisma.course.findUnique({ where: { id: courseId }, select: { communityId: true } });
    if (base) {
      const membership = await prisma.membership.findUnique({
        where: { userId_communityId: { userId, communityId: base.communityId } },
        select: { role: true },
      });
      isManager = !!membership && ["creator", "admin"].includes(membership.role);
    }
  }

  const course = await prisma.course.findUnique({
    where: { id: courseId },
    include: {
      sections: {
        orderBy: { order: "asc" },
        include: {
          lessons: {
            ...(isManager ? {} : { where: { isPublished: true } }),
            orderBy: { order: "asc" },
            select: {
              id: true,
              title: true,
              description: true,
              duration: true,
              order: true,
              videoUrl: true,
              isPublished: true,
            },
          },
        },
      },
    },
  });

  if (!course) throw new AppError("Course not found", 404);
  return course;
}

// ─── Create Course ─────────────────────────────────────────────────────────────

export async function createCourse(
  communityId: string,
  requesterId: string,
  input: {
    title: string;
    description?: string;
    thumbnail?: string;
    accessType?: CourseAccessType;
    unlockAfterDays?: number;
    price?: number;
  }
) {
  if (!input.title?.trim()) throw new AppError("title is required", 400);

  if (input.accessType === "TIME_UNLOCK" && !input.unlockAfterDays) {
    throw new AppError("unlockAfterDays is required for TIME_UNLOCK courses", 400);
  }
  if (input.accessType === "BUY_NOW" && !input.price) {
    throw new AppError("price is required for BUY_NOW courses", 400);
  }

  await requireCreatorOrAdmin(communityId, requesterId);

  const lastCourse = await prisma.course.findFirst({
    where: { communityId },
    orderBy: { order: "desc" },
    select: { order: true },
  });

  return prisma.course.create({
    data: {
      communityId,
      title: input.title.trim(),
      description: input.description?.trim() ?? null,
      thumbnail: input.thumbnail?.trim() ?? null,
      accessType: input.accessType ?? "OPEN",
      unlockAfterDays: input.unlockAfterDays ?? null,
      price: input.price ?? null,
      order: (lastCourse?.order ?? -1) + 1,
    },
  });
}

// ─── Update Course ─────────────────────────────────────────────────────────────

export async function updateCourse(
  courseId: string,
  requesterId: string,
  input: {
    title?: string;
    description?: string;
    thumbnail?: string;
    accessType?: CourseAccessType;
    unlockAfterDays?: number;
    price?: number;
    isPublished?: boolean;
    order?: number;
  }
) {
  const course = await prisma.course.findUnique({ where: { id: courseId } });
  if (!course) throw new AppError("Course not found", 404);

  await requireCreatorOrAdmin(course.communityId, requesterId);

  const newAccessType = input.accessType ?? course.accessType;
  if (newAccessType === "TIME_UNLOCK" && input.unlockAfterDays === undefined && !course.unlockAfterDays) {
    throw new AppError("unlockAfterDays is required for TIME_UNLOCK courses", 400);
  }
  if (newAccessType === "BUY_NOW" && input.price === undefined && !course.price) {
    throw new AppError("price is required for BUY_NOW courses", 400);
  }

  return prisma.course.update({
    where: { id: courseId },
    data: {
      ...(input.title !== undefined && { title: input.title.trim() }),
      ...(input.description !== undefined && { description: input.description.trim() }),
      ...(input.thumbnail !== undefined && { thumbnail: input.thumbnail.trim() }),
      ...(input.accessType !== undefined && { accessType: input.accessType }),
      ...(input.unlockAfterDays !== undefined && { unlockAfterDays: input.unlockAfterDays }),
      ...(input.price !== undefined && { price: input.price }),
      ...(input.isPublished !== undefined && { isPublished: input.isPublished }),
      ...(input.order !== undefined && { order: input.order }),
    },
  });
}

// ─── Delete Course ─────────────────────────────────────────────────────────────

export async function deleteCourse(courseId: string, requesterId: string) {
  const course = await prisma.course.findUnique({ where: { id: courseId } });
  if (!course) throw new AppError("Course not found", 404);

  await requireCreatorOrAdmin(course.communityId, requesterId);
  await prisma.course.delete({ where: { id: courseId } });
}

// ─── Purchase Course (BUY_NOW) ─────────────────────────────────────────────────

export async function purchaseCourse(courseId: string, userId: string) {
  const course = await prisma.course.findUnique({ where: { id: courseId } });
  if (!course) throw new AppError("Course not found", 404);

  if (course.accessType !== "BUY_NOW") {
    throw new AppError("This course does not require a purchase", 400);
  }

  const existing = await prisma.coursePurchase.findUnique({
    where: { userId_courseId: { userId, courseId } },
  });
  if (existing) throw new AppError("You have already purchased this course", 409);

  // price is guaranteed non-null for BUY_NOW (enforced on create/update)
  return prisma.coursePurchase.create({
    data: { userId, courseId, pricePaid: course.price! },
  });
}

// ─── Create Section ────────────────────────────────────────────────────────────

export async function createSection(
  courseId: string,
  requesterId: string,
  input: { title: string }
) {
  if (!input.title?.trim()) throw new AppError("title is required", 400);

  const course = await prisma.course.findUnique({ where: { id: courseId } });
  if (!course) throw new AppError("Course not found", 404);

  await requireCreatorOrAdmin(course.communityId, requesterId);

  const lastSection = await prisma.section.findFirst({
    where: { courseId },
    orderBy: { order: "desc" },
    select: { order: true },
  });

  return prisma.section.create({
    data: {
      courseId,
      title: input.title.trim(),
      order: (lastSection?.order ?? -1) + 1,
    },
  });
}

// ─── Update Section ────────────────────────────────────────────────────────────

export async function updateSection(
  sectionId: string,
  requesterId: string,
  input: { title?: string; order?: number }
) {
  const section = await prisma.section.findUnique({
    where: { id: sectionId },
    include: { course: { select: { communityId: true } } },
  });
  if (!section) throw new AppError("Section not found", 404);

  await requireCreatorOrAdmin(section.course.communityId, requesterId);

  return prisma.section.update({
    where: { id: sectionId },
    data: {
      ...(input.title !== undefined && { title: input.title.trim() }),
      ...(input.order !== undefined && { order: input.order }),
    },
  });
}

// ─── Delete Section ────────────────────────────────────────────────────────────

export async function deleteSection(sectionId: string, requesterId: string) {
  const section = await prisma.section.findUnique({
    where: { id: sectionId },
    include: { course: { select: { communityId: true } } },
  });
  if (!section) throw new AppError("Section not found", 404);

  await requireCreatorOrAdmin(section.course.communityId, requesterId);
  await prisma.section.delete({ where: { id: sectionId } });
}

// ─── Create Lesson ─────────────────────────────────────────────────────────────

export async function createLesson(
  sectionId: string,
  requesterId: string,
  input: {
    title: string;
    description?: string;
    videoUrl?: string;
    content?: string;
    transcript?: string;
    duration?: number;
    isPublished?: boolean;
  }
) {
  if (!input.title?.trim()) throw new AppError("title is required", 400);

  const section = await prisma.section.findUnique({
    where: { id: sectionId },
    include: { course: { select: { communityId: true } } },
  });
  if (!section) throw new AppError("Section not found", 404);

  await requireCreatorOrAdmin(section.course.communityId, requesterId);

  const lastLesson = await prisma.lesson.findFirst({
    where: { sectionId },
    orderBy: { order: "desc" },
    select: { order: true },
  });

  const lesson = await prisma.lesson.create({
    data: {
      sectionId,
      title: input.title.trim(),
      description: input.description?.trim() ?? null,
      videoUrl: input.videoUrl?.trim() ?? null,
      content: input.content?.trim() ?? null,
      transcript: input.transcript?.trim() ?? null,
      duration: input.duration ?? null,
      isPublished: input.isPublished ?? false,
      order: (lastLesson?.order ?? -1) + 1,
    },
    include: { attachments: true },
  });

  if (input.transcript?.trim()) {
    embedLesson(lesson.id, lesson.title, input.transcript.trim());
  }

  return lesson;
}

// ─── Get Lesson ────────────────────────────────────────────────────────────────

export async function getLesson(lessonId: string, userId?: string) {
  const lesson = await prisma.lesson.findUnique({
    where: { id: lessonId },
    include: { attachments: true },
  });
  if (!lesson) throw new AppError("Lesson not found", 404);

  let videoPosition: number | null = null;
  if (userId) {
    const progress = await prisma.lessonProgress.findUnique({
      where: { userId_lessonId: { userId, lessonId } },
      select: { videoPosition: true },
    });
    videoPosition = progress?.videoPosition ?? null;
  }

  return { ...lesson, videoPosition };
}

// ─── Update Lesson ─────────────────────────────────────────────────────────────

export async function updateLesson(
  lessonId: string,
  requesterId: string,
  input: {
    title?: string;
    description?: string;
    videoUrl?: string;
    content?: string;
    transcript?: string;
    duration?: number;
    order?: number;
    isPublished?: boolean;
  }
) {
  const lesson = await prisma.lesson.findUnique({
    where: { id: lessonId },
    include: { section: { include: { course: { select: { communityId: true } } } } },
  });
  if (!lesson) throw new AppError("Lesson not found", 404);

  await requireCreatorOrAdmin(lesson.section.course.communityId, requesterId);

  const updated = await prisma.lesson.update({
    where: { id: lessonId },
    data: {
      ...(input.title !== undefined && { title: input.title.trim() }),
      ...(input.description !== undefined && { description: input.description.trim() }),
      ...(input.videoUrl !== undefined && { videoUrl: input.videoUrl.trim() }),
      ...(input.content !== undefined && { content: input.content.trim() }),
      ...(input.transcript !== undefined && { transcript: input.transcript.trim() }),
      ...(input.duration !== undefined && { duration: input.duration }),
      ...(input.order !== undefined && { order: input.order }),
      ...(input.isPublished !== undefined && { isPublished: input.isPublished }),
    },
    include: { attachments: true },
  });

  const newTranscript = input.transcript?.trim();
  if (newTranscript && newTranscript !== lesson.transcript) {
    embedLesson(lessonId, updated.title, newTranscript);
  }

  return updated;
}

// ─── Delete Lesson ─────────────────────────────────────────────────────────────

export async function deleteLesson(lessonId: string, requesterId: string) {
  const lesson = await prisma.lesson.findUnique({
    where: { id: lessonId },
    include: { section: { include: { course: { select: { communityId: true } } } } },
  });
  if (!lesson) throw new AppError("Lesson not found", 404);

  await requireCreatorOrAdmin(lesson.section.course.communityId, requesterId);
  await prisma.lesson.delete({ where: { id: lessonId } });
}

// ─── Add Attachment ────────────────────────────────────────────────────────────

export async function addAttachment(
  lessonId: string,
  requesterId: string,
  input: { name: string; url: string; type: AttachmentType }
) {
  if (!input.name?.trim()) throw new AppError("name is required", 400);
  if (!input.url?.trim()) throw new AppError("url is required", 400);

  const lesson = await prisma.lesson.findUnique({
    where: { id: lessonId },
    include: { section: { include: { course: { select: { communityId: true } } } } },
  });
  if (!lesson) throw new AppError("Lesson not found", 404);

  await requireCreatorOrAdmin(lesson.section.course.communityId, requesterId);

  return prisma.lessonAttachment.create({
    data: {
      lessonId,
      name: input.name.trim(),
      url: input.url.trim(),
      type: input.type,
    },
  });
}

// ─── Delete Attachment ─────────────────────────────────────────────────────────

export async function deleteAttachment(attachmentId: string, requesterId: string) {
  const attachment = await prisma.lessonAttachment.findUnique({
    where: { id: attachmentId },
    include: {
      lesson: {
        include: { section: { include: { course: { select: { communityId: true } } } } },
      },
    },
  });
  if (!attachment) throw new AppError("Attachment not found", 404);

  await requireCreatorOrAdmin(attachment.lesson.section.course.communityId, requesterId);
  await prisma.lessonAttachment.delete({ where: { id: attachmentId } });
}

// ─── Mark Lesson Complete / Incomplete ────────────────────────────────────────

export async function markLessonComplete(lessonId: string, userId: string) {
  const lesson = await prisma.lesson.findUnique({
    where: { id: lessonId },
    include: { section: { include: { course: { select: { communityId: true } } } } },
  });
  if (!lesson) throw new AppError("Lesson not found", 404);

  const existing = await prisma.lessonProgress.findUnique({
    where: { userId_lessonId: { userId, lessonId } },
  });
  const alreadyCompleted = !!existing?.completedAt;

  const result = await prisma.lessonProgress.upsert({
    where: { userId_lessonId: { userId, lessonId } },
    create: { userId, lessonId, completedAt: new Date() },
    update: { completedAt: new Date() },
  });

  // Award XP only on first completion
  if (!alreadyCompleted) {
    addPoints(userId, lesson.section.course.communityId, "LESSON_COMPLETED").catch(() => {});
  }

  return result;
}

export async function markLessonIncomplete(lessonId: string, userId: string) {
  await prisma.lessonProgress.deleteMany({ where: { userId, lessonId } });
}

// ─── Save Video Position ──────────────────────────────────────────────────────

export async function saveVideoPosition(lessonId: string, userId: string, position: number) {
  const lesson = await prisma.lesson.findUnique({ where: { id: lessonId } });
  if (!lesson) throw new AppError("Lesson not found", 404);

  return prisma.lessonProgress.upsert({
    where: { userId_lessonId: { userId, lessonId } },
    create: { userId, lessonId, videoPosition: position },
    update: { videoPosition: position },
  });
}

// ─── Reorder Sections ─────────────────────────────────────────────────────────

export async function reorderSections(courseId: string, requesterId: string, orderedIds: string[]) {
  const course = await prisma.course.findUnique({ where: { id: courseId } });
  if (!course) throw new AppError("Course not found", 404);

  await requireCreatorOrAdmin(course.communityId, requesterId);

  await prisma.$transaction(
    orderedIds.map((id, index) =>
      prisma.section.update({ where: { id }, data: { order: index } })
    )
  );
}

// ─── Reorder Lessons ──────────────────────────────────────────────────────────

export async function reorderLessons(sectionId: string, requesterId: string, orderedIds: string[]) {
  const section = await prisma.section.findUnique({
    where: { id: sectionId },
    include: { course: { select: { communityId: true } } },
  });
  if (!section) throw new AppError("Section not found", 404);

  await requireCreatorOrAdmin(section.course.communityId, requesterId);

  await prisma.$transaction(
    orderedIds.map((id, index) =>
      prisma.lesson.update({ where: { id }, data: { order: index } })
    )
  );
}

// ─── Get Course Progress ──────────────────────────────────────────────────────

export async function getCourseProgress(courseId: string, userId: string) {
  const course = await prisma.course.findUnique({
    where: { id: courseId },
    include: {
      sections: {
        include: { lessons: { where: { isPublished: true }, select: { id: true } } },
      },
    },
  });
  if (!course) throw new AppError("Course not found", 404);

  const lessonIds = course.sections.flatMap((s) => s.lessons.map((l) => l.id));
  const totalLessons = lessonIds.length;

  const completed = await prisma.lessonProgress.findMany({
    where: { userId, lessonId: { in: lessonIds }, completedAt: { not: null } },
    select: { lessonId: true },
  });

  const completedLessonIds = completed.map((p) => p.lessonId);
  const completedCount = completedLessonIds.length;
  const percentage = totalLessons === 0 ? 0 : Math.round((completedCount / totalLessons) * 100);

  return { totalLessons, completedCount, percentage, completedLessonIds };
}
