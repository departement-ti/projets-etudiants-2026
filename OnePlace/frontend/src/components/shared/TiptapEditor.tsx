import { useEffect, useRef, useState } from 'react'
import { useEditor, EditorContent } from '@tiptap/react'
import { Node } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import Link from '@tiptap/extension-link'
import Image from '@tiptap/extension-image'
import {
  Bold,
  Image as ImageIcon,
  Italic,
  Link2,
  List,
  ListOrdered,
  Loader2,
  Minus,
  Quote,
  Strikethrough,
  Upload,
  Video,
  X,
} from 'lucide-react'
import { toast } from 'sonner'
import { cn } from '@/lib/utils'
import { uploadFile } from '@/api/upload'

// ─── Video URL → embed URL ────────────────────────────────────────────────────

function toEmbedUrl(url: string): string {
  const yt = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([^&\s?]+)/)
  if (yt) return `https://www.youtube.com/embed/${yt[1]}`
  const vimeo = url.match(/vimeo\.com\/(\d+)/)
  if (vimeo) return `https://player.vimeo.com/video/${vimeo[1]}`
  const loom = url.match(/loom\.com\/share\/([a-zA-Z0-9]+)/)
  if (loom) return `https://www.loom.com/embed/${loom[1]}`
  return url
}

// X icon as inline SVG (used inside manually-created DOM nodes)
const X_SVG = `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>`

// ─── VideoEmbed node extension ────────────────────────────────────────────────

const VideoEmbed = Node.create({
  name: 'videoEmbed',
  group: 'block',
  atom: true,
  draggable: true,

  addAttributes() {
    return { src: { default: null } }
  },

  parseHTML() {
    return [
      {
        tag: 'div[data-video-embed]',
        getAttrs: (el) => ({ src: (el as HTMLElement).getAttribute('data-src') }),
      },
    ]
  },

  renderHTML({ node }) {
    return ['div', { 'data-video-embed': '', 'data-src': node.attrs.src }]
  },

  addNodeView() {
    return ({ node, getPos, editor }) => {
      // Outer wrapper — position:relative so the overlay/button sit on top
      const dom = document.createElement('div')
      dom.setAttribute('data-video-embed', '')
      dom.setAttribute('data-src', node.attrs.src as string)
      dom.className = 'video-embed-node'

      // 16:9 ratio box
      const ratio = document.createElement('div')
      ratio.className = 'video-embed-ratio'

      const iframe = document.createElement('iframe')
      iframe.src = toEmbedUrl(node.attrs.src as string)
      iframe.allowFullscreen = true
      iframe.setAttribute('frameborder', '0')
      iframe.setAttribute(
        'allow',
        'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share',
      )
      ratio.appendChild(iframe)

      // Transparent overlay — sits above the iframe so the parent receives
      // mouseenter/mouseleave events (iframes swallow pointer events otherwise)
      const overlay = document.createElement('div')
      overlay.className = 'video-embed-overlay'

      // Delete button
      const deleteBtn = document.createElement('button')
      deleteBtn.type = 'button'
      deleteBtn.title = 'Remove video'
      deleteBtn.className = 'video-embed-delete'
      deleteBtn.innerHTML = X_SVG
      deleteBtn.addEventListener('mousedown', (e) => {
        e.preventDefault()
        e.stopPropagation()
      })
      deleteBtn.addEventListener('click', (e) => {
        e.preventDefault()
        e.stopPropagation()
        if (typeof getPos === 'function') {
          const pos = getPos()
          if (pos !== undefined) {
            editor.chain().focus().deleteRange({ from: pos, to: pos + node.nodeSize }).run()
          }
        }
      })

      // Show / hide the delete button on hover via JS because the iframe
      // swallows pointer events — CSS :hover on the parent won't fire
      const show = () => { deleteBtn.style.opacity = '1' }
      const hide = () => { deleteBtn.style.opacity = '0' }
      overlay.addEventListener('mouseenter', show)
      overlay.addEventListener('mouseleave', hide)
      deleteBtn.addEventListener('mouseenter', show)
      deleteBtn.addEventListener('mouseleave', hide)

      dom.appendChild(ratio)
      dom.appendChild(overlay)
      dom.appendChild(deleteBtn)

      return { dom }
    }
  },
})

// ─── Helpers ──────────────────────────────────────────────────────────────────

function docHasVideo(doc: ReturnType<typeof useEditor>['state']['doc'] | undefined): boolean {
  if (!doc) return false
  let found = false
  doc.descendants((node) => {
    if (node.type.name === 'videoEmbed') {
      found = true
      return false
    }
  })
  return found
}

// ─── Toolbar button ───────────────────────────────────────────────────────────

