import { useNavigate, useParams } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { BookOpen, Lock, Clock, Settings, ShoppingCart, ChevronRight } from 'lucide-react'
import { courseApi } from '@/api/course'
import { communityApi } from '@/api/community'
import { useAuthStore } from '@/store/auth.store'
import type { CourseAccessType, CourseListItem } from '@/types/course'

// ─── Helpers ──────────────────────────────────────────────────────────────────

function AccessBadge({ type, price, unlockAfterDays }: { type: CourseAccessType; price: string | null; unlockAfterDays: number | null }) {
  if (type === 'OPEN') return null

  const map: Record<CourseAccessType, { label: string; className: string }> = {
    OPEN: { label: '', className: '' },
    BUY_NOW: {
      label: price ? `$${price}` : 'Buy now',
      className: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
    },
    TIME_UNLOCK: {
      label: unlockAfterDays ? `Unlocks day ${unlockAfterDays}` : 'Time unlock',
      className: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
    },
    PRIVATE: {
      label: 'Paid members only',
      className: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400',
    },
    LEVEL_UNLOCK: {
      label: 'Level locked',
      className: 'bg-muted text-muted-foreground',
    },
  }

  const { label, className } = map[type]
  return (
    <span className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium ${className}`}>
      {(type === 'BUY_NOW') && <ShoppingCart className="h-3 w-3" />}
      {(type === 'TIME_UNLOCK') && <Clock className="h-3 w-3" />}
      {(type === 'PRIVATE' || type === 'LEVEL_UNLOCK') && <Lock className="h-3 w-3" />}
      {label}
    </span>
  )
}

// ─── CourseCard ───────────────────────────────────────────────────────────────

function CourseCard({ course, communityId }: { course: CourseListItem; communityId: string }) {
  const navigate = useNavigate()

  const { data: progressData } = useQuery({
    queryKey: ['course-progress', course.id],
    queryFn: () => courseApi.getProgress(communityId, course.id),
  })

  const progress = progressData?.data?.progress
  const pct = progress?.percentage ?? 0

  return (
    <div
      onClick={() => navigate(`/communities/${communityId}/classroom/${course.id}`)}
      className="group cursor-pointer overflow-hidden rounded-xl border border-border bg-card transition-colors hover:border-primary/40"
    >
      {/* Thumbnail */}
      <div className="relative h-40 bg-gradient-to-br from-primary/20 to-primary/5">
        {course.thumbnail ? (
          <img src={course.thumbnail} alt={course.title} className="h-full w-full object-cover" />
        ) : (
          <div className="flex h-full items-center justify-center">
            <BookOpen className="h-10 w-10 text-primary/30" />
          </div>
        )}
        <div className="absolute right-2 top-2">
          <AccessBadge type={course.accessType} price={course.price} unlockAfterDays={course.unlockAfterDays} />
        </div>
      </div>

      {/* Body */}
      <div className="p-4">
        <h3 className="font-semibold text-foreground group-hover:text-primary transition-colors line-clamp-2">
          {course.title}
        </h3>
        {course.description && (
          <p className="mt-1 line-clamp-2 text-sm text-muted-foreground">{course.description}</p>
        )}

        <div className="mt-3 flex items-center justify-between text-xs text-muted-foreground">
          <span>{course._count.sections} section{course._count.sections !== 1 ? 's' : ''}</span>
          {pct > 0 && <span className="font-medium text-primary">{pct}%</span>}
        </div>

        {/* Progress bar */}
        <div className="mt-2 h-1.5 w-full overflow-hidden rounded-full bg-muted">
          <div
            className="h-full rounded-full bg-primary transition-all"
            style={{ width: `${pct}%` }}
          />
        </div>
      </div>

      <div className="flex items-center justify-end px-4 pb-3">
        <span className="flex items-center gap-1 text-xs font-medium text-primary opacity-0 transition-opacity group-hover:opacity-100">
          Open <ChevronRight className="h-3.5 w-3.5" />
        </span>
      </div>
    </div>
  )
}

// ─── Classroom ────────────────────────────────────────────────────────────────

export function Classroom() {
  const { id: communityId } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { user } = useAuthStore()
  const isMock = communityId?.startsWith('mock-')

  const { data: communityData } = useQuery({
    queryKey: ['community', communityId],
    queryFn: () => communityApi.getById(communityId!),
    enabled: !!communityId && !isMock,
  })

  const { data, isLoading } = useQuery({
    queryKey: ['courses', communityId],
    queryFn: () => courseApi.list(communityId!),
    enabled: !!communityId && !isMock,
  })

  const community = communityData?.data?.community
  const isCreator = community?.creator.id === user?.id
  const courses = data?.data?.courses ?? []

  if (isMock) {
    return (
      <div className="rounded-xl border border-border bg-card p-8 text-center">
        <BookOpen className="mx-auto h-9 w-9 text-muted-foreground" />
        <p className="mt-3 font-semibold text-foreground">Demo community</p>
        <p className="mt-1 text-sm text-muted-foreground">Create a real community to build courses.</p>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-foreground">Classroom</h2>
        {isCreator && (
          <button
            onClick={() => navigate(`/communities/${communityId}/classroom/manage`)}
            className="flex items-center gap-1.5 rounded-lg border border-border px-3 py-1.5 text-sm text-muted-foreground transition-colors hover:border-primary/50 hover:text-foreground"
          >
            <Settings className="h-3.5 w-3.5" />
            Manage courses
          </button>
        )}
      </div>

      {isLoading ? (
        <div className="flex h-48 items-center justify-center">
          <div className="h-6 w-6 animate-spin rounded-full border-4 border-border border-t-primary" />
        </div>
      ) : courses.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-xl border border-border bg-card py-16 text-center">
          <BookOpen className="h-9 w-9 text-muted-foreground" />
          <p className="mt-3 font-semibold text-foreground">No courses yet</p>
          <p className="mt-1 text-sm text-muted-foreground">
            {isCreator
              ? 'Click "Manage courses" to create your first course.'
              : "The creator hasn't published any courses yet."}
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          {courses.map((course) => (
            <CourseCard key={course.id} course={course} communityId={communityId!} />
          ))}
        </div>
      )}
    </div>
  )
}
