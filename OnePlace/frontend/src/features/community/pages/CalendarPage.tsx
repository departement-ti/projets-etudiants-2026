import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  format,
  startOfMonth,
  endOfMonth,
  startOfWeek,
  endOfWeek,
  eachDayOfInterval,
  isSameMonth,
  isSameDay,
  isToday,
  addMonths,
  subMonths,
  parseISO,
} from 'date-fns'
import { ChevronLeft, ChevronRight, Plus, List, CalendarDays, Trash2, Clock, MapPin, Video, Users } from 'lucide-react'
import { Dialog, DialogContent } from '@/components/ui/dialog'
import { toast } from 'sonner'
import { cn } from '@/lib/utils'
import { eventApi } from '@/api/event'
import { useAuthStore } from '@/store/auth.store'
import { communityApi } from '@/api/community'
import type { CommunityEvent } from '@/types/event'
import { AddEventModal } from '../components/AddEventModal'
import { Button } from '@/components/ui/button'

// ─── Helpers ──────────────────────────────────────────────────────────────────

function formatDuration(minutes: number | null): string {
  if (!minutes) return ''
  if (minutes < 60) return `${minutes}m`
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  return m ? `${h}h ${m}m` : `${h}h`
}

function formatEventTime(startAt: string, timezone: string): string {
  try {
    return new Intl.DateTimeFormat('en-US', {
      hour: 'numeric',
      minute: '2-digit',
      timeZone: timezone,
      hour12: true,
    }).format(new Date(startAt))
  } catch {
    return format(parseISO(startAt), 'h:mm a')
  }
}

const EVENT_COLORS = [
  'bg-primary/80',
  'bg-blue-500/80',
  'bg-green-500/80',
  'bg-amber-500/80',
  'bg-pink-500/80',
  'bg-purple-500/80',
]

function eventColor(id: string): string {
  const n = id.split('').reduce((acc, c) => acc + c.charCodeAt(0), 0)
  return EVENT_COLORS[n % EVENT_COLORS.length]!
}

// ─── Event pill shown inside a calendar cell ──────────────────────────────────

function EventPill({
  event,
  onDelete,
  canDelete,
  onClick,
}: {
  event: CommunityEvent
  onDelete: (id: string) => void
  canDelete: boolean
  onClick: () => void
}) {
  return (
    <div
      onClick={onClick}
      className={cn(
        'group flex cursor-pointer items-center justify-between rounded px-1.5 py-0.5 text-[11px] font-medium text-white',
        eventColor(event.id),
      )}
    >
      <span className="truncate">{event.title}</span>
      {canDelete && (
        <button
          onClick={(e) => { e.stopPropagation(); onDelete(event.id) }}
          className="ml-1 hidden shrink-0 group-hover:block"
        >
          <Trash2 className="h-2.5 w-2.5" />
        </button>
      )}
    </div>
  )
}

// ─── Event Detail Modal ───────────────────────────────────────────────────────

