import { useEffect, useState } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { courseApi } from '@/api/course'
import type { CourseSection } from '@/types/course'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

interface SectionModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  communityId: string
  courseId: string
  section?: CourseSection
}

export function SectionModal({
  open,
  onOpenChange,
  communityId,
  courseId,
  section,
}: SectionModalProps) {
  const queryClient = useQueryClient()
  const [title, setTitle] = useState('')
  const [error, setError] = useState('')

  useEffect(() => {
    if (open) {
      setTitle(section?.title ?? '')
      setError('')
    }
  }, [open, section])

  const { mutate, isPending } = useMutation({
    mutationFn: () =>
      section
        ? courseApi.updateSection(communityId, courseId, section.id, { title: title.trim() })
        : courseApi.createSection(communityId, courseId, { title: title.trim() }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['course', communityId, courseId] })
      toast.success(section ? 'Section renamed' : 'Section added')
      onOpenChange(false)
    },
    onError: (err) => toast.error((err as Error).message),
  })

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!title.trim()) { setError('Title is required'); return }
    setError('')
    mutate()
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-sm">
        <DialogHeader>
          <DialogTitle>{section ? 'Rename section' : 'Add section'}</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1.5">
            <Label htmlFor="section-title">Section title</Label>
            <Input
              id="section-title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g. Foundations"
              autoFocus
            />
          </div>
          {error && <p className="text-sm text-destructive">{error}</p>}
          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={isPending}>
              {isPending ? 'Saving...' : section ? 'Save' : 'Add section'}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}
