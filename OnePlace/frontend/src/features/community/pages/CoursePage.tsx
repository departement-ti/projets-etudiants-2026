import { useState, useRef, useEffect, useCallback } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import {
  ArrowLeft,
  CheckCircle,
  Circle,
  ChevronDown,
  ChevronRight,
  BookOpen,
  Lock,
  Paperclip,
  ExternalLink,
  CheckSquare,
  Square,
  FileText,
  Brain,
  X,
  Sparkles,
} from 'lucide-react'
import { aiApi, type QuizQuestion, type QuizResult, type ProgressCoachData } from '@/api/ai'
import { MediaPlayer, MediaProvider } from '@vidstack/react'
import { DefaultVideoLayout, defaultLayoutIcons } from '@vidstack/react/player/layouts/default'
import type { MediaPlayerInstance, MediaTimeUpdateEventDetail } from '@vidstack/react'
import '@vidstack/react/player/styles/default/theme.css'
import '@vidstack/react/player/styles/default/layouts/video.css'
import { courseApi } from '@/api/course'
import { xpToast } from '@/lib/xpToast'
import type { Course, CourseSection, Lesson, LessonSummary } from '@/types/course'
import { Button } from '@/components/ui/button'
import { PurchaseCourseModal } from '../components/PurchaseCourseModal'
import { RichTextRenderer } from '@/components/shared/RichTextRenderer'

// ─── Video Player ─────────────────────────────────────────────────────────────

function VideoPlayer({
  url,
  savedPosition,
  onSavePosition,
}: {
  url: string
  savedPosition?: number | null
  onSavePosition?: (pos: number) => void
}) {
  const playerRef = useRef<MediaPlayerInstance>(null)
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  const flush = useCallback(() => {
    if (!onSavePosition || !playerRef.current) return
    if (timerRef.current) clearTimeout(timerRef.current)
    onSavePosition(Math.floor(playerRef.current.currentTime))
  }, [onSavePosition])

  useEffect(() => {
    window.addEventListener('beforeunload', flush)
    return () => window.removeEventListener('beforeunload', flush)
  }, [flush])

  // Loom has no Vidstack provider — keep as iframe
  const loomMatch = url.match(/loom\.com\/share\/([a-zA-Z0-9]+)/)
  if (loomMatch) {
    return (
      <div className="relative aspect-video w-full overflow-hidden rounded-xl bg-black">
        <iframe
          src={`https://www.loom.com/embed/${loomMatch[1]}`}
          className="absolute inset-0 h-full w-full"
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
          allowFullScreen
        />
      </div>
    )
  }

  // Vidstack handles YouTube, Vimeo, MP4, HLS (.m3u8) automatically
  return (
    <MediaPlayer
      ref={playerRef}
      src={url}
      className="w-full overflow-hidden rounded-xl"
      onCanPlay={() => {
        if (savedPosition && savedPosition > 0 && playerRef.current) {
          playerRef.current.currentTime = savedPosition
        }
      }}
      onTimeUpdate={({ currentTime }: MediaTimeUpdateEventDetail) => {
        if (!onSavePosition) return
        if (timerRef.current) clearTimeout(timerRef.current)
        timerRef.current = setTimeout(() => onSavePosition(Math.floor(currentTime)), 5000)
      }}
      onPause={flush}
      onEnded={flush}
    >
      <MediaProvider />
      <DefaultVideoLayout icons={defaultLayoutIcons} />
    </MediaPlayer>
  )
}

// ─── Sidebar Lesson Row ───────────────────────────────────────────────────────

