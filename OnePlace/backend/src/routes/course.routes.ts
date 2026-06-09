import { Router } from "express";
import { protect } from "../middlewares/auth.middleware.js";
import { checkCommunityAccess, checkCourseAccess } from "../middlewares/access.middleware.js";
import {
  listCourses,
  getCourse,
  createCourse,
  updateCourse,
  deleteCourse,
  purchaseCourse,
  getCourseProgress,
  createSection,
  updateSection,
  deleteSection,
  reorderSections,
  createLesson,
  getLesson,
  updateLesson,
  deleteLesson,
  reorderLessons,
  addAttachment,
  deleteAttachment,
  markLessonComplete,
  markLessonIncomplete,
  saveVideoPosition,
} from "../controllers/course.controller.js";

// mergeParams lets handlers access :communityId from the parent community router
const courseRouter = Router({ mergeParams: true });

// ─── Courses ───────────────────────────────────────────────────────────────────
courseRouter.get("/", protect, checkCommunityAccess, listCourses);
courseRouter.post("/", protect, checkCommunityAccess, createCourse);
courseRouter.get("/:courseId", protect, checkCommunityAccess, checkCourseAccess, getCourse);
courseRouter.put("/:courseId", protect, checkCommunityAccess, updateCourse);
courseRouter.delete("/:courseId", protect, checkCommunityAccess, deleteCourse);
courseRouter.post("/:courseId/purchase", protect, checkCommunityAccess, purchaseCourse);
courseRouter.get("/:courseId/progress", protect, checkCommunityAccess, getCourseProgress);

// ─── Sections ──────────────────────────────────────────────────────────────────
courseRouter.post("/:courseId/sections", protect, checkCommunityAccess, createSection);
courseRouter.put("/:courseId/sections/reorder", protect, checkCommunityAccess, reorderSections);
courseRouter.put("/:courseId/sections/:sectionId", protect, checkCommunityAccess, updateSection);
courseRouter.delete("/:courseId/sections/:sectionId", protect, checkCommunityAccess, deleteSection);

// ─── Lessons ───────────────────────────────────────────────────────────────────
courseRouter.post(
  "/:courseId/sections/:sectionId/lessons",
  protect, checkCommunityAccess, createLesson
);
courseRouter.put(
  "/:courseId/sections/:sectionId/lessons/reorder",
  protect, checkCommunityAccess, reorderLessons
);
courseRouter.get(
  "/:courseId/sections/:sectionId/lessons/:lessonId",
  protect, checkCommunityAccess, checkCourseAccess, getLesson
);
courseRouter.put(
  "/:courseId/sections/:sectionId/lessons/:lessonId",
  protect, checkCommunityAccess, updateLesson
);
courseRouter.delete(
  "/:courseId/sections/:sectionId/lessons/:lessonId",
  protect, checkCommunityAccess, deleteLesson
);

// ─── Attachments ───────────────────────────────────────────────────────────────
courseRouter.post(
  "/:courseId/sections/:sectionId/lessons/:lessonId/attachments",
  protect, checkCommunityAccess, addAttachment
);
courseRouter.delete(
  "/:courseId/sections/:sectionId/lessons/:lessonId/attachments/:attachmentId",
  protect, checkCommunityAccess, deleteAttachment
);

// ─── Progress ──────────────────────────────────────────────────────────────────
courseRouter.post(
  "/:courseId/sections/:sectionId/lessons/:lessonId/complete",
  protect, checkCommunityAccess, checkCourseAccess, markLessonComplete
);
courseRouter.delete(
  "/:courseId/sections/:sectionId/lessons/:lessonId/complete",
  protect, checkCommunityAccess, checkCourseAccess, markLessonIncomplete
);
courseRouter.patch(
  "/:courseId/sections/:sectionId/lessons/:lessonId/progress",
  protect, checkCommunityAccess, checkCourseAccess, saveVideoPosition
);

export default courseRouter;