function ToolbarBtn({
  onClick,
  isActive,
  title,
  disabled,
  children,
}: {
  onClick: () => void
  isActive?: boolean
  title: string
  disabled?: boolean
  children: React.ReactNode
}) {
  return (
    <button
      type="button"
      onMouseDown={(e) => {
        e.preventDefault()
        if (!disabled) onClick()
      }}
      title={title}
      disabled={disabled}
      className={cn(
        'flex h-7 min-w-[1.75rem] items-center justify-center rounded px-1.5 text-xs font-medium transition-colors',
        disabled
          ? 'cursor-not-allowed opacity-35'
          : isActive
            ? 'bg-foreground text-background'
            : 'text-muted-foreground hover:bg-muted hover:text-foreground',
      )}
    >
      {children}
    </button>
  )
}

function Divider() {
  return <div className="mx-1 h-4 w-px shrink-0 bg-border" />
}

// ─── Progress circle ──────────────────────────────────────────────────────────

function ProgressCircle({ percent }: { percent: number }) {
  const r = 22
  const circumference = 2 * Math.PI * r
  const offset = circumference - (percent / 100) * circumference
  return (
    <div className="relative flex items-center justify-center">
      <svg width="60" height="60" viewBox="0 0 60 60" className="-rotate-90">
        <circle cx="30" cy="30" r={r} fill="none" stroke="hsl(var(--border))" strokeWidth="4" />
        <circle
          cx="30" cy="30" r={r} fill="none"
          stroke="hsl(var(--primary))" strokeWidth="4"
          strokeDasharray={circumference}
          strokeDashoffset={offset}
          strokeLinecap="round"
          className="transition-[stroke-dashoffset] duration-150"
        />
      </svg>
      <span className="absolute text-xs font-semibold text-foreground">{percent}%</span>
    </div>
  )
}

// ─── Video modal ──────────────────────────────────────────────────────────────

function VideoModal({
  onConfirm,
  onClose,
}: {
  onConfirm: (url: string, generateTranscript: boolean) => void
  onClose: () => void
}) {
  const [url, setUrl] = useState('')
  const [uploading, setUploading] = useState(false)
  const [progress, setProgress] = useState(0)
  const [dragging, setDragging] = useState(false)
  const [generateTranscript, setGenerateTranscript] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  function handleConfirm() {
    const trimmed = url.trim()
    if (!trimmed) return
    onConfirm(trimmed, generateTranscript)
    onClose()
  }

  async function handleFile(file: File) {
    if (!file.type.startsWith('video/')) {
      toast.error('Please select a video file.')
      return
    }
    setUploading(true)
    setProgress(0)
    try {
      const fileUrl = await uploadFile(file, 'lessons', setProgress)
      onConfirm(fileUrl, generateTranscript)
      onClose()
    } catch (err) {
      toast.error((err as Error).message || 'Video upload failed.')
    } finally {
      setUploading(false)
      setProgress(0)
    }
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
      onClick={(e) => { if (e.target === e.currentTarget && !uploading) onClose() }}
    >
      <div className="w-full max-w-md rounded-2xl border border-border bg-card p-6 shadow-2xl">
        <div className="mb-5 flex items-center justify-between">
          <h2 className="text-xl font-bold text-foreground">Add a video</h2>
          <button
            onClick={() => { if (!uploading) onClose() }}
            disabled={uploading}
            className="rounded-lg p-1.5 text-muted-foreground hover:bg-muted hover:text-foreground disabled:opacity-40"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className={cn(
          'flex items-center gap-2.5 rounded-lg border border-border px-3 py-2.5 focus-within:ring-2 focus-within:ring-ring',
          uploading && 'pointer-events-none opacity-50',
        )}>
          <Link2 className="h-4 w-4 shrink-0 text-muted-foreground" />
          <input
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            onKeyDown={(e) => { if (e.key === 'Enter') handleConfirm() }}
            placeholder="YouTube, Loom, Vimeo, or direct link"
            autoFocus
            disabled={uploading}
            className="flex-1 bg-transparent text-sm text-foreground placeholder:text-muted-foreground focus:outline-none"
          />
        </div>

        <div
          onDragOver={(e) => { e.preventDefault(); if (!uploading) setDragging(true) }}
          onDragLeave={() => setDragging(false)}
          onDrop={(e) => {
            e.preventDefault()
            setDragging(false)
            const file = e.dataTransfer.files[0]
            if (file && !uploading) handleFile(file)
          }}
          onClick={() => { if (!uploading) fileInputRef.current?.click() }}
          className={cn(
            'mt-3 flex cursor-pointer flex-col items-center justify-center gap-2 rounded-xl border-2 border-dashed py-10 transition-colors',
            uploading
              ? 'cursor-default border-border'
              : dragging
                ? 'border-primary bg-primary/5'
                : 'border-border hover:border-muted-foreground/40 hover:bg-muted/30',
          )}
        >
          {uploading ? (
            <>
              <ProgressCircle percent={progress} />
              <p className="text-sm text-muted-foreground">Uploading video…</p>
            </>
          ) : (
            <>
              <Upload className="h-6 w-6 text-muted-foreground" />
              <p className="text-sm text-muted-foreground">Drag and drop video here</p>
              <span className="text-sm text-muted-foreground underline underline-offset-2">or select file</span>
            </>
          )}
          <input
            ref={fileInputRef}
            type="file"
            accept="video/*"
            className="hidden"
            onChange={(e) => {
              const file = e.target.files?.[0]
              if (file) handleFile(file)
              e.target.value = ''
            }}
          />
        </div>

        <label className={cn(
          'mt-4 flex cursor-pointer items-center gap-2.5',
          uploading && 'pointer-events-none opacity-50',
        )}>
          <input
            type="checkbox"
            checked={generateTranscript}
            onChange={(e) => setGenerateTranscript(e.target.checked)}
            disabled={uploading}
            className="h-4 w-4 rounded border-border accent-primary"
          />
          <span className="text-sm text-foreground">Generate transcript</span>
          <span className="text-xs text-muted-foreground">YouTube captions or AI</span>
        </label>

        <div className="mt-5 flex items-center justify-end gap-3">
          <button
            onClick={() => { if (!uploading) onClose() }}
            disabled={uploading}
            className="px-4 py-2 text-sm font-semibold uppercase tracking-wide text-muted-foreground transition-colors hover:text-foreground disabled:opacity-40"
          >
            Cancel
          </button>
          <button
            onClick={handleConfirm}
            disabled={!url.trim() || uploading}
            className={cn(
              'rounded-lg px-5 py-2 text-sm font-semibold uppercase tracking-wide transition-colors',
              url.trim() && !uploading
                ? 'bg-muted text-foreground hover:bg-muted/70'
                : 'cursor-not-allowed bg-muted/40 text-muted-foreground',
            )}
          >
            Add
          </button>
        </div>
      </div>
    </div>
  )
}