function LessonRow({
  lesson,
  sectionId,
  communityId,
  courseId,
  isActive,
  isCompleted,
}: {
  lesson: LessonSummary
  sectionId: string
  communityId: string
  courseId: string
  isActive: boolean
  isCompleted: boolean
}) {
  const navigate = useNavigate()

  return (
    <button
      onClick={() =>
        navigate(
          `/communities/${communityId}/classroom/${courseId}/sections/${sectionId}/lessons/${lesson.id}`,
        )
      }
      className={`flex w-full items-center gap-2.5 rounded-lg px-3 py-2 text-left text-sm transition-colors ${
        isActive
          ? 'bg-primary/10 text-primary'
          : 'text-muted-foreground hover:bg-muted hover:text-foreground'
      }`}
    >
      {isCompleted ? (
        <CheckCircle className="h-4 w-4 shrink-0 text-emerald-500" />
      ) : (
        <Circle className={`h-4 w-4 shrink-0 ${isActive ? 'text-primary' : 'text-muted-foreground/40'}`} />
      )}
      <span className="min-w-0 flex-1 truncate">{lesson.title}</span>
      {lesson.duration && (
        <span className="shrink-0 text-xs text-muted-foreground/60">
          {Math.round(lesson.duration / 60)}m
        </span>
      )}
    </button>
  )
}

// ─── Sidebar Section ──────────────────────────────────────────────────────────

function SidebarSection({
  section,
  communityId,
  courseId,
  activeLessonId,
  completedIds,
}: {
  section: CourseSection
  communityId: string
  courseId: string
  activeLessonId: string | undefined
  completedIds: Set<string>
}) {
  const [open, setOpen] = useState(true)

  return (
    <div>
      <button
        onClick={() => setOpen((o) => !o)}
        className="flex w-full items-center gap-2 px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground hover:text-foreground"
      >
        {open ? <ChevronDown className="h-3.5 w-3.5" /> : <ChevronRight className="h-3.5 w-3.5" />}
        {section.title}
      </button>
      {open && (
        <div className="space-y-0.5">
          {section.lessons.map((lesson) => (
            <LessonRow
              key={lesson.id}
              lesson={lesson}
              sectionId={section.id}
              communityId={communityId}
              courseId={courseId}
              isActive={lesson.id === activeLessonId}
              isCompleted={completedIds.has(lesson.id)}
            />
          ))}
        </div>
      )}
    </div>
  )
}

// ─── Progress Coach Banner ────────────────────────────────────────────────────

function ProgressCoachBanner({ communityId }: { communityId: string }) {
  const [dismissed, setDismissed] = useState(false)
  const { data, isLoading } = useQuery({
    queryKey: ['progress-coach', communityId],
    queryFn: () => aiApi.getProgressCoach(communityId),
    staleTime: 5 * 60 * 1000,
  })

  const coach = data?.data as ProgressCoachData | undefined
  if (isLoading || !coach || dismissed) return null
  if (coach.daysSinceActive !== null && coach.daysSinceActive < 2) return null

  return (
    <div className="flex items-start gap-3 rounded-xl border border-primary/20 bg-primary/5 p-4">
      <Sparkles className="mt-0.5 h-4 w-4 shrink-0 text-primary" />
      <div className="min-w-0 flex-1">
        <p className="text-sm font-medium text-foreground">Progress Coach</p>
        <p className="mt-0.5 text-sm text-muted-foreground">{coach.message}</p>
        {coach.lastCourse && (
          <p className="mt-1 text-xs text-muted-foreground">
            Last active in: <span className="font-medium text-foreground">{coach.lastCourse}</span>
            {coach.lastLesson && ` — ${coach.lastLesson}`}
          </p>
        )}
      </div>
      <button onClick={() => setDismissed(true)} className="shrink-0 text-muted-foreground hover:text-foreground">
        <X className="h-4 w-4" />
      </button>
    </div>
  )
}

// ─── Quiz Modal ───────────────────────────────────────────────────────────────