function EventDetailModal({
  event,
  open,
  onClose,
  onDelete,
  canDelete,
}: {
  event: CommunityEvent | null
  open: boolean
  onClose: () => void
  onDelete: (id: string) => void
  canDelete: boolean
}) {
  if (!event) return null

  const time = formatEventTime(event.startAt, event.timezone)
  const date = format(parseISO(event.startAt), 'EEEE, MMMM d, yyyy')

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-md p-0 overflow-hidden">
        {/* Cover */}
        {event.coverUrl && (
          <img src={event.coverUrl} alt={event.title} className="h-36 w-full object-cover" />
        )}

        <div className="p-5 space-y-4">
          {/* Title */}
          <h2 className="text-lg font-semibold text-foreground">{event.title}</h2>

          {/* Meta */}
          <div className="space-y-2 text-sm text-muted-foreground">
            <div className="flex items-center gap-2">
              <CalendarDays className="h-4 w-4 shrink-0" />
              <span>{date}</span>
            </div>
            <div className="flex items-center gap-2">
              <Clock className="h-4 w-4 shrink-0" />
              <span>{time}{event.duration ? ` · ${formatDuration(event.duration)}` : ''} ({event.timezone})</span>
            </div>
            {event.location && (
              <div className="flex items-center gap-2">
                <MapPin className="h-4 w-4 shrink-0" />
                <span>{event.location}</span>
              </div>
            )}
            <div className="flex items-center gap-2">
              <Users className="h-4 w-4 shrink-0" />
              <span>{event.accessType === 'ALL_MEMBERS' ? 'All members' : 'Paid members only'}</span>
            </div>
          </div>

          {/* Description */}
          {event.description && (
            <p className="text-sm text-muted-foreground leading-relaxed">{event.description}</p>
          )}

          {/* Actions */}
          <div className="flex items-center justify-between pt-1">
            {event.callRoomUrl ? (
              <a
                href={event.callRoomUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-opacity hover:opacity-90"
              >
                <Video className="h-4 w-4" />
                Join Call
              </a>
            ) : <span />}

            {canDelete && (
              <button
                onClick={() => { onDelete(event.id); onClose() }}
                className="flex items-center gap-1.5 text-sm text-muted-foreground transition-colors hover:text-destructive"
              >
                <Trash2 className="h-4 w-4" />
                Delete
              </button>
            )}
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}

// ─── List-view event card ─────────────────────────────────────────────────────

function EventCard({
  event,
  onDelete,
  canDelete,
}: {
  event: CommunityEvent
  onDelete: (id: string) => void
  canDelete: boolean
}) {
  const time = formatEventTime(event.startAt, event.timezone)
  const date = format(parseISO(event.startAt), 'EEE, MMM d')

  return (
    <div className="flex items-start gap-4 rounded-xl border border-border bg-card p-4">
      {/* Color stripe */}
      <div className={cn('mt-1 h-10 w-1 shrink-0 rounded-full', eventColor(event.id))} />

      <div className="min-w-0 flex-1">
        <p className="font-medium text-foreground">{event.title}</p>
        <div className="mt-1 flex flex-wrap items-center gap-3 text-xs text-muted-foreground">
          <span className="flex items-center gap-1">
            <CalendarDays className="h-3 w-3" />
            {date}
          </span>
          <span className="flex items-center gap-1">
            <Clock className="h-3 w-3" />
            {time}{event.duration ? ` · ${formatDuration(event.duration)}` : ''}
          </span>
          {event.location && (
            <span className="flex items-center gap-1">
              <MapPin className="h-3 w-3" />
              {event.location}
            </span>
          )}
        </div>
        {event.description && (
          <p className="mt-2 text-xs text-muted-foreground line-clamp-2">{event.description}</p>
        )}
      </div>

      <div className="flex shrink-0 items-center gap-2">
        {event.callRoomUrl && (
          <a
            href={event.callRoomUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-1.5 rounded-lg bg-primary px-3 py-1.5 text-xs font-medium text-primary-foreground transition-opacity hover:opacity-90"
          >
            <Video className="h-3.5 w-3.5" />
            Join Call
          </a>
        )}
        {canDelete && (
          <button
            onClick={() => onDelete(event.id)}
            className="text-muted-foreground transition-colors hover:text-destructive"
          >
            <Trash2 className="h-4 w-4" />
          </button>
        )}
      </div>
    </div>
  )
}

// ─── CalendarPage ─────────────────────────────────────────────────────────────

export function CalendarPage() {
  const { id: communityId } = useParams<{ id: string }>()
  const { user } = useAuthStore()
  const queryClient = useQueryClient()

  const [current, setCurrent] = useState(new Date())
  const [viewMode, setViewMode] = useState<'calendar' | 'list'>('calendar')
  const [addOpen, setAddOpen] = useState(false)
  const [selectedEvent, setSelectedEvent] = useState<CommunityEvent | null>(null)

  const year = current.getFullYear()
  const month = current.getMonth() + 1

  const { data, isLoading } = useQuery({
    queryKey: ['events', communityId, year, month],
    queryFn: () => eventApi.list(communityId!, year, month),
    enabled: !!communityId,
  })

  const { data: membershipData } = useQuery({
    queryKey: ['membership', communityId],
    queryFn: () => communityApi.getMyMembership(communityId!),
    enabled: !!communityId,
  })

  const memberRole = membershipData?.data?.membership?.role
  const canManage = memberRole === 'creator' || memberRole === 'admin'

  const events: CommunityEvent[] = data?.data?.events ?? []

  const deleteMutation = useMutation({
    mutationFn: (eventId: string) => eventApi.delete(communityId!, eventId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['events', communityId] })
      toast.success('Event deleted')
    },
    onError: (err: Error) => toast.error(err.message),
  })

  // ── Calendar grid ───────────────────────────────────────────────────────────

  const monthStart = startOfMonth(current)
  const monthEnd = endOfMonth(current)
  const gridStart = startOfWeek(monthStart, { weekStartsOn: 1 })
  const gridEnd = endOfWeek(monthEnd, { weekStartsOn: 1 })
  const days = eachDayOfInterval({ start: gridStart, end: gridEnd })

  function eventsForDay(day: Date): CommunityEvent[] {
    return events.filter((e) => isSameDay(parseISO(e.startAt), day))
  }

  const localTz = Intl.DateTimeFormat().resolvedOptions().timeZone
  const localTime = new Intl.DateTimeFormat('en-US', {
    hour: 'numeric',
    minute: '2-digit',
    timeZoneName: 'short',
    timeZone: localTz,
  }).format(new Date())

  return (
    <div className="space-y-4">
      {/* ── Toolbar ── */}
      <div className="flex items-center justify-between">
        {/* Month navigation */}
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            className="h-8 px-3 text-xs"
            onClick={() => setCurrent(new Date())}
          >
            Today
          </Button>
          <button
            onClick={() => setCurrent(subMonths(current, 1))}
            className="flex h-8 w-8 items-center justify-center rounded-lg border border-border text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
          >
            <ChevronLeft className="h-4 w-4" />
          </button>
          <button
            onClick={() => setCurrent(addMonths(current, 1))}
            className="flex h-8 w-8 items-center justify-center rounded-lg border border-border text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
          >
            <ChevronRight className="h-4 w-4" />
          </button>
          <div>
            <p className="text-base font-semibold text-foreground">{format(current, 'MMMM yyyy')}</p>
            <p className="text-xs text-muted-foreground">{localTime} {localTz} time</p>
          </div>
        </div>

        {/* Right: add + view toggles */}
        <div className="flex items-center gap-2">
          {canManage && (
            <button
              onClick={() => setAddOpen(true)}
              className="flex h-8 w-8 items-center justify-center rounded-lg border border-border text-muted-foreground transition-colors hover:bg-primary hover:text-white hover:border-primary"
            >
              <Plus className="h-4 w-4" />
            </button>
          )}
          <button
            onClick={() => setViewMode('list')}
            className={cn(
              'flex h-8 w-8 items-center justify-center rounded-lg border transition-colors',
              viewMode === 'list'
                ? 'border-primary bg-primary text-white'
                : 'border-border text-muted-foreground hover:bg-muted',
            )}
          >
            <List className="h-4 w-4" />
          </button>
          <button
            onClick={() => setViewMode('calendar')}
            className={cn(
              'flex h-8 w-8 items-center justify-center rounded-lg border transition-colors',
              viewMode === 'calendar'
                ? 'border-primary bg-primary text-white'
                : 'border-border text-muted-foreground hover:bg-muted',
            )}
          >
            <CalendarDays className="h-4 w-4" />
          </button>
        </div>
      </div>

      {/* ── Calendar grid ── */}
      {viewMode === 'calendar' && (
        <div className="overflow-hidden rounded-xl border border-border">
          {/* Day-of-week header */}
          <div className="grid grid-cols-7 border-b border-border bg-muted/40">
            {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) => (
              <div key={d} className="py-2 text-center text-xs font-medium text-muted-foreground">
                {d}
              </div>
            ))}
          </div>

          {/* Day cells */}
          {isLoading ? (
            <div className="flex h-64 items-center justify-center">
              <div className="h-6 w-6 animate-spin rounded-full border-2 border-border border-t-primary" />
            </div>
          ) : (
            <div className="grid grid-cols-7">
              {days.map((day, i) => {
                const dayEvents = eventsForDay(day)
                const inMonth = isSameMonth(day, current)
                const today = isToday(day)

                return (
                  <div
                    key={i}
                    className={cn(
                      'min-h-[100px] border-b border-r border-border p-1.5',
                      !inMonth && 'bg-muted/20',
                      i % 7 === 6 && 'border-r-0',
                    )}
                  >
                    {/* Day number */}
                    <div className="mb-1 flex justify-start">
                      <span
                        className={cn(
                          'flex h-6 w-6 items-center justify-center rounded-full text-xs font-medium',
                          today
                            ? 'bg-primary text-white'
                            : inMonth
                            ? 'text-foreground'
                            : 'text-muted-foreground/50',
                        )}
                      >
                        {format(day, 'd')}
                      </span>
                    </div>

                    {/* Event pills */}
                    <div className="space-y-0.5">
                      {dayEvents.slice(0, 3).map((e) => (
                        <EventPill
                          key={e.id}
                          event={e}
                          onDelete={(id) => deleteMutation.mutate(id)}
                          canDelete={canManage || e.creatorId === user?.id}
                          onClick={() => setSelectedEvent(e)}
                        />
                      ))}
                      {dayEvents.length > 3 && (
                        <p className="pl-1 text-[10px] text-muted-foreground">
                          +{dayEvents.length - 3} more
                        </p>
                      )}
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </div>
      )}

      {/* ── List view ── */}
      {viewMode === 'list' && (
        <div className="space-y-3">
          {isLoading ? (
            <div className="flex h-40 items-center justify-center">
              <div className="h-6 w-6 animate-spin rounded-full border-2 border-border border-t-primary" />
            </div>
          ) : events.length === 0 ? (
            <div className="flex flex-col items-center justify-center gap-3 rounded-xl border border-border py-16 text-center">
              <CalendarDays className="h-10 w-10 text-muted-foreground/40" />
              <p className="text-sm font-medium text-muted-foreground">No events this month</p>
              {canManage && (
                <Button size="sm" onClick={() => setAddOpen(true)}>
                  <Plus className="mr-1.5 h-3.5 w-3.5" />
                  Add event
                </Button>
              )}
            </div>
          ) : (
            events.map((e) => (
              <div key={e.id} onClick={() => setSelectedEvent(e)} className="cursor-pointer">
                <EventCard
                  event={e}
                  onDelete={(id) => deleteMutation.mutate(id)}
                  canDelete={canManage || e.creatorId === user?.id}
                />
              </div>
            ))
          )}
        </div>
      )}

      <AddEventModal
        open={addOpen}
        onOpenChange={setAddOpen}
        communityId={communityId!}
      />

      <EventDetailModal
        event={selectedEvent}
        open={!!selectedEvent}
        onClose={() => setSelectedEvent(null)}
        onDelete={(id) => deleteMutation.mutate(id)}
        canDelete={canManage || selectedEvent?.creatorId === user?.id}
      />
    </div>
  )
}