// ─── TiptapEditor ─────────────────────────────────────────────────────────────

interface TiptapEditorProps {
  content: string
  onChange: (html: string) => void
  onVideoAdd?: (url: string, generateTranscript: boolean) => void
  resetKey?: string | number
  className?: string
}

export function TiptapEditor({
  content,
  onChange,
  onVideoAdd,
  resetKey,
  className,
}: TiptapEditorProps) {
  const [videoModalOpen, setVideoModalOpen] = useState(false)
  const [uploadingImage, setUploadingImage] = useState(false)
  const [hasVideo, setHasVideo] = useState(false)
  const imageInputRef = useRef<HTMLInputElement>(null)

  const editor = useEditor({
    extensions: [
      StarterKit,
      Link.configure({ openOnClick: false }),
      Image.configure({ inline: false, allowBase64: false }),
      VideoEmbed,
    ],
    content,
    onUpdate: ({ editor }) => {
      onChange(editor.getHTML())
      setHasVideo(docHasVideo(editor.state.doc))
    },
    onCreate: ({ editor }) => {
      setHasVideo(docHasVideo(editor.state.doc))
    },
  })

  useEffect(() => {
    if (!editor) return
    editor.commands.setContent(content || '')
    setHasVideo(docHasVideo(editor.state.doc))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [resetKey])

  if (!editor) return null

  function handleAddLink() {
    const url = window.prompt('Enter URL')
    if (!url) return
    editor!.chain().focus().setLink({ href: url }).run()
  }

  function handleVideoConfirm(url: string, generateTranscript: boolean) {
    editor!.chain().focus().insertContent({ type: 'videoEmbed', attrs: { src: url } }).run()
    setHasVideo(true)
    onVideoAdd?.(url, generateTranscript)
  }

  async function handleImageFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file || !editor) return
    setUploadingImage(true)
    try {
      const url = await uploadFile(file, 'lessons')
      editor.chain().focus().setImage({ src: url }).run()
    } catch (err) {
      toast.error((err as Error).message || 'Image upload failed')
    } finally {
      setUploadingImage(false)
      e.target.value = ''
    }
  }

  return (
    <>
      <div className={cn('flex flex-col overflow-hidden rounded-b-lg shadow-[0_4px_24px_0_rgba(0,0,0,0.18)]', className)}>
        {/* Toolbar */}
        <div className="flex flex-wrap items-center gap-0.5 border-b border-border bg-background/50 px-2 py-1.5">
          <ToolbarBtn
            onClick={() => editor.chain().focus().toggleHeading({ level: 1 }).run()}
            isActive={editor.isActive('heading', { level: 1 })}
            title="Heading 1"
          >
            H1
          </ToolbarBtn>
          <ToolbarBtn
            onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()}
            isActive={editor.isActive('heading', { level: 2 })}
            title="Heading 2"
          >
            H2
          </ToolbarBtn>
          <ToolbarBtn
            onClick={() => editor.chain().focus().toggleHeading({ level: 3 }).run()}
            isActive={editor.isActive('heading', { level: 3 })}
            title="Heading 3"
          >
            H3
          </ToolbarBtn>
          <ToolbarBtn
            onClick={() => editor.chain().focus().toggleHeading({ level: 4 }).run()}
            isActive={editor.isActive('heading', { level: 4 })}
            title="Heading 4"
          >
            H4
          </ToolbarBtn>
          <Divider />
          <ToolbarBtn
            onClick={() => editor.chain().focus().toggleBold().run()}
            isActive={editor.isActive('bold')}
            title="Bold"
          >
            <Bold className="h-3.5 w-3.5" />
          </ToolbarBtn>
          <ToolbarBtn
            onClick={() => editor.chain().focus().toggleItalic().run()}
            isActive={editor.isActive('italic')}
            title="Italic"
          >
            <Italic className="h-3.5 w-3.5" />
          </ToolbarBtn>
          <ToolbarBtn
            onClick={() => editor.chain().focus().toggleStrike().run()}
            isActive={editor.isActive('strike')}
            title="Strikethrough"
          >
            <Strikethrough className="h-3.5 w-3.5" />
          </ToolbarBtn>
          <Divider />
          <ToolbarBtn
            onClick={() => editor.chain().focus().toggleBulletList().run()}
            isActive={editor.isActive('bulletList')}
            title="Bullet list"
          >
            <List className="h-3.5 w-3.5" />
          </ToolbarBtn>
          <ToolbarBtn
            onClick={() => editor.chain().focus().toggleOrderedList().run()}
            isActive={editor.isActive('orderedList')}
            title="Ordered list"
          >
            <ListOrdered className="h-3.5 w-3.5" />
          </ToolbarBtn>
          <ToolbarBtn
            onClick={() => editor.chain().focus().toggleBlockquote().run()}
            isActive={editor.isActive('blockquote')}
            title="Blockquote"
          >
            <Quote className="h-3.5 w-3.5" />
          </ToolbarBtn>
          <Divider />
          <ToolbarBtn
            onClick={handleAddLink}
            isActive={editor.isActive('link')}
            title="Add link"
          >
            <Link2 className="h-3.5 w-3.5" />
          </ToolbarBtn>
          <ToolbarBtn
            onClick={() => editor.chain().focus().setHorizontalRule().run()}
            isActive={false}
            title="Horizontal rule"
          >
            <Minus className="h-3.5 w-3.5" />
          </ToolbarBtn>
          <Divider />

          {/* Image upload — uses onClick (not onMouseDown) so the browser
              treats imageInputRef.current.click() as a trusted user gesture */}
          <button
            type="button"
            onMouseDown={(e) => e.preventDefault()}
            onClick={() => imageInputRef.current?.click()}
            title="Upload image"
            disabled={uploadingImage}
            className={cn(
              'flex h-7 min-w-[1.75rem] items-center justify-center rounded px-1.5 text-xs font-medium transition-colors',
              uploadingImage
                ? 'cursor-not-allowed opacity-35'
                : 'text-muted-foreground hover:bg-muted hover:text-foreground',
            )}
          >
            {uploadingImage ? (
              <Loader2 className="h-3.5 w-3.5 animate-spin" />
            ) : (
              <ImageIcon className="h-3.5 w-3.5" />
            )}
          </button>

          {/* Video — disabled once a video already exists in the lesson */}
          <ToolbarBtn
            onClick={() => setVideoModalOpen(true)}
            isActive={false}
            title={hasVideo ? 'Remove the existing video first' : 'Add video'}
            disabled={hasVideo}
          >
            <Video className="h-3.5 w-3.5" />
          </ToolbarBtn>

          <input
            ref={imageInputRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={handleImageFileChange}
          />
        </div>

        {/* Editor area */}
        <EditorContent editor={editor} className="tiptap-body flex-1 overflow-y-auto" />
      </div>

      {videoModalOpen && (
        <VideoModal
          onConfirm={handleVideoConfirm}
          onClose={() => setVideoModalOpen(false)}
        />
      )}
    </>
  )
}