function QuizModal({ lessonId, onClose }: { lessonId: string; onClose: () => void }) {
  const [selected, setSelected] = useState<(number | null)[]>([])
  const [submitted, setSubmitted] = useState(false)

  const { data, isLoading, isError } = useQuery({
    queryKey: ['quiz', lessonId],
    queryFn: () => aiApi.generateQuiz(lessonId),
    staleTime: Infinity,
  })

  const quizData = data?.data as QuizResult | undefined
  const questions = quizData?.questions ?? []
  const source = quizData?.transcriptSource

  useEffect(() => {
    if (questions.length) setSelected(new Array(questions.length).fill(null))
  }, [questions.length])

  const score = submitted
    ? questions.filter((q, i) => selected[i] === q.correctIndex).length
    : 0

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="relative w-full max-w-xl max-h-[90vh] overflow-y-auto rounded-2xl border border-border bg-background shadow-xl">
        <div className="sticky top-0 flex items-center justify-between border-b border-border bg-background p-5">
          <div className="flex items-center gap-2">
            <Brain className="h-5 w-5 text-primary" />
            <h2 className="text-base font-semibold text-foreground">Study Buddy Quiz</h2>
          </div>
          <button onClick={onClose} className="text-muted-foreground hover:text-foreground">
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="p-5 space-y-6">
          {isLoading && (
            <div className="flex flex-col items-center gap-3 py-12">
              <div className="h-6 w-6 animate-spin rounded-full border-2 border-border border-t-primary" />
              <p className="text-sm font-medium text-foreground">Analyzing lesson content...</p>
              <p className="text-xs text-muted-foreground text-center max-w-xs">
                Transcribing your video and generating questions. This takes 10–30 seconds the first time.
              </p>
            </div>
          )}

          {isError && (
            <p className="py-8 text-center text-sm text-muted-foreground">
              Failed to generate quiz. Please try again.
            </p>
          )}

          {source && !isLoading && (
            <p className="text-xs text-muted-foreground text-center">
              {source === 'youtube_captions' && 'Quiz based on YouTube captions'}
              {source === 'whisper' && 'Quiz based on AI video transcription'}
              {source === 'cached' && 'Quiz based on saved transcript'}
              {source === 'none' && 'Quiz based on lesson topic (no transcript available)'}
            </p>
          )}

          {submitted && (
            <div className={`rounded-xl p-4 text-center ${score >= questions.length * 0.8 ? 'bg-emerald-500/10 text-emerald-600' : 'bg-amber-500/10 text-amber-600'}`}>
              <p className="text-lg font-bold">{score} / {questions.length} correct</p>
              <p className="text-sm mt-1">{score === questions.length ? 'Perfect score!' : score >= questions.length * 0.8 ? 'Great job!' : 'Keep studying!'}</p>
            </div>
          )}

          {questions.map((q: QuizQuestion, qi: number) => (
            <div key={qi} className="space-y-3">
              <p className="text-sm font-medium text-foreground">
                {qi + 1}. {q.question}
              </p>
              <div className="space-y-2">
                {q.options.map((opt: string, oi: number) => {
                  const isSelected = selected[qi] === oi
                  const isCorrect = submitted && oi === q.correctIndex
                  const isWrong = submitted && isSelected && oi !== q.correctIndex

                  return (
                    <button
                      key={oi}
                      disabled={submitted}
                      onClick={() => setSelected((s) => { const n = [...s]; n[qi] = oi; return n })}
                      className={`w-full rounded-lg border px-4 py-2.5 text-left text-sm transition-colors ${
                        isCorrect
                          ? 'border-emerald-500 bg-emerald-500/10 text-emerald-700'
                          : isWrong
                          ? 'border-red-500 bg-red-500/10 text-red-700'
                          : isSelected
                          ? 'border-primary bg-primary/10 text-primary'
                          : 'border-border bg-card text-foreground hover:bg-muted'
                      }`}
                    >
                      {opt}
                    </button>
                  )
                })}
              </div>
              {submitted && (
                <p className="text-xs text-muted-foreground italic">{q.explanation}</p>
              )}
            </div>
          ))}

          {questions.length > 0 && !submitted && (
            <button
              disabled={selected.some((s) => s === null)}
              onClick={() => setSubmitted(true)}
              className="w-full rounded-lg bg-primary py-2.5 text-sm font-semibold text-white disabled:opacity-50"
            >
              Submit answers
            </button>
          )}

          {submitted && (
            <button
              onClick={() => { setSelected(new Array(questions.length).fill(null)); setSubmitted(false) }}
              className="w-full rounded-lg border border-border py-2.5 text-sm font-semibold text-foreground hover:bg-muted"
            >
              Try again
            </button>
          )}
        </div>
      </div>
    </div>
  )
}

