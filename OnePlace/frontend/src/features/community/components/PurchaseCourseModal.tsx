import { useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { courseApi } from '@/api/course'
import type { Course } from '@/types/course'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'

interface PurchaseCourseModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  course: Course
  communityId: string
}

export function PurchaseCourseModal({
  open,
  onOpenChange,
  course,
  communityId,
}: PurchaseCourseModalProps) {
  const queryClient = useQueryClient()

  const { mutate: purchase, isPending } = useMutation({
    mutationFn: () => courseApi.purchase(communityId, course.id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['course', course.id] })
      queryClient.invalidateQueries({ queryKey: ['courses', communityId] })
      toast.success('Course unlocked!')
      onOpenChange(false)
    },
    onError: (err) => toast.error((err as Error).message),
  })

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Buy this course</DialogTitle>
          <DialogDescription>{course.title}</DialogDescription>
        </DialogHeader>

        <div className="mb-4 rounded-lg border border-border bg-muted/50 p-4">
          <p className="text-sm text-muted-foreground">One-time price</p>
          <p className="mt-1 text-3xl font-bold text-foreground">${course.price}</p>
          <p className="mt-1 text-xs text-muted-foreground">Lifetime access. No recurring charges.</p>
        </div>

        <Button onClick={() => purchase()} disabled={isPending} className="w-full">
          {isPending ? 'Processing...' : `Buy for $${course.price}`}
        </Button>
      </DialogContent>
    </Dialog>
  )
}
