import { useEffect, useRef, useState } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { ImageIcon, Loader2, Upload, X } from 'lucide-react'
import { toast } from 'sonner'
import { courseApi } from '@/api/course'
import { uploadFile } from '@/api/upload'
import type { CourseAccessType, CourseListItem } from '@/types/course'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

interface CourseFormModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  communityId: string
  course?: CourseListItem
}

const ACCESS_TYPES: { value: CourseAccessType; label: string; description: string }[] = [
  { value: 'OPEN', label: 'Open', description: 'All active members can access' },
  { value: 'BUY_NOW', label: 'Buy now', description: 'One-time purchase per member' },
  { value: 'TIME_UNLOCK', label: 'Time unlock', description: 'Unlocks after N days of membership' },
  { value: 'PRIVATE', label: 'Paid members only', description: 'FREEMIUM paid-tier only' },
]

export function CourseFormModal({ open, onOpenChange, communityId, course }: CourseFormModalProps) {
  const queryClient = useQueryClient()
  const fileInputRef = useRef<HTMLInputElement>(null)

  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [accessType, setAccessType] = useState<CourseAccessType>('OPEN')
  const [price, setPrice] = useState('')
  const [unlockAfterDays, setUnlockAfterDays] = useState('')
  const [thumbnail, setThumbnail] = useState('')
  const [isPublished, setIsPublished] = useState(false)
  const [uploading, setUploading] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    if (open) {
      setTitle(course?.title ?? '')
      setDescription(course?.description ?? '')
      setAccessType(course?.accessType ?? 'OPEN')
      setPrice(course?.price ?? '')
      setUnlockAfterDays(course?.unlockAfterDays?.toString() ?? '')
      setThumbnail(course?.thumbnail ?? '')
      setIsPublished(course?.isPublished ?? false)
      setError('')
    }
  }, [open, course])

  const { mutate, isPending } = useMutation({
    mutationFn: () => {
      const data = {
        title: title.trim(),
        description: description.trim() || undefined,
        thumbnail: thumbnail.trim() || undefined,
        accessType,
        price: accessType === 'BUY_NOW' && price ? Number(price) : undefined,
        unlockAfterDays: accessType === 'TIME_UNLOCK' && unlockAfterDays ? Number(unlockAfterDays) : undefined,
        isPublished,
      }
      return course
        ? courseApi.update(communityId, course.id, data)
        : courseApi.create(communityId, data)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['courses', communityId] })
      toast.success(course ? 'Course updated' : 'Course created')
      onOpenChange(false)
    },
    onError: (err) => toast.error((err as Error).message),
  })

  async function handleThumbnailUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    setUploading(true)
    try {
      const url = await uploadFile(file, 'courses')
      setThumbnail(url)
    } catch (err) {
      toast.error((err as Error).message ?? 'Upload failed')
    } finally {
      setUploading(false)
      if (fileInputRef.current) fileInputRef.current.value = ''
    }
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!title.trim()) { setError('Title is required'); return }
    if (accessType === 'BUY_NOW' && !price) { setError('Price is required for Buy now courses'); return }
    if (accessType === 'TIME_UNLOCK' && !unlockAfterDays) { setError('Unlock days is required'); return }
    mutate()
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{course ? 'Edit course' : 'Create course'}</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-5">
          {/* Title */}
          <div className="space-y-1.5">
            <Label htmlFor="title">Title</Label>
            <Input
              id="title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g. Getting started with strength training"
            />
          </div>

          {/* Description */}
          <div className="space-y-1.5">
            <Label htmlFor="description">Description</Label>
            <textarea
              id="description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Short description shown on the course card..."
              rows={3}
              className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring resize-none"
            />
          </div>

          {/* Thumbnail */}
          <div className="space-y-1.5">
            <Label>Thumbnail</Label>
            <div className="flex gap-2">
              {thumbnail ? (
                <div className="relative h-20 w-32 shrink-0 overflow-hidden rounded-lg border border-border">
                  <img src={thumbnail} alt="thumbnail" className="h-full w-full object-cover" />
                  <button
                    type="button"
                    onClick={() => setThumbnail('')}
                    className="absolute right-1 top-1 rounded-full bg-background/80 p-0.5 text-foreground hover:bg-background"
                  >
                    <X className="h-3 w-3" />
                  </button>
                </div>
              ) : (
                <div className="flex h-20 w-32 shrink-0 items-center justify-center rounded-lg border border-dashed border-border bg-muted/50">
                  <ImageIcon className="h-6 w-6 text-muted-foreground" />
                </div>
              )}
              <div className="flex flex-col gap-2">
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={() => fileInputRef.current?.click()}
                  disabled={uploading}
                >
                  {uploading ? (
                    <><Loader2 className="mr-1.5 h-3.5 w-3.5 animate-spin" />Uploading...</>
                  ) : (
                    <><Upload className="mr-1.5 h-3.5 w-3.5" />Upload image</>
                  )}
                </Button>
                <Input
                  value={thumbnail}
                  onChange={(e) => setThumbnail(e.target.value)}
                  placeholder="or paste URL"
                  className="h-8 text-xs"
                />
              </div>
              <input
                ref={fileInputRef}
                type="file"
                accept="image/jpeg,image/png,image/webp,image/gif"
                className="hidden"
                onChange={handleThumbnailUpload}
              />
            </div>
          </div>

          {/* Access type */}
          <div className="space-y-1.5">
            <Label>Access type</Label>
            <div className="grid grid-cols-2 gap-2">
              {ACCESS_TYPES.map((a) => (
                <button
                  key={a.value}
                  type="button"
                  onClick={() => setAccessType(a.value)}
                  className={`rounded-lg border p-3 text-left transition-colors ${
                    accessType === a.value
                      ? 'border-primary bg-primary/5'
                      : 'border-border hover:border-primary/50'
                  }`}
                >
                  <p className="text-sm font-medium text-foreground">{a.label}</p>
                  <p className="mt-0.5 text-xs text-muted-foreground">{a.description}</p>
                </button>
              ))}
            </div>
          </div>

          {/* Price (BUY_NOW) */}
          {accessType === 'BUY_NOW' && (
            <div className="space-y-1.5">
              <Label htmlFor="price">Price (USD)</Label>
              <Input
                id="price"
                type="number"
                min="0"
                step="0.01"
                value={price}
                onChange={(e) => setPrice(e.target.value)}
                placeholder="e.g. 29"
              />
            </div>
          )}

          {/* Unlock days (TIME_UNLOCK) */}
          {accessType === 'TIME_UNLOCK' && (
            <div className="space-y-1.5">
              <Label htmlFor="unlock">Unlock after (days)</Label>
              <Input
                id="unlock"
                type="number"
                min="1"
                value={unlockAfterDays}
                onChange={(e) => setUnlockAfterDays(e.target.value)}
                placeholder="e.g. 7"
              />
            </div>
          )}

          {/* Published toggle */}
          <label className="flex cursor-pointer items-center justify-between rounded-lg border border-border p-3">
            <div>
              <p className="text-sm font-medium text-foreground">Published</p>
              <p className="text-xs text-muted-foreground">Visible to members when enabled</p>
            </div>
            <div
              className={`relative h-5 w-9 rounded-full transition-colors ${
                isPublished ? 'bg-primary' : 'bg-muted'
              }`}
              onClick={() => setIsPublished((v) => !v)}
            >
              <div
                className={`absolute top-0.5 h-4 w-4 rounded-full bg-white shadow transition-transform ${
                  isPublished ? 'translate-x-4' : 'translate-x-0.5'
                }`}
              />
            </div>
          </label>

          {error && <p className="text-sm text-destructive">{error}</p>}

          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={isPending || uploading}>
              {isPending ? 'Saving...' : course ? 'Save changes' : 'Create course'}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