// ─── Lesson View ──────────────────────────────────────────────────────────────

function LessonView({
  lesson,
  communityId,
  courseId,
  sectionId,
  isCompleted,
  onQuiz,
}: {
  lesson: Lesson
  communityId: string
  courseId: string
  sectionId: string
  isCompleted: boolean
  onQuiz: () => void
}) {
  const queryClient = useQueryClient()
  const [showTranscript, setShowTranscript] = useState(false)

  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ['lesson-progress', courseId] })
    queryClient.invalidateQueries({ queryKey: ['course-progress', courseId] })
  }

  const { mutate: savePosition } = useMutation({
    mutationFn: (position: number) =>
      courseApi.saveVideoPosition(communityId, courseId, sectionId, lesson.id, position),
  })

  const { mutate: markComplete, isPending: completing } = useMutation({
    mutationFn: () => courseApi.markComplete(communityId, courseId, sectionId, lesson.id),
    onSuccess: () => { invalidate(); toast.success('Lesson completed!'); xpToast(10) },
    onError: (err) => toast.error((err as Error).message),
  })

  const { mutate: markIncomplete, isPending: uncompleting } = useMutation({
    mutationFn: () => courseApi.markIncomplete(communityId, courseId, sectionId, lesson.id),
    onSuccess: () => { invalidate(); toast.success('Marked as incomplete') },
    onError: (err) => toast.error((err as Error).message),
  })

  return (
    <div className="space-y-6">
      {/* Video */}
      {lesson.videoUrl && (
        <VideoPlayer
          url={lesson.videoUrl}
          savedPosition={lesson.videoPosition}
          onSavePosition={(pos) => savePosition(pos)}
        />
      )}

      {/* Title + complete button */}
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-xl font-bold text-foreground">{lesson.title}</h1>
          {lesson.description && (
            <p className="mt-1 text-sm text-muted-foreground">{lesson.description}</p>
          )}
        </div>
        <div className="flex shrink-0 items-center gap-2">
          <Button size="sm" variant="outline" onClick={onQuiz}>
            <Brain className="h-4 w-4" />
            Quiz me
          </Button>
          <Button
            size="sm"
            variant={isCompleted ? 'outline' : 'default'}
            onClick={() => (isCompleted ? markIncomplete() : markComplete())}
            disabled={completing || uncompleting}
          >
            {isCompleted ? (
              <>
                <CheckSquare className="h-4 w-4" />
                Completed
              </>
            ) : (
              <>
                <Square className="h-4 w-4" />
                Mark complete
              </>
            )}
          </Button>
        </div>
      </div>

      {/* Content */}
      {lesson.content && (
        <div className="rounded-xl border border-border bg-card p-5">
          <RichTextRenderer content={lesson.content} />
        </div>
      )}

      {/* Attachments */}
      {lesson.attachments.length > 0 && (
        <div className="rounded-xl border border-border bg-card p-5">
          <h2 className="mb-3 flex items-center gap-2 text-sm font-semibold text-foreground">
            <Paperclip className="h-4 w-4" />
            Resources
          </h2>
          <div className="space-y-2">
            {lesson.attachments.map((a) => (
              <a
                key={a.id}
                href={a.url}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-2.5 rounded-lg border border-border p-3 text-sm text-foreground transition-colors hover:bg-muted"
              >
                {a.type === 'LINK' ? (
                  <ExternalLink className="h-4 w-4 shrink-0 text-muted-foreground" />
                ) : (
                  <FileText className="h-4 w-4 shrink-0 text-muted-foreground" />
                )}
                <span className="min-w-0 flex-1 truncate">{a.name}</span>
              </a>
            ))}
          </div>
        </div>
      )}

      {/* Transcript */}
      {lesson.transcript && (
        <div className="rounded-xl border border-border bg-card p-5">
          <button
            onClick={() => setShowTranscript((s) => !s)}
            className="flex w-full items-center justify-between text-sm font-semibold text-foreground"
          >
            Transcript
            <ChevronDown
              className={`h-4 w-4 text-muted-foreground transition-transform ${showTranscript ? 'rotate-180' : ''}`}
            />
          </button>
          {showTranscript && (
            <p className="mt-3 whitespace-pre-wrap text-sm leading-relaxed text-muted-foreground">
              {lesson.transcript}
            </p>
          )}
        </div>
      )}
    </div>
  )
}

