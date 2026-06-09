import { api } from './client'
import type { ApiResponse } from '@/types/auth'
import type { Course, CourseAccessType, CourseListItem, CourseProgress, Lesson } from '@/types/course'

const base = (communityId: string) => `/communities/${communityId}/courses`
const lessonBase = (communityId: string, courseId: string, sectionId: string) =>
  `${base(communityId)}/${courseId}/sections/${sectionId}/lessons`

export const courseApi = {
  // ── Courses ──────────────────────────────────────────────────────────────────

  list: (communityId: string) =>
    api.get<ApiResponse<{ courses: CourseListItem[] }>>(base(communityId)).then((r) => r.data),

  getById: (communityId: string, courseId: string) =>
    api
      .get<ApiResponse<{ course: Course }>>(`${base(communityId)}/${courseId}`)
      .then((r) => r.data),

  getProgress: (communityId: string, courseId: string) =>
    api
      .get<ApiResponse<{ progress: CourseProgress }>>(`${base(communityId)}/${courseId}/progress`)
      .then((r) => r.data),

  purchase: (communityId: string, courseId: string) =>
    api.post(`${base(communityId)}/${courseId}/purchase`).then((r) => r.data),

  create: (
    communityId: string,
    data: {
      title: string
      description?: string
      thumbnail?: string
      accessType?: CourseAccessType
      price?: number
      unlockAfterDays?: number
      isPublished?: boolean
    },
  ) =>
    api
      .post<ApiResponse<{ course: CourseListItem }>>(`${base(communityId)}`, data)
      .then((r) => r.data),

  update: (
    communityId: string,
    courseId: string,
    data: {
      title?: string
      description?: string
      thumbnail?: string
      accessType?: CourseAccessType
      price?: number
      unlockAfterDays?: number
      isPublished?: boolean
    },
  ) =>
    api
      .put<ApiResponse<{ course: CourseListItem }>>(`${base(communityId)}/${courseId}`, data)
      .then((r) => r.data),

  delete: (communityId: string, courseId: string) =>
    api.delete(`${base(communityId)}/${courseId}`).then((r) => r.data),

  // ── Sections ─────────────────────────────────────────────────────────────────

  createSection: (communityId: string, courseId: string, data: { title: string }) =>
    api
      .post<ApiResponse<{ section: { id: string; title: string; order: number } }>>(
        `${base(communityId)}/${courseId}/sections`,
        data,
      )
      .then((r) => r.data),

  updateSection: (
    communityId: string,
    courseId: string,
    sectionId: string,
    data: { title?: string; order?: number },
  ) =>
    api
      .put(`${base(communityId)}/${courseId}/sections/${sectionId}`, data)
      .then((r) => r.data),

  deleteSection: (communityId: string, courseId: string, sectionId: string) =>
    api.delete(`${base(communityId)}/${courseId}/sections/${sectionId}`).then((r) => r.data),

  reorderSections: (communityId: string, courseId: string, orderedIds: string[]) =>
    api
      .put(`${base(communityId)}/${courseId}/sections/reorder`, { orderedIds })
      .then((r) => r.data),

  reorderLessons: (communityId: string, courseId: string, sectionId: string, orderedIds: string[]) =>
    api
      .put(`${base(communityId)}/${courseId}/sections/${sectionId}/lessons/reorder`, { orderedIds })
      .then((r) => r.data),

  // ── Lessons ──────────────────────────────────────────────────────────────────

  getLesson: (communityId: string, courseId: string, sectionId: string, lessonId: string) =>
    api
      .get<ApiResponse<{ lesson: Lesson }>>(
        `${lessonBase(communityId, courseId, sectionId)}/${lessonId}`,
      )
      .then((r) => r.data),

  createLesson: (
    communityId: string,
    courseId: string,
    sectionId: string,
    data: {
      title: string
      videoUrl?: string
      content?: string
      transcript?: string
      duration?: number
      isPublished?: boolean
    },
  ) =>
    api
      .post<ApiResponse<{ lesson: Lesson }>>(lessonBase(communityId, courseId, sectionId), data)
      .then((r) => r.data),

  updateLesson: (
    communityId: string,
    courseId: string,
    sectionId: string,
    lessonId: string,
    data: {
      title?: string
      videoUrl?: string
      content?: string
      transcript?: string
      duration?: number
      isPublished?: boolean
    },
  ) =>
    api
      .put<ApiResponse<{ lesson: Lesson }>>(
        `${lessonBase(communityId, courseId, sectionId)}/${lessonId}`,
        data,
      )
      .then((r) => r.data),

  deleteLesson: (communityId: string, courseId: string, sectionId: string, lessonId: string) =>
    api
      .delete(`${lessonBase(communityId, courseId, sectionId)}/${lessonId}`)
      .then((r) => r.data),

  // ── Attachments ───────────────────────────────────────────────────────────────

  addAttachment: (
    communityId: string,
    courseId: string,
    sectionId: string,
    lessonId: string,
    data: { name: string; url: string; type: 'FILE' | 'LINK' },
  ) =>
    api
      .post(
        `${lessonBase(communityId, courseId, sectionId)}/${lessonId}/attachments`,
        data,
      )
      .then((r) => r.data),

  deleteAttachment: (
    communityId: string,
    courseId: string,
    sectionId: string,
    lessonId: string,
    attachmentId: string,
  ) =>
    api
      .delete(
        `${lessonBase(communityId, courseId, sectionId)}/${lessonId}/attachments/${attachmentId}`,
      )
      .then((r) => r.data),

  // ── Progress ──────────────────────────────────────────────────────────────────

  markComplete: (communityId: string, courseId: string, sectionId: string, lessonId: string) =>
    api
      .post(`${lessonBase(communityId, courseId, sectionId)}/${lessonId}/complete`)
      .then((r) => r.data),

  markIncomplete: (communityId: string, courseId: string, sectionId: string, lessonId: string) =>
    api
      .delete(`${lessonBase(communityId, courseId, sectionId)}/${lessonId}/complete`)
      .then((r) => r.data),

  saveVideoPosition: (communityId: string, courseId: string, sectionId: string, lessonId: string, position: number) =>
    api
      .patch(`${lessonBase(communityId, courseId, sectionId)}/${lessonId}/progress`, { position })
      .then((r) => r.data),
}
