import { useState } from 'react'
import { useNavigate, useParams, Navigate } from 'react-router-dom'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { BookOpen, Edit2, Plus, Trash2 } from 'lucide-react'
import { toast } from 'sonner'
import { courseApi } from '@/api/course'
import { communityApi } from '@/api/community'
import { useAuthStore } from '@/store/auth.store'
import type { CourseListItem, CourseAccessType } from '@/types/course'
import { Button } from '@/components/ui/button'
import { CourseFormModal } from '../components/CourseFormModal'
import { ConfirmModal } from '@/components/ui/confirm-modal'

// ── Access badge ──────────────────────────────────────────────────────────────

const ACCESS_LABELS: Record<CourseAccessType, string> = {
  OPEN: 'Open',
  BUY_NOW: 'Buy now',
  TIME_UNLOCK: 'Time unlock',
  PRIVATE: 'Paid only',
  LEVEL_UNLOCK: 'Level unlock',
}

function AccessBadge({ type }: { type: CourseAccessType }) {
  const colorMap: Record<CourseAccessType, string> = {
    OPEN: 'bg-emerald-100 text-emerald-700',
    BUY_NOW: 'bg-amber-100 text-amber-700',
    TIME_UNLOCK: 'bg-blue-100 text-blue-700',
    PRIVATE: 'bg-purple-100 text-purple-700',
    LEVEL_UNLOCK: 'bg-muted text-muted-foreground',
  }
  return (
    <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${colorMap[type]}`}>
      {ACCESS_LABELS[type]}
    </span>
  )
}

// ── CourseRow ─────────────────────────────────────────────────────────────────

function CourseRow({
  course,
  communityId,
  onEdit,
  onDelete,
}: {
  course: CourseListItem
  communityId: string
  onEdit: (c: CourseListItem) => void
  onDelete: (c: CourseListItem) => void
}) {
  const navigate = useNavigate()

  return (
    <div
      onClick={() => navigate(`/communities/${communityId}/classroom/manage/${course.id}`)}
      className="flex cursor-pointer items-center gap-4 rounded-xl border border-border bg-card px-4 py-3 transition-colors hover:border-primary/40"
    >
      {/* Thumbnail */}
      <div className="h-14 w-20 shrink-0 overflow-hidden rounded-lg bg-muted">
        {course.thumbnail ? (
          <img src={course.thumbnail} alt={course.title} className="h-full w-full object-cover" />
        ) : (
          <div className="flex h-full items-center justify-center">
            <BookOpen className="h-5 w-5 text-muted-foreground/50" />
          </div>
        )}
      </div>

      {/* Info */}
      <div className="min-w-0 flex-1">
        <p className="truncate font-medium text-foreground">{course.title}</p>
        <div className="mt-1 flex items-center gap-2">
          <AccessBadge type={course.accessType} />
          <span
            className={`text-xs font-medium ${
              course.isPublished ? 'text-emerald-600' : 'text-muted-foreground'
            }`}
          >
            {course.isPublished ? 'Published' : 'Draft'}
          </span>
          <span className="text-xs text-muted-foreground">
            {course._count.sections} section{course._count.sections !== 1 ? 's' : ''}
          </span>
        </div>
      </div>

      {/* Actions */}
      <div className="flex shrink-0 gap-1" onClick={(e) => e.stopPropagation()}>
        <button
          onClick={() => onEdit(course)}
          className="rounded-lg p-2 text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
        >
          <Edit2 className="h-4 w-4" />
        </button>
        <button
          onClick={() => onDelete(course)}
          className="rounded-lg p-2 text-muted-foreground transition-colors hover:bg-destructive/10 hover:text-destructive"
        >
          <Trash2 className="h-4 w-4" />
        </button>
      </div>
    </div>
  )
}

// ── CourseBuilder ─────────────────────────────────────────────────────────────

export function CourseBuilder() {
  const { id: communityId } = useParams<{ id: string }>()
  const { user } = useAuthStore()
  const queryClient = useQueryClient()

  const [formOpen, setFormOpen] = useState(false)
  const [editingCourse, setEditingCourse] = useState<CourseListItem | undefined>()
  const [deletingCourse, setDeletingCourse] = useState<CourseListItem | undefined>()

  const { data: communityData } = useQuery({
    queryKey: ['community', communityId],
    queryFn: () => communityApi.getById(communityId!),
    enabled: !!communityId,
  })
  const community = communityData?.data?.community

  const { data: membershipData } = useQuery({
    queryKey: ['membership', communityId],
    queryFn: () => communityApi.getMyMembership(communityId!),
    enabled: !!communityId,
  })
  const membership = membershipData?.data?.membership

  const { data, isLoading } = useQuery({
    queryKey: ['courses', communityId],
    queryFn: () => courseApi.list(communityId!),
    enabled: !!communityId,
  })
  const courses = data?.data?.courses ?? []

  const { mutate: deleteCourse, isPending: deleting } = useMutation({
    mutationFn: (courseId: string) => courseApi.delete(communityId!, courseId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['courses', communityId] })
      toast.success('Course deleted')
      setDeletingCourse(undefined)
    },
    onError: (err) => toast.error((err as Error).message),
  })

  if (!communityId) return null

  // Creator/admin guard
  const isManager =
    community?.creator.id === user?.id || membership?.role === 'admin'

  if (community && !isManager) {
    return <Navigate to={`/communities/${communityId}/classroom`} replace />
  }

  if (isLoading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="h-6 w-6 animate-spin rounded-full border-4 border-border border-t-primary" />
      </div>
    )
  }

  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-lg font-semibold text-foreground">Manage courses</h2>
          <p className="text-sm text-muted-foreground">
            {courses.length} course{courses.length !== 1 ? 's' : ''} total
          </p>
        </div>
        <Button
          size="sm"
          onClick={() => { setEditingCourse(undefined); setFormOpen(true) }}
        >
          <Plus className="mr-1.5 h-4 w-4" />
          New course
        </Button>
      </div>

      {/* Course list */}
      {courses.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-xl border border-dashed border-border py-16 text-center">
          <BookOpen className="h-9 w-9 text-muted-foreground" />
          <p className="mt-3 font-semibold text-foreground">No courses yet</p>
          <p className="mt-1 text-sm text-muted-foreground">Create your first course to get started.</p>
          <Button
            size="sm"
            className="mt-4"
            onClick={() => { setEditingCourse(undefined); setFormOpen(true) }}
          >
            <Plus className="mr-1.5 h-4 w-4" />
            New course
          </Button>
        </div>
      ) : (
        <div className="space-y-2">
          {courses.map((course) => (
            <CourseRow
              key={course.id}
              course={course}
              communityId={communityId}
              onEdit={(c) => { setEditingCourse(c); setFormOpen(true) }}
              onDelete={(c) => setDeletingCourse(c)}
            />
          ))}
        </div>
      )}

      <ConfirmModal
        open={!!deletingCourse}
        onOpenChange={(v) => { if (!v) setDeletingCourse(undefined) }}
        title="Delete course?"
        description={`"${deletingCourse?.title}" and all its sections and lessons will be permanently deleted.`}
        confirmLabel="Delete"
        onConfirm={() => deletingCourse && deleteCourse(deletingCourse.id)}
        isPending={deleting}
      />

      <CourseFormModal
        open={formOpen}
        onOpenChange={setFormOpen}
        communityId={communityId}
        course={editingCourse}
      />
    </div>
  )
}