// ─── Locked Screen ────────────────────────────────────────────────────────────

function LockedScreen({
  course,
  communityId,
  errorMessage,
}: {
  course: Course
  communityId: string
  errorMessage: string
}) {
  const [purchaseOpen, setPurchaseOpen] = useState(false)

  const isBuyNow = course.accessType === 'BUY_NOW'
  const isPrivate = course.accessType === 'PRIVATE'
  const isTimeUnlock = course.accessType === 'TIME_UNLOCK'

  return (
    <div className="flex flex-col items-center justify-center rounded-xl border border-border bg-card py-16 text-center">
      <div className="flex h-14 w-14 items-center justify-center rounded-full bg-muted">
        <Lock className="h-6 w-6 text-muted-foreground" />
      </div>
      <h2 className="mt-4 text-lg font-semibold text-foreground">Course locked</h2>
      <p className="mt-2 max-w-sm text-sm text-muted-foreground">{errorMessage}</p>

      {isBuyNow && course.price && (
        <div className="mt-6">
          <p className="mb-3 text-2xl font-bold text-foreground">${course.price}</p>
          <Button onClick={() => setPurchaseOpen(true)}>
            <ShoppingCartIcon className="h-4 w-4" />
            Buy this course
          </Button>
          <PurchaseCourseModal
            open={purchaseOpen}
            onOpenChange={setPurchaseOpen}
            course={course}
            communityId={communityId}
          />
        </div>
      )}

      {isPrivate && (
        <p className="mt-4 text-sm text-muted-foreground">
          Upgrade your membership to access this course.
        </p>
      )}

      {isTimeUnlock && course.unlockAfterDays && (
        <p className="mt-4 text-sm text-muted-foreground">
          This course unlocks {course.unlockAfterDays} days after joining.
        </p>
      )}
    </div>
  )
}

function ShoppingCartIcon({ className }: { className?: string }) {
  return (
    <svg className={className} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="9" cy="21" r="1" /><circle cx="20" cy="21" r="1" />
      <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6" />
    </svg>
  )
}

// ─── CoursePage ───────────────────────────────────────────────────────────────

