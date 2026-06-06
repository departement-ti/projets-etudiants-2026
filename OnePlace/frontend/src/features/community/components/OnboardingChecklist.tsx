import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { ChevronUp, ChevronDown } from 'lucide-react'
import { communityApi } from '@/api/community'
import { courseApi } from '@/api/course'
import { useAuthStore } from '@/store/auth.store'

// ─── Circular progress arc ────────────────────────────────────────────────────

function ArcProgress({ completed, total }: { completed: number; total: number }) {
  const r = 9
  const circumference = 2 * Math.PI * r
  const offset = circumference - (completed / total) * circumference
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" className="-rotate-90 shrink-0">
      <circle cx="12" cy="12" r={r} fill="none" stroke="hsl(var(--border))" strokeWidth="2.5" />
      <circle
        cx="12" cy="12" r={r} fill="none"
        stroke="#22c55e"
        strokeWidth="2.5"
        strokeDasharray={circumference}
        strokeDashoffset={offset}
        strokeLinecap="round"
        className="transition-[stroke-dashoffset] duration-500"
      />
    </svg>
  )
}

// ─── Step icons ───────────────────────────────────────────────────────────────

function DoneIcon() {
  return (
    <div className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-emerald-500">
      <svg viewBox="0 0 12 12" fill="none" className="h-3 w-3">
        <path d="M2 6l3 3 5-5" stroke="white" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    </div>
  )
}

function TodoIcon() {
  return <div className="h-5 w-5 shrink-0 rounded-full border-2 border-muted-foreground/30" />
}

// ─── OnboardingChecklist ──────────────────────────────────────────────────────

interface OnboardingChecklistProps {
  communityId: string
  onCreatePost: () => void
}

export function OnboardingChecklist({ communityId, onCreatePost }: OnboardingChecklistProps) {
  const { user } = useAuthStore()
  const navigate = useNavigate()
  const [open, setOpen] = useState(true)

  const { data: communityData } = useQuery({
    queryKey: ['community', communityId],
    queryFn: () => communityApi.getById(communityId),
    enabled: !!communityId,
  })

  const { data: coursesData } = useQuery({
    queryKey: ['courses', communityId],
    queryFn: () => courseApi.list(communityId),
    enabled: !!communityId,
  })

  const community = communityData?.data?.community
  const courses = coursesData?.data?.courses ?? []

  if (!community || !user) return null
  if (community.creator.id !== user.id) return null

  const steps = [
    {
      label: 'Set cover image',
      done: !!community.coverUrl,
      onClick: () => navigate(`/communities/${communityId}/settings/general`),
    },
    {
      label: 'Configure pricing',
      done: community.pricingModel !== 'FREE',
      onClick: () => navigate(`/communities/${communityId}/settings/pricing`),
    },
    {
      label: 'Create your first course',
      done: courses.length > 0,
      onClick: () => navigate(`/communities/${communityId}/classroom/manage`),
    },
    {
      label: 'Write your first post',
      done: community._count.posts > 0,
      onClick: onCreatePost,
    },
  ]

  const completedCount = steps.filter((s) => s.done).length

  // Hide once everything is done
  if (completedCount === steps.length) return null

  return (
    <div className="overflow-hidden rounded-xl border border-border bg-card">
      {/* Header */}
      <button
        onClick={() => setOpen((o) => !o)}
        className="flex w-full items-center gap-3 px-4 py-3.5 text-left"
      >
        <ArcProgress completed={completedCount} total={steps.length} />
        <span className="flex-1 font-semibold text-foreground">Set up your community</span>
        <div className="flex h-8 w-8 items-center justify-center rounded-full bg-muted">
          {open
            ? <ChevronUp className="h-4 w-4 text-muted-foreground" />
            : <ChevronDown className="h-4 w-4 text-muted-foreground" />
          }
        </div>
      </button>

      {/* Steps */}
      {open && (
        <div className="border-t border-border px-4 py-1.5">
          {steps.map((step) => (
            <button
              key={step.label}
              onClick={step.onClick}
              className="flex w-full items-center gap-3 py-2.5 text-left"
            >
              {step.done ? <DoneIcon /> : <TodoIcon />}
              <span className="text-sm font-medium text-primary">
                {step.label}
              </span>
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
