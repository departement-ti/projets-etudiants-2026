export type CourseAccessType = 'OPEN' | 'BUY_NOW' | 'TIME_UNLOCK' | 'PRIVATE' | 'LEVEL_UNLOCK'
export type AttachmentType = 'FILE' | 'LINK'

export interface CourseListItem {
  id: string
  communityId: string
  title: string
  description: string | null
  thumbnail: string | null
  accessType: CourseAccessType
  price: string | null
  unlockAfterDays: number | null
  order: number
  isPublished: boolean
  createdAt: string
  _count: { sections: number }
}

export interface LessonSummary {
  id: string
  title: string
  description: string | null
  duration: number | null
  order: number
  videoUrl: string | null
  isPublished: boolean
}

export interface CourseSection {
  id: string
  courseId: string
  title: string
  order: number
  lessons: LessonSummary[]
}

export interface Course {
  id: string
  communityId: string
  title: string
  description: string | null
  thumbnail: string | null
  accessType: CourseAccessType
  price: string | null
  unlockAfterDays: number | null
  order: number
  isPublished: boolean
  createdAt: string
  sections: CourseSection[]
}

export interface LessonAttachment {
  id: string
  lessonId: string
  name: string
  url: string
  type: AttachmentType
}

export interface Lesson {
  id: string
  sectionId: string
  title: string
  description: string | null
  videoUrl: string | null
  content: string | null
  transcript: string | null
  duration: number | null
  isPublished: boolean
  order: number
  attachments: LessonAttachment[]
  videoPosition: number | null
}

export interface CourseProgress {
  totalLessons: number
  completedCount: number
  percentage: number
  completedLessonIds: string[]
}
