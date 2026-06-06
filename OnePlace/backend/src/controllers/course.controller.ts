import type { Request, Response, NextFunction } from "express";
import * as courseService from "../services/course.service.js";
import type { AttachmentType, CourseAccessType } from "@prisma/client";

// ─── Courses ───────────────────────────────────────────────────────────────────

// GET /api/v1/communities/:communityId/courses
export async function listCourses(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const courses = await courseService.listCourses(req.params.communityId as string, req.user?.id);
    res.status(200).json({ success: true, data: { courses } });
  } catch (err) {
    next(err);
  }
}

// GET /api/v1/communities/:communityId/courses/:courseId
export async function getCourse(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const course = await courseService.getCourse(req.params.courseId as string, req.user?.id);
    res.status(200).json({ success: true, data: { course } });
  } catch (err) {
    next(err);
  }
}

// POST /api/v1/communities/:communityId/courses
export async function createCourse(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const course = await courseService.createCourse(
      req.params.communityId as string,
      req.user!.id,
      req.body as {
        title: string;
        description?: string;
        thumbnail?: string;
        accessType?: CourseAccessType;
        unlockAfterDays?: number;
        price?: number;
      }
    );
    res.status(201).json({ success: true, data: { course } });
  } catch (err) {
    next(err);
  }
}

// PUT /api/v1/communities/:communityId/courses/:courseId
export async function updateCourse(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const course = await courseService.updateCourse(
      req.params.courseId as string,
      req.user!.id,
      req.body
    );
    res.status(200).json({ success: true, data: { course } });
  } catch (err) {
    next(err);
  }
}

// DELETE /api/v1/communities/:communityId/courses/:courseId
export async function deleteCourse(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    await courseService.deleteCourse(req.params.courseId as string, req.user!.id);
    res.status(200).json({ success: true, message: "Course deleted." });
  } catch (err) {
    next(err);
  }
}

// POST /api/v1/communities/:communityId/courses/:courseId/purchase
export async function purchaseCourse(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const purchase = await courseService.purchaseCourse(
      req.params.courseId as string,
      req.user!.id
    );
    res.status(201).json({ success: true, data: { purchase } });
  } catch (err) {
    next(err);
  }
}

// GET /api/v1/communities/:communityId/courses/:courseId/progress
export async function getCourseProgress(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const progress = await courseService.getCourseProgress(req.params.courseId as string, req.user!.id);
    res.status(200).json({ success: true, data: { progress } });
  } catch (err) {
    next(err);
  }
}

// ─── Sections ──────────────────────────────────────────────────────────────────

// POST /api/v1/communities/:communityId/courses/:courseId/sections
export async function createSection(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const section = await courseService.createSection(
      req.params.courseId as string,
      req.user!.id,
      req.body as { title: string }
    );
    res.status(201).json({ success: true, data: { section } });
  } catch (err) {
    next(err);
  }
}

// PUT /api/v1/communities/:communityId/courses/:courseId/sections/:sectionId
export async function updateSection(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const section = await courseService.updateSection(
      req.params.sectionId as string,
      req.user!.id,
      req.body as { title?: string; order?: number }
    );
    res.status(200).json({ success: true, data: { section } });
  } catch (err) {
    next(err);
  }
}

// DELETE /api/v1/communities/:communityId/courses/:courseId/sections/:sectionId
export async function deleteSection(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    await courseService.deleteSection(req.params.sectionId as string, req.user!.id);
    res.status(200).json({ success: true, message: "Section deleted." });
  } catch (err) {
    next(err);
  }
}

// ─── Lessons ───────────────────────────────────────────────────────────────────

// POST /api/v1/communities/:communityId/courses/:courseId/sections/:sectionId/lessons
export async function createLesson(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const lesson = await courseService.createLesson(
      req.params.sectionId as string,
      req.user!.id,
      req.body as {
        title: string;
        description?: string;
        videoUrl?: string;
        content?: string;
        transcript?: string;
        duration?: number;
        isPublished?: boolean;
      }
    );
    res.status(201).json({ success: true, data: { lesson } });
  } catch (err) {
    next(err);
  }
}

