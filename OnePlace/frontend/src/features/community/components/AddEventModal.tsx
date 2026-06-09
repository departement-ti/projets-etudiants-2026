import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { format } from 'date-fns'
import { X, Upload } from 'lucide-react'
import { eventApi } from '@/api/event'
import { uploadFile } from '@/api/upload'
import type { EventAccess } from '@/types/event'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'

// ─── Constants ────────────────────────────────────────────────────────────────

const TIMES = Array.from({ length: 48 }, (_, i) => {
  const h = Math.floor(i / 2)
  const m = i % 2 === 0 ? '00' : '30'
  const ampm = h < 12 ? 'AM' : 'PM'
  const display = `${h === 0 ? 12 : h > 12 ? h - 12 : h}:${m} ${ampm}`
  const value = `${String(h).padStart(2, '0')}:${m}`
  return { label: display, value }
})

const DURATIONS = [
  { label: '30 min', value: 30 },
  { label: '1 hour', value: 60 },
  { label: '1.5 hours', value: 90 },
  { label: '2 hours', value: 120 },
  { label: '3 hours', value: 180 },
  { label: '4 hours', value: 240 },
]

const TIMEZONES = [
  'UTC',
  'America/New_York',
  'America/Chicago',
  'America/Denver',
  'America/Los_Angeles',
  'Europe/London',
  'Europe/Paris',
  'Europe/Berlin',
  'Africa/Lagos',
  'Asia/Dubai',
  'Asia/Kolkata',
  'Asia/Singapore',
  'Asia/Tokyo',
  'Australia/Sydney',
]

const LOCATION_TYPES = [
  { value: 'oneplace', label: 'OnePlace Call' },
  { value: 'zoom',     label: 'Zoom' },
  { value: 'meet',     label: 'Google Meet' },
  { value: 'address',  label: 'Address' },
]

const LOCATION_PLACEHOLDERS: Record<string, string> = {
  zoom:    'Paste Zoom meeting link…',
  meet:    'Paste Google Meet link…',
  address: 'Enter the address…',
}

// ─── Schema ───────────────────────────────────────────────────────────────────

const schema = z.object({
  title: z.string().min(1, 'Title is required').max(30, 'Max 30 characters'),
  date: z.string().min(1, 'Date is required'),
  time: z.string().min(1, 'Time is required'),
  duration: z.coerce.number().optional(),
  timezone: z.string(),
  isRecurring: z.boolean(),
  location: z.string().optional(),
  description: z.string().max(300, 'Max 300 characters').optional(),
  accessType: z.enum(['ALL_MEMBERS', 'PAID_MEMBERS']),
  emailReminder: z.boolean(),
})

type FormValues = z.infer<typeof schema>

// ─── Component ───────────────────────────────────────────────────────────────

interface Props {
  open: boolean
  onOpenChange: (open: boolean) => void
  communityId: string
}