export function CoursePage() {
  const { id: communityId, courseId, sectionId, lessonId } = useParams<{
    id: string
    courseId: string
    sectionId?: string
    lessonId?: string
  }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const [quizOpen, setQuizOpen] = useState(false)

  const { data: courseData, isLoading: courseLoading, error: courseError } = useQuery({
    queryKey: ['course', courseId],
    queryFn: () => courseApi.getById(communityId!, courseId!),
    enabled: !!communityId && !!courseId,
    retry: false,
  })

  const { data: lessonData, isLoading: lessonLoading } = useQuery({
    queryKey: ['lesson', lessonId],
    queryFn: () => courseApi.getLesson(communityId!, courseId!, sectionId!, lessonId!),
    enabled: !!lessonId && !!sectionId,
    retry: false,
  })

  // Track which lessons are completed for this course
  const { data: progressData } = useQuery({
    queryKey: ['lesson-progress', courseId],
    queryFn: () => courseApi.getProgress(communityId!, courseId!),
    enabled: !!communityId && !!courseId,
  })

  const course = courseData?.data?.course
  const lesson = lessonData?.data?.lesson
  const progress = progressData?.data?.progress

  const completedIds = new Set(progress?.completedLessonIds ?? [])

  const errorMsg = (courseError as Error | null)?.message ?? ''
  const isLocked =
    errorMsg.includes('Purchase required') ||
    errorMsg.includes('subscription') ||
    errorMsg.includes('paid members') ||
    errorMsg.includes('unlocks')

  // Auto-navigate to first lesson if no lesson selected
  const handleOpenCourse = (c: Course) => {
    if (!lessonId && c.sections.length > 0) {
      const firstSection = c.sections[0]
      if (firstSection.lessons.length > 0) {
        const firstLesson = firstSection.lessons[0]
        navigate(
          `/communities/${communityId}/classroom/${courseId}/sections/${firstSection.id}/lessons/${firstLesson.id}`,
          { replace: true },
        )
      }
    }
  }

  if (courseLoading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="h-6 w-6 animate-spin rounded-full border-4 border-border border-t-primary" />
      </div>
    )
  }

  if (isLocked && course) {
    return (
      <div className="space-y-4">
        <button
          onClick={() => navigate(`/communities/${communityId}/classroom`)}
          className="flex items-center gap-1.5 text-sm text-muted-foreground transition-colors hover:text-foreground"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to classroom
        </button>
        <LockedScreen course={course} communityId={communityId!} errorMessage={errorMsg} />
      </div>
    )
  }

  if (!course) {
    return (
      <div className="rounded-xl border border-border bg-card p-8 text-center text-muted-foreground">
        Course not found.
      </div>
    )
  }

  // Auto-navigate on first load
  if (!lessonId) {
    handleOpenCourse(course)
  }

  const totalLessons = course.sections.reduce((acc, s) => acc + s.lessons.length, 0)
  const pct = progress?.percentage ?? 0

  return (
    <div className="space-y-4">
      {quizOpen && lessonId && (
        <QuizModal lessonId={lessonId} onClose={() => setQuizOpen(false)} />
      )}

      {/* Progress Coach */}
      {communityId && <ProgressCoachBanner communityId={communityId} />}

      {/* Header */}
      <div>
        <button
          onClick={() => navigate(`/communities/${communityId}/classroom`)}
          className="mb-3 flex items-center gap-1.5 text-sm text-muted-foreground transition-colors hover:text-foreground"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to classroom
        </button>

        <div className="flex items-center justify-between gap-4">
          <h1 className="text-lg font-bold text-foreground">{course.title}</h1>
          <span className="shrink-0 text-sm font-medium text-primary">{pct}%</span>
        </div>
        <div className="mt-2 h-1.5 w-full overflow-hidden rounded-full bg-muted">
          <div
            className="h-full rounded-full bg-primary transition-all duration-500"
            style={{ width: `${pct}%` }}
          />
        </div>
        <p className="mt-1 text-xs text-muted-foreground">
          {progress?.completedCount ?? 0} / {totalLessons} lessons completed
        </p>
      </div>

      {/* Layout */}
      <div className="flex gap-4">
        {/* Sidebar */}
        <aside className="hidden w-64 shrink-0 lg:block">
          <div className="sticky top-24 space-y-1 rounded-xl border border-border bg-card p-3">
            {course.sections.length === 0 ? (
              <p className="px-3 py-4 text-center text-sm text-muted-foreground">
                No lessons yet.
              </p>
            ) : (
              course.sections.map((section) => (
                <SidebarSection
                  key={section.id}
                  section={section}
                  communityId={communityId!}
                  courseId={courseId!}
                  activeLessonId={lessonId}
                  completedIds={completedIds}
                />
              ))
            )}
          </div>
        </aside>

        {/* Main */}
        <main className="min-w-0 flex-1">
          {lessonLoading ? (
            <div className="flex h-64 items-center justify-center">
              <div className="h-6 w-6 animate-spin rounded-full border-4 border-border border-t-primary" />
            </div>
          ) : lesson && sectionId ? (
            <LessonView
              lesson={lesson}
              communityId={communityId!}
              courseId={courseId!}
              sectionId={sectionId}
              isCompleted={completedIds.has(lesson.id)}
              onQuiz={() => setQuizOpen(true)}
            />
          ) : (
            <div className="flex flex-col items-center justify-center rounded-xl border border-border bg-card py-16 text-center">
              <BookOpen className="h-9 w-9 text-muted-foreground" />
              <p className="mt-3 font-semibold text-foreground">Select a lesson</p>
              <p className="mt-1 text-sm text-muted-foreground">
                Choose a lesson from the sidebar to get started.
              </p>
            </div>
          )}
        </main>
      </div>
    </div>
  )
}