// GET /api/v1/communities/:communityId/courses/:courseId/sections/:sectionId/lessons/:lessonId
export async function getLesson(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const lesson = await courseService.getLesson(req.params.lessonId as string, req.user?.id);
    res.status(200).json({ success: true, data: { lesson } });
  } catch (err) {
    next(err);
  }
}

// PUT /api/v1/communities/:communityId/courses/:courseId/sections/:sectionId/lessons/:lessonId
export async function updateLesson(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const lesson = await courseService.updateLesson(
      req.params.lessonId as string,
      req.user!.id,
      req.body
    );
    res.status(200).json({ success: true, data: { lesson } });
  } catch (err) {
    next(err);
  }
}

// DELETE /api/v1/communities/:communityId/courses/:courseId/sections/:sectionId/lessons/:lessonId
export async function deleteLesson(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    await courseService.deleteLesson(req.params.lessonId as string, req.user!.id);
    res.status(200).json({ success: true, message: "Lesson deleted." });
  } catch (err) {
    next(err);
  }
}

// ─── Attachments ───────────────────────────────────────────────────────────────

// POST /api/v1/communities/:communityId/courses/:courseId/sections/:sectionId/lessons/:lessonId/attachments
export async function addAttachment(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const attachment = await courseService.addAttachment(
      req.params.lessonId as string,
      req.user!.id,
      req.body as { name: string; url: string; type: AttachmentType }
    );
    res.status(201).json({ success: true, data: { attachment } });
  } catch (err) {
    next(err);
  }
}

// DELETE /api/v1/communities/:communityId/courses/:courseId/sections/:sectionId/lessons/:lessonId/attachments/:attachmentId
export async function deleteAttachment(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    await courseService.deleteAttachment(req.params.attachmentId as string, req.user!.id);
    res.status(200).json({ success: true, message: "Attachment deleted." });
  } catch (err) {
    next(err);
  }
}

// ─── Progress ──────────────────────────────────────────────────────────────────

// POST /api/v1/communities/:communityId/courses/:courseId/sections/:sectionId/lessons/:lessonId/complete
export async function markLessonComplete(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const progress = await courseService.markLessonComplete(req.params.lessonId as string, req.user!.id);
    res.status(200).json({ success: true, data: { progress } });
  } catch (err) {
    next(err);
  }
}

// DELETE /api/v1/communities/:communityId/courses/:courseId/sections/:sectionId/lessons/:lessonId/complete
export async function markLessonIncomplete(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    await courseService.markLessonIncomplete(req.params.lessonId as string, req.user!.id);
    res.status(200).json({ success: true, message: "Lesson marked incomplete." });
  } catch (err) {
    next(err);
  }
}

// PUT /api/v1/communities/:communityId/courses/:courseId/sections/reorder
export async function reorderSections(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const { orderedIds } = req.body as { orderedIds: string[] };
    if (!Array.isArray(orderedIds)) {
      res.status(400).json({ success: false, message: "orderedIds must be an array" });
      return;
    }
    await courseService.reorderSections(req.params.courseId as string, req.user!.id, orderedIds);
    res.status(200).json({ success: true });
  } catch (err) {
    next(err);
  }
}

// PUT /api/v1/communities/:communityId/courses/:courseId/sections/:sectionId/lessons/reorder
export async function reorderLessons(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const { orderedIds } = req.body as { orderedIds: string[] };
    if (!Array.isArray(orderedIds)) {
      res.status(400).json({ success: false, message: "orderedIds must be an array" });
      return;
    }
    await courseService.reorderLessons(req.params.sectionId as string, req.user!.id, orderedIds);
    res.status(200).json({ success: true });
  } catch (err) {
    next(err);
  }
}

// PATCH /api/v1/communities/:communityId/courses/:courseId/sections/:sectionId/lessons/:lessonId/progress
export async function saveVideoPosition(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const { position } = req.body as { position: number };
    if (typeof position !== "number") {
      res.status(400).json({ success: false, message: "position must be a number" });
      return;
    }
    const progress = await courseService.saveVideoPosition(req.params.lessonId as string, req.user!.id, position);
    res.status(200).json({ success: true, data: { progress } });
  } catch (err) {
    next(err);
  }
}