export function AddEventModal({ open, onOpenChange, communityId }: Props) {
  const queryClient = useQueryClient()
  const [coverUrl, setCoverUrl] = useState<string | null>(null)
  const [uploadingCover, setUploadingCover] = useState(false)
  const [locationLink, setLocationLink] = useState('')

  const today = format(new Date(), 'yyyy-MM-dd')
  const guessedTz = Intl.DateTimeFormat().resolvedOptions().timeZone

  const {
    register,
    handleSubmit,
    watch,
    setValue,
    reset,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      title: '',
      date: today,
      time: '09:00',
      duration: 60,
      timezone: TIMEZONES.includes(guessedTz) ? guessedTz : 'UTC',
      isRecurring: false,
      location: '',
      description: '',
      accessType: 'ALL_MEMBERS',
      emailReminder: false,
    },
  })

  const title = watch('title')
  const description = watch('description') ?? ''
  const locationType = watch('location') ?? ''

  const create = useMutation({
    mutationFn: (data: FormValues) => {
      const startAt = new Date(`${data.date}T${data.time}:00`).toISOString()
      return eventApi.create(communityId, {
        title: data.title,
        description: data.description || undefined,
        coverUrl: coverUrl ?? undefined,
        location: data.location === 'oneplace'
          ? 'OnePlace Call'
          : data.location
            ? locationLink.trim() || undefined
            : undefined,
        startAt,
        duration: data.duration,
        timezone: data.timezone,
        isRecurring: data.isRecurring,
        accessType: data.accessType as EventAccess,
        emailReminder: data.emailReminder,
      })
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['events', communityId] })
      toast.success('Event created')
      reset()
      setCoverUrl(null)
      setLocationLink('')
      onOpenChange(false)
    },
    onError: (err: Error) => toast.error(err.message),
  })

  async function handleCoverUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    setUploadingCover(true)
    try {
      const url = await uploadFile(file, 'communities')
      setCoverUrl(url)
    } catch {
      toast.error('Failed to upload image')
    } finally {
      setUploadingCover(false)
    }
  }

  function handleClose() {
    reset()
    setCoverUrl(null)
    setLocationLink('')
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="max-h-[90vh] w-full max-w-lg overflow-y-auto p-0">
        <DialogHeader className="border-b border-border px-6 py-4">
          <DialogTitle className="text-lg font-semibold">Add event</DialogTitle>
          <p className="mt-0.5 text-xs text-muted-foreground">
            Need ideas? Try one of these fun formats:{' '}
            <span className="text-primary">coffee hour</span>,{' '}
            <span className="text-primary">Q&A</span>,{' '}
            <span className="text-primary">co-working session</span>, or{' '}
            <span className="text-primary">happy hour</span>
          </p>
        </DialogHeader>

        <form onSubmit={handleSubmit((v) => create.mutate(v))} className="space-y-5 px-6 py-5">

          {/* Title */}
          <div>
            <input
              {...register('title')}
              placeholder="Title"
              maxLength={30}
              className="w-full rounded-lg border border-border bg-background px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/40"
            />
            <div className="mt-1 flex items-center justify-between">
              {errors.title ? (
                <p className="text-xs text-destructive">{errors.title.message}</p>
              ) : <span />}
              <span className="text-xs text-muted-foreground">{title.length} / 30</span>
            </div>
          </div>

          {/* Date / Time / Duration / Timezone */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="mb-1 block text-xs text-muted-foreground">Date</label>
              <input
                type="date"
                {...register('date')}
                className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary/40"
              />
            </div>
            <div>
              <label className="mb-1 block text-xs text-muted-foreground">Time</label>
              <select
                {...register('time')}
                className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary/40"
              >
                {TIMES.map((t) => (
                  <option key={t.value} value={t.value}>{t.label}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="mb-1 block text-xs text-muted-foreground">Duration</label>
              <select
                {...register('duration')}
                className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary/40"
              >
                {DURATIONS.map((d) => (
                  <option key={d.value} value={d.value}>{d.label}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="mb-1 block text-xs text-muted-foreground">Timezone</label>
              <select
                {...register('timezone')}
                className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary/40"
              >
                {TIMEZONES.map((tz) => (
                  <option key={tz} value={tz}>{tz.replace('_', ' ')}</option>
                ))}
              </select>
            </div>
          </div>

          {/* Recurring */}
          <label className="flex cursor-pointer items-center gap-2.5">
            <input
              type="checkbox"
              {...register('isRecurring')}
              className="h-4 w-4 rounded border-border accent-primary"
            />
            <span className="text-sm text-foreground">Recurring event</span>
          </label>

          {/* Location */}
          <div>
            <label className="mb-1 block text-xs text-muted-foreground">Location</label>
            <select
              {...register('location')}
              className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary/40"
            >
              <option value="">Select location</option>
              {LOCATION_TYPES.map((l) => (
                <option key={l.value} value={l.value}>{l.label}</option>
              ))}
            </select>
            {locationType && locationType !== 'oneplace' && (
              <input
                type="text"
                value={locationLink}
                onChange={(e) => setLocationLink(e.target.value)}
                placeholder={LOCATION_PLACEHOLDERS[locationType]}
                className="mt-2 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/40"
              />
            )}
            {locationType === 'oneplace' && (
              <p className="mt-1.5 text-xs text-muted-foreground">
                A OnePlace Call room will be generated automatically when the event starts.
              </p>
            )}
          </div>

          {/* Description */}
          <div>
            <textarea
              {...register('description')}
              placeholder="Description"
              maxLength={300}
              rows={3}
              className="w-full resize-none rounded-lg border border-border bg-background px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/40"
            />
            <div className="mt-1 flex justify-end">
              <span className="text-xs text-muted-foreground">{description.length} / 300</span>
            </div>
          </div>

          {/* Cover image + Access side-by-side */}
          <div className="flex gap-4">
            {/* Cover upload */}
            <label className="relative flex h-32 w-40 shrink-0 cursor-pointer flex-col items-center justify-center rounded-xl border-2 border-dashed border-border bg-muted/30 text-center transition-colors hover:bg-muted/60">
              {coverUrl ? (
                <>
                  <img src={coverUrl} alt="cover" className="h-full w-full rounded-xl object-cover" />
                  <button
                    type="button"
                    onClick={(e) => { e.preventDefault(); setCoverUrl(null) }}
                    className="absolute -right-2 -top-2 flex h-5 w-5 items-center justify-center rounded-full bg-destructive text-white"
                  >
                    <X className="h-3 w-3" />
                  </button>
                </>
              ) : (
                <>
                  <Upload className="mb-1 h-5 w-5 text-muted-foreground" />
                  <span className="text-xs text-primary">
                    {uploadingCover ? 'Uploading…' : 'Upload cover image'}
                  </span>
                  <span className="mt-0.5 text-[10px] text-muted-foreground">1460 × 752 px</span>
                </>
              )}
              <input
                type="file"
                accept="image/*"
                className="sr-only"
                onChange={handleCoverUpload}
                disabled={uploadingCover}
              />
            </label>

            {/* Access */}
            <div className="flex-1">
              <p className="mb-2 text-sm font-medium text-foreground">Access</p>
              <div className="space-y-2">
                {([
                  { value: 'ALL_MEMBERS', label: 'All members' },
                  { value: 'PAID_MEMBERS', label: 'Paid members only' },
                ] as { value: EventAccess; label: string }[]).map((opt) => (
                  <label key={opt.value} className="flex cursor-pointer items-center gap-2.5">
                    <input
                      type="radio"
                      value={opt.value}
                      {...register('accessType')}
                      className="accent-primary"
                    />
                    <span className="text-sm text-foreground">{opt.label}</span>
                  </label>
                ))}
              </div>
            </div>
          </div>

          {/* Email reminder */}
          <label className="flex cursor-pointer items-center gap-2.5">
            <input
              type="checkbox"
              {...register('emailReminder')}
              className="h-4 w-4 rounded border-border accent-primary"
            />
            <span className="text-sm text-foreground">Remind members by email 1 day before</span>
          </label>

          {/* Actions */}
          <div className="flex justify-end gap-3 border-t border-border pt-4">
            <Button type="button" variant="ghost" onClick={handleClose}>
              Cancel
            </Button>
            <Button type="submit" disabled={create.isPending}>
              {create.isPending ? 'Adding…' : 'Add'}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
