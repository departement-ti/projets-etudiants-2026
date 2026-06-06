import { useEffect, useRef, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import {
  ChevronDown,
  FileText,
  Link2,
  Loader2,
  Paperclip,
  Pin,
  Trash2,
} from 'lucide-react'
import { toast } from 'sonner'
import { courseApi } from '@/api/course'
import { uploadFile } from '@/api/upload'
import { aiApi } from '@/api/ai'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { TiptapEditor } from '@/components/shared/TiptapEditor'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import type { LessonAttachment } from '@/types/course'
import { cn } from '@/lib/utils'

interface LessonPanelProps {
  communityId: string
  courseId: string
  sectionId: string
  lessonId: string | null
  onClose: () => void
  onSaved: () => void
}

export function LessonPanel({
  communityId,
  courseId,
  sectionId,
  lessonId,
  onClose,
  onSaved,
}: LessonPanelProps) {
  const queryClient = useQueryClient()
  const isNew = lessonId === null

  const { data: lessonData, isLoading } = useQuery({
    queryKey: ['lesson', communityId, courseId, sectionId, lessonId],
    queryFn: () => courseApi.getLesson(communityId, courseId, sectionId, lessonId!),
    enabled: !isNew,
  })
  const lesson = lessonData?.data?.lesson

  const [title, setTitle] = useState('')
  const [content, setContent] = useState('')
  const [videoUrl, setVideoUrl] = useState('')
  const [transcript, setTranscript] = useState('')
  const [isPublished, setIsPublished] = useState(true)
  const [attachments, setAttachments] = useState<LessonAttachment[]>([])
  const [error, setError] = useState('')
  const [editorKey, setEditorKey] = useState<string>(lessonId ?? 'new')
  const [transcribing, setTranscribing] = useState(false)

  // ADD dropdown panels
  const [showLinkField, setShowLinkField] = useState(false)
  const [showTranscriptField, setShowTranscriptField] = useState(false)
  const [linkName, setLinkName] = useState('')
  const [linkUrl, setLinkUrl] = useState('')

  const resourceFileInputRef = useRef<HTMLInputElement>(null)
  // Holds the resolved lessonId after an auto-save on a new lesson
  const resolvedLessonId = useRef<string | null>(lessonId)

  useEffect(() => {
    resolvedLessonId.current = lessonId
    if (isNew) {
      setTitle('')
      setContent('')
      setVideoUrl('')
      setTranscript('')
      setIsPublished(true)
      setError('')
      setAttachments([])
      setShowLinkField(false)
      setShowTranscriptField(false)
      setEditorKey('new')
    }
  }, [isNew, lessonId])

  useEffect(() => {
    if (lesson) {
      setTitle(lesson.title)
      setContent(lesson.content ?? '')
      setVideoUrl(lesson.videoUrl ?? '')
      setTranscript(lesson.transcript ?? '')
      setIsPublished(lesson.isPublished)
      setAttachments(lesson.attachments)
      setError('')
      if (lesson.transcript) setShowTranscriptField(true)
      // Update editorKey in the same effect so React batches it with setContent —
      // TiptapEditor's resetKey effect then runs with the correct content already in props
      setEditorKey(`${lessonId}-ready`)
    }
  }, [lesson])

  const { mutate: save, isPending: saving } = useMutation({
    mutationFn: () => {
      const data = {
        title: title.trim(),
        videoUrl: videoUrl.trim() || undefined,
        content: content || undefined,
        transcript: transcript.trim() || undefined,
        isPublished,
      }
      return isNew
        ? courseApi.createLesson(communityId, courseId, sectionId, data)
        : courseApi.updateLesson(communityId, courseId, sectionId, lessonId!, data)
    },
    onSuccess: () => {
      toast.success('Lesson saved')
      onSaved()
      if (isNew) onClose()
    },
    onError: (err) => toast.error((err as Error).message),
  })

  // Save first (if new) then run the callback — used by attachment actions
  async function saveIfNewThen(action: (savedLessonId: string) => void) {
    if (!title.trim()) {
      setError('Add a title before attaching resources')
      return
    }
    if (!isNew) {
      action(lessonId!)
      return
    }
    try {
      const res = await courseApi.createLesson(communityId, courseId, sectionId, {
        title: title.trim(),
        videoUrl: videoUrl.trim() || undefined,
        content: content || undefined,
        transcript: transcript.trim() || undefined,
        isPublished,
      })
      const newId = res.data?.lesson?.id
      if (!newId) throw new Error('No lesson ID returned')
      resolvedLessonId.current = newId
      onSaved()
      action(newId)
    } catch (err) {
      toast.error((err as Error).message)
    }
  }

  const { mutate: addLink, isPending: addingLink } = useMutation({
    mutationFn: () =>
      courseApi.addAttachment(communityId, courseId, sectionId, resolvedLessonId.current!, {
        name: linkName.trim(),
        url: linkUrl.trim(),
        type: 'LINK',
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ['lesson', communityId, courseId, sectionId, lessonId],
      })
      toast.success('Link added')
      setLinkName('')
      setLinkUrl('')
      setShowLinkField(false)
    },
    onError: (err) => toast.error((err as Error).message),
  })

  const { mutate: addFile, isPending: addingFile } = useMutation({
    mutationFn: async (file: File) => {
      const url = await uploadFile(file, 'attachments')
      return courseApi.addAttachment(communityId, courseId, sectionId, resolvedLessonId.current!, {
        name: file.name,
        url,
        type: 'FILE',
      })
    },
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ['lesson', communityId, courseId, sectionId, lessonId],
      })
      toast.success('File attached')
    },
    onError: (err) => toast.error((err as Error).message),
  })

  const { mutate: removeAttachment } = useMutation({
    mutationFn: (attachmentId: string) =>
      courseApi.deleteAttachment(communityId, courseId, sectionId, lessonId!, attachmentId),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ['lesson', communityId, courseId, sectionId, lessonId],
      })
      toast.success('Attachment removed')
    },
    onError: (err) => toast.error((err as Error).message),
  })

  function handleSave() {
    if (!title.trim()) {
      setError('Title is required')
      return
    }
    setError('')
    save()
  }

  function handleResourceFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    addFile(file)
    e.target.value = ''
  }

  if (!isNew && (isLoading || !lesson)) {
    return (
      <div className="flex h-full items-center justify-center">
        <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
      </div>
    )
  }

  return (
    <div className="flex h-full flex-col bg-card">
      {/* Title */}
      <div className="border-b border-border px-5 pt-4 pb-3">
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Lesson title..."
          autoFocus={isNew}
          className="w-full bg-transparent text-xl font-semibold text-foreground placeholder:text-muted-foreground/60 focus:outline-none"
        />
      </div>

      {/* Tiptap editor — video inserts at cursor position */}
      <TiptapEditor
        content={content}
        onChange={setContent}
        onVideoAdd={async (url, generateTranscript) => {
          setVideoUrl(url)
          if (!generateTranscript) return
          setShowTranscriptField(true)
          setTranscribing(true)
          try {
            const result = await aiApi.transcribeVideo(url)
            const { transcript: text, source } = result.data!
            if (text) {
              setTranscript(text)
              const label = source === 'youtube_captions' ? 'YouTube captions' : 'AI (Whisper)'
              toast.success(`Transcript generated via ${label}`)
            } else {
              toast.error('No transcript available for this video type (Loom/Vimeo not supported).')
              setShowTranscriptField(false)
            }
          } catch {
            toast.error('Transcript generation failed.')
            setShowTranscriptField(false)
          } finally {
            setTranscribing(false)
          }
        }}
        resetKey={editorKey}
        className="flex-1 overflow-hidden"
      />

      {/* Transcript field */}
      {showTranscriptField && (
        <div className="border-t border-border px-4 py-3">
          <div className="flex items-start gap-2">
            <FileText className="mt-2 h-4 w-4 shrink-0 text-muted-foreground" />
            {transcribing ? (
              <div className="flex flex-1 items-center gap-2 rounded-md border border-border bg-muted/30 px-3 py-2 text-sm text-muted-foreground">
                <Loader2 className="h-3.5 w-3.5 animate-spin" />
                Generating transcript…
              </div>
            ) : (
              <textarea
                value={transcript}
                onChange={(e) => setTranscript(e.target.value)}
                placeholder="Paste or type lesson transcript…"
                rows={4}
                className="flex-1 resize-y rounded-md border border-border bg-muted/30 px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
              />
            )}
            <button
              type="button"
              onClick={() => { setShowTranscriptField(false); setTranscript('') }}
              className="mt-1.5 text-xs text-muted-foreground hover:text-foreground"
            >
              Remove
            </button>
          </div>
        </div>
      )}

      {/* Attachments + link form */}
      {(showLinkField || attachments.length > 0) && (
        <div className="space-y-2 border-t border-border px-4 py-3">
          {/* Resource link form */}
          {showLinkField && (
            <div className="space-y-1.5 rounded-lg border border-border p-2.5">
              <Input
                value={linkName}
                onChange={(e) => setLinkName(e.target.value)}
                placeholder="Link name"
                className="h-7 text-sm"
              />
              <Input
                value={linkUrl}
                onChange={(e) => setLinkUrl(e.target.value)}
                placeholder="https://..."
                className="h-7 text-sm"
              />
              <div className="flex gap-1.5">
                <Button
                  type="button"
                  size="sm"
                  className="h-7 text-xs"
                  onClick={() => addLink()}
                  disabled={!linkName.trim() || !linkUrl.trim() || addingLink}
                >
                  Add
                </Button>
                <Button
                  type="button"
                  size="sm"
                  variant="outline"
                  className="h-7 text-xs"
                  onClick={() => {
                    setShowLinkField(false)
                    setLinkName('')
                    setLinkUrl('')
                  }}
                >
                  Cancel
                </Button>
              </div>
            </div>
          )}
          {/* Attachments list */}
          {attachments.map((a) => (
            <div
              key={a.id}
              className="flex items-center gap-2 rounded-md border border-border bg-muted/30 px-3 py-1.5"
            >
              {a.type === 'FILE' ? (
                <Paperclip className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
              ) : (
                <Link2 className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
              )}
              <a
                href={a.url}
                target="_blank"
                rel="noopener noreferrer"
                className="min-w-0 flex-1 truncate text-sm text-foreground hover:underline"
              >
                {a.name}
              </a>
              <button
                type="button"
                onClick={() => removeAttachment(a.id)}
                className="text-muted-foreground hover:text-destructive"
              >
                <Trash2 className="h-3.5 w-3.5" />
              </button>
            </div>
          ))}
        </div>
      )}

      {error && <p className="px-4 pb-1 text-xs text-destructive">{error}</p>}

      {/* Bottom action bar */}
      <div className="flex items-center justify-between border-t border-border px-4 py-3">
        {/* Left: ADD + Published */}
        <div className="flex items-center gap-2">
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="outline" size="sm" className="h-8 gap-1 text-xs">
                ADD
                <ChevronDown className="h-3 w-3" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="start" side="top" className="min-w-[180px]">
              <DropdownMenuItem
                onClick={() => saveIfNewThen(() => setShowLinkField(true))}
              >
                <Link2 className="mr-2 h-3.5 w-3.5" />
                Add resource link
              </DropdownMenuItem>
              <DropdownMenuItem
                disabled={addingFile}
                onClick={() => saveIfNewThen(() => resourceFileInputRef.current?.click())}
              >
                <Paperclip className="mr-2 h-3.5 w-3.5" />
                {addingFile ? 'Uploading…' : 'Add resource file'}
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => setShowTranscriptField(true)}>
                <FileText className="mr-2 h-3.5 w-3.5" />
                Add transcript
              </DropdownMenuItem>
              <DropdownMenuItem disabled>
                <Pin className="mr-2 h-3.5 w-3.5" />
                Pin community post
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>

          {/* Published toggle */}
          <button
            type="button"
            onClick={() => setIsPublished((v) => !v)}
            className={cn(
              'flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-medium transition-colors',
              isPublished
                ? 'bg-emerald-600/15 text-emerald-600 hover:bg-emerald-600/25'
                : 'bg-muted text-muted-foreground hover:bg-muted/80',
            )}
          >
            <div
              className={cn(
                'h-1.5 w-1.5 rounded-full',
                isPublished ? 'bg-emerald-500' : 'bg-muted-foreground/50',
              )}
            />
            Published
          </button>
        </div>

        {/* Right: Cancel + Save */}
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" className="h-8 text-xs" onClick={onClose}>
            Cancel
          </Button>
          <Button size="sm" className="h-8 text-xs" onClick={handleSave} disabled={saving}>
            {saving ? 'Saving…' : 'Save'}
          </Button>
        </div>
      </div>

      {/* Hidden file input for resource file uploads */}
      <input
        ref={resourceFileInputRef}
        type="file"
        className="hidden"
        onChange={handleResourceFileChange}
      />
    </div>
  )
}
