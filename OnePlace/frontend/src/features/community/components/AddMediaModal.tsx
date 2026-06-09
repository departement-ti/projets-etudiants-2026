import { useRef, useState } from 'react'
import { Link, Loader2, Upload, X, Film } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { uploadFile } from '@/api/upload'
import { toast } from 'sonner'

interface AddMediaModalProps {
  open: boolean
  onClose: () => void
  onAdd: (url: string, type: 'IMAGE' | 'VIDEO', thumbnailUrl?: string) => Promise<void>
}

function getYouTubeThumbnail(url: string): string | null {
  const match = url.match(
    /(?:youtube\.com\/(?:watch\?v=|embed\/)|youtu\.be\/)([A-Za-z0-9_-]{11})/
  )
  return match ? `https://img.youtube.com/vi/${match[1]}/hqdefault.jpg` : null
}

function formatBytes(bytes: number) {
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`
}

// Extract a frame from a video file as a JPEG File using Canvas.
function generateVideoThumbnail(file: File): Promise<File> {
  return new Promise((resolve, reject) => {
    const video = document.createElement('video')
    video.preload = 'metadata'
    video.muted = true
    video.playsInline = true

    const objectUrl = URL.createObjectURL(file)
    video.src = objectUrl

    const cleanup = () => URL.revokeObjectURL(objectUrl)

    video.onerror = () => { cleanup(); reject(new Error('Could not load video')) }

    video.onloadeddata = () => {
      // Seek to 1 s or 10% of the duration, whichever is smaller
      video.currentTime = Math.min(1, video.duration * 0.1)
    }

    video.onseeked = () => {
      const canvas = document.createElement('canvas')
      // Cap thumbnail at 1280 px wide for reasonable file size
      const scale = Math.min(1, 1280 / (video.videoWidth || 1280))
      canvas.width = Math.round(video.videoWidth * scale)
      canvas.height = Math.round(video.videoHeight * scale)

      const ctx = canvas.getContext('2d')
      if (!ctx) { cleanup(); reject(new Error('Canvas not supported')); return }
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height)

      cleanup()
      canvas.toBlob(
        (blob) => {
          if (!blob) { reject(new Error('Failed to generate thumbnail')); return }
          resolve(new File([blob], 'thumbnail.jpg', { type: 'image/jpeg' }))
        },
        'image/jpeg',
        0.82,
      )
    }
  })
}

export function AddMediaModal({ open, onClose, onAdd }: AddMediaModalProps) {
  const [videoUrl, setVideoUrl] = useState('')
  const [imagePreview, setImagePreview] = useState<string | null>(null)
  const [imageFile, setImageFile] = useState<File | null>(null)
  const [videoFile, setVideoFile] = useState<File | null>(null)
  const [videoThumbPreview, setVideoThumbPreview] = useState<string | null>(null)
  const [videoThumbFile, setVideoThumbFile] = useState<File | null>(null)
  const [generatingThumb, setGeneratingThumb] = useState(false)
  const [uploadProgress, setUploadProgress] = useState<number | null>(null)
  const [uploading, setUploading] = useState(false)
  const [dragOver, setDragOver] = useState(false)

  const imageInputRef = useRef<HTMLInputElement>(null)
  const videoInputRef = useRef<HTMLInputElement>(null)

  if (!open) return null

  function handleImageSelect(file: File) {
    if (!file.type.startsWith('image/')) return
    setImageFile(file)
    setVideoFile(null)
    setVideoThumbFile(null)
    setVideoThumbPreview(null)
    setVideoUrl('')
    setImagePreview(URL.createObjectURL(file))
  }

  async function handleVideoSelect(file: File) {
    if (!file.type.startsWith('video/')) return
    setVideoFile(file)
    setImageFile(null)
    setImagePreview(null)
    setVideoUrl('')
    setVideoThumbFile(null)
    setVideoThumbPreview(null)

    // Auto-generate thumbnail
    setGeneratingThumb(true)
    try {
      const thumb = await generateVideoThumbnail(file)
      setVideoThumbFile(thumb)
      setVideoThumbPreview(URL.createObjectURL(thumb))
    } catch {
      // thumbnail generation is best-effort — don't block the user
    } finally {
      setGeneratingThumb(false)
    }
  }

  function handleDrop(e: React.DragEvent) {
    e.preventDefault()
    setDragOver(false)
    const file = e.dataTransfer.files[0]
    if (file?.type.startsWith('video/')) handleVideoSelect(file)
  }

  function handleClose() {
    if (uploading) return
    setVideoUrl('')
    setImagePreview(null)
    setImageFile(null)
    setVideoFile(null)
    setVideoThumbFile(null)
    setVideoThumbPreview(null)
    setUploadProgress(null)
    onClose()
  }

  async function handleAdd() {
    if (uploading) return

    // ── Image file ──
    if (imageFile) {
      setUploading(true)
      setUploadProgress(0)
      try {
        const url = await uploadFile(imageFile, 'communities', (p) => setUploadProgress(p))
        await onAdd(url, 'IMAGE')
        handleClose()
      } catch (err) {
        toast.error((err as Error).message)
      } finally {
        setUploading(false)
        setUploadProgress(null)
      }
      return
    }

    // ── Video file ──
    if (videoFile) {
      setUploading(true)
      setUploadProgress(0)
      try {
        // Upload thumbnail first (small, fast — no progress needed)
        let thumbnailUrl: string | undefined
        if (videoThumbFile) {
          thumbnailUrl = await uploadFile(videoThumbFile, 'communities')
        }
        // Upload the video with progress
        const url = await uploadFile(videoFile, 'communities', (p) => setUploadProgress(p))
        await onAdd(url, 'VIDEO', thumbnailUrl)
        toast.success('Video uploaded')
        handleClose()
      } catch (err) {
        toast.error((err as Error).message)
      } finally {
        setUploading(false)
        setUploadProgress(null)
      }
      return
    }

    // ── Video URL ──
    if (videoUrl.trim()) {
      setUploading(true)
      try {
        await onAdd(videoUrl.trim(), 'VIDEO')
        handleClose()
      } catch (err) {
        toast.error((err as Error).message)
      } finally {
        setUploading(false)
      }
    }
  }

  const canAdd = !uploading && !generatingThumb && (!!imageFile || !!videoFile || !!videoUrl.trim())
  const ytThumb = videoUrl.trim() ? getYouTubeThumbnail(videoUrl) : null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/60" onClick={handleClose} />

      <div className="relative z-10 w-full max-w-md rounded-2xl border border-border bg-card shadow-2xl">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <h2 className="text-base font-semibold text-foreground">Add media</h2>
          <button
            onClick={handleClose}
            disabled={uploading}
            className="rounded-lg p-1 text-muted-foreground hover:bg-muted hover:text-foreground"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="space-y-5 p-6">
          {/* ── Image upload ── */}
          <div>
            <p className="mb-2 text-sm text-muted-foreground">
              Upload an image{' '}
              <span className="text-muted-foreground/60">(1400 × 790 recommended).</span>
            </p>

            {imagePreview ? (
              <div className="relative overflow-hidden rounded-xl border border-border">
                <img src={imagePreview} alt="" className="h-40 w-full object-cover" />
                {!uploading && (
                  <button
                    onClick={() => { setImageFile(null); setImagePreview(null) }}
                    className="absolute right-2 top-2 rounded-full bg-black/60 p-1 text-white hover:bg-black/80"
                  >
                    <X className="h-3.5 w-3.5" />
                  </button>
                )}
              </div>
            ) : (
              <button
                onClick={() => imageInputRef.current?.click()}
                disabled={uploading}
                className="flex w-full items-center justify-center gap-2 rounded-xl border border-border bg-muted/40 px-4 py-2.5 text-sm font-medium uppercase tracking-wide text-muted-foreground transition-colors hover:bg-muted hover:text-foreground disabled:opacity-50"
              >
                <Upload className="h-4 w-4" />
                Upload image
              </button>
            )}
            <input
              ref={imageInputRef}
              type="file"
              accept="image/jpeg,image/png,image/webp,image/gif"
              className="hidden"
              onChange={(e) => {
                const file = e.target.files?.[0]
                if (file) handleImageSelect(file)
                e.target.value = ''
              }}
            />
          </div>

          {/* ── Video section ── */}
          {!imageFile && (
            <div>
              <p className="mb-2 text-sm text-muted-foreground">Or, add a video.</p>

              {/* URL input */}
              {!videoFile && (
                <div className="mb-3 flex items-center gap-2 rounded-xl border border-border bg-muted/40 px-3 py-2.5 focus-within:border-primary/60">
                  <Link className="h-4 w-4 shrink-0 text-muted-foreground" />
                  <input
                    type="url"
                    placeholder="YouTube, Loom, Vimeo, or Wistia link"
                    value={videoUrl}
                    onChange={(e) => setVideoUrl(e.target.value)}
                    disabled={uploading}
                    className="flex-1 bg-transparent text-sm text-foreground placeholder:text-muted-foreground focus:outline-none disabled:opacity-50"
                  />
                </div>
              )}

              {/* YouTube thumbnail preview */}
              {ytThumb && !videoFile && (
                <div className="mb-3 overflow-hidden rounded-xl border border-border">
                  <img src={ytThumb} alt="Video preview" className="h-36 w-full object-cover" />
                </div>
              )}

              {/* Video file selected */}
              {videoFile ? (
                <div className="space-y-3 rounded-xl border border-border bg-muted/40 p-4">
                  {/* Thumbnail preview */}
                  {generatingThumb ? (
                    <div className="flex h-32 items-center justify-center gap-2 rounded-lg bg-muted text-sm text-muted-foreground">
                      <Loader2 className="h-4 w-4 animate-spin" />
                      Generating thumbnail…
                    </div>
                  ) : videoThumbPreview ? (
                    <div className="relative overflow-hidden rounded-lg">
                      <img src={videoThumbPreview} alt="Thumbnail" className="h-32 w-full object-cover" />
                      <div className="absolute inset-0 flex items-center justify-center bg-black/20">
                        <div className="rounded-full bg-black/60 p-2">
                          <svg className="h-5 w-5 fill-white" viewBox="0 0 24 24">
                            <path d="M8 5v14l11-7z" />
                          </svg>
                        </div>
                      </div>
                    </div>
                  ) : null}

                  {/* File info row */}
                  <div className="flex items-center gap-3">
                    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-muted">
                      <Film className="h-4 w-4 text-muted-foreground" />
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-medium text-foreground">{videoFile.name}</p>
                      <p className="text-xs text-muted-foreground">{formatBytes(videoFile.size)}</p>
                    </div>
                    {!uploading && (
                      <button
                        onClick={() => {
                          setVideoFile(null)
                          setVideoThumbFile(null)
                          setVideoThumbPreview(null)
                        }}
                        className="rounded-lg p-1 text-muted-foreground hover:bg-muted hover:text-foreground"
                      >
                        <X className="h-4 w-4" />
                      </button>
                    )}
                  </div>

                  {/* Upload progress */}
                  {uploadProgress !== null && (
                    <div>
                      <div className="mb-1 flex items-center justify-between text-xs text-muted-foreground">
                        <span>Uploading…</span>
                        <span>{uploadProgress}%</span>
                      </div>
                      <div className="h-1.5 w-full overflow-hidden rounded-full bg-muted">
                        <div
                          className="h-full rounded-full bg-primary transition-all duration-150"
                          style={{ width: `${uploadProgress}%` }}
                        />
                      </div>
                    </div>
                  )}
                </div>
              ) : (
                !videoUrl.trim() && (
                  <div
                    onDragOver={(e) => { e.preventDefault(); setDragOver(true) }}
                    onDragLeave={() => setDragOver(false)}
                    onDrop={handleDrop}
                    onClick={() => videoInputRef.current?.click()}
                    className={`flex cursor-pointer flex-col items-center justify-center gap-1.5 rounded-xl border-2 border-dashed py-7 transition-colors ${
                      dragOver
                        ? 'border-primary bg-primary/5'
                        : 'border-border bg-muted/20 hover:border-primary/50 hover:bg-muted/40'
                    }`}
                  >
                    <Upload className="h-6 w-6 text-muted-foreground" />
                    <p className="text-sm text-muted-foreground">Drag and drop video here</p>
                    <p className="text-xs text-primary underline">or select file</p>
                  </div>
                )
              )}

              <input
                ref={videoInputRef}
                type="file"
                accept="video/*"
                className="hidden"
                onChange={(e) => {
                  const file = e.target.files?.[0]
                  if (file) handleVideoSelect(file)
                  e.target.value = ''
                }}
              />
            </div>
          )}

          {/* Image upload progress */}
          {imageFile && uploadProgress !== null && (
            <div>
              <div className="mb-1 flex items-center justify-between text-xs text-muted-foreground">
                <span>Uploading…</span>
                <span>{uploadProgress}%</span>
              </div>
              <div className="h-1.5 w-full overflow-hidden rounded-full bg-muted">
                <div
                  className="h-full rounded-full bg-primary transition-all duration-150"
                  style={{ width: `${uploadProgress}%` }}
                />
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex justify-end gap-3 border-t border-border px-6 py-4">
          <Button variant="ghost" onClick={handleClose} disabled={uploading}>
            Cancel
          </Button>
          <Button onClick={handleAdd} disabled={!canAdd}>
            {uploading ? <Loader2 className="h-4 w-4 animate-spin" /> : 'Add'}
          </Button>
        </div>
      </div>
    </div>
  )
}
