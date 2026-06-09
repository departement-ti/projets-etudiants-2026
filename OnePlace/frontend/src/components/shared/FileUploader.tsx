import { useCallback, useRef, useState } from 'react'
import { ImageIcon, Loader2, Upload, Video, X } from 'lucide-react'
import { cn } from '@/lib/utils'
import { uploadApi, type UploadFolder } from '@/api/upload'

interface FileUploaderProps {
  folder: UploadFolder
  accept: string
  value?: string
  onUpload: (url: string) => void
  onClear?: () => void
  onUploadingChange?: (isUploading: boolean) => void
  previewType?: 'image' | 'video' | 'none'
  label?: string
  className?: string
}

export function FileUploader({
  folder,
  accept,
  value,
  onUpload,
  onClear,
  onUploadingChange,
  previewType = 'none',
  label = 'Drop a file here or click to browse',
  className,
}: FileUploaderProps) {
  const inputRef = useRef<HTMLInputElement>(null)
  const [dragging, setDragging] = useState(false)
  const [progress, setProgress] = useState<number | null>(null)
  const [error, setError] = useState<string | null>(null)

  async function uploadWithProgress(file: File) {
    setError(null)
    setProgress(0)
    onUploadingChange?.(true)
    try {
      const result = await uploadApi.presign({
        filename: file.name,
        contentType: file.type,
        folder,
      })
      if (!result.data) throw new Error('Failed to get upload URL')
      const { uploadUrl, fileUrl } = result.data

      await new Promise<void>((resolve, reject) => {
        const xhr = new XMLHttpRequest()
        xhr.upload.onprogress = (e) => {
          if (e.lengthComputable) setProgress(Math.round((e.loaded / e.total) * 100))
        }
        xhr.onload = () => {
          if (xhr.status >= 200 && xhr.status < 300) resolve()
          else reject(new Error(`Upload failed (${xhr.status})`))
        }
        xhr.onerror = () => reject(new Error('Upload failed'))
        xhr.open('PUT', uploadUrl)
        xhr.setRequestHeader('Content-Type', file.type)
        xhr.send(file)
      })

      onUpload(fileUrl)
    } catch (err) {
      setError((err as Error).message ?? 'Upload failed')
    } finally {
      setProgress(null)
      onUploadingChange?.(false)
      if (inputRef.current) inputRef.current.value = ''
    }
  }

  function handleFiles(files: FileList | null) {
    const file = files?.[0]
    if (!file) return
    uploadWithProgress(file)
  }

  const onDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    setDragging(true)
  }, [])

  const onDragLeave = useCallback(() => setDragging(false), [])

  const onDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    setDragging(false)
    handleFiles(e.dataTransfer.files)
  }, [])

  if (value) {
    return (
      <div className={cn('relative overflow-hidden rounded-lg border border-border', className)}>
        {previewType === 'image' && (
          <img src={value} alt="upload preview" className="h-full w-full object-cover" />
        )}
        {previewType === 'video' && (
          <video src={value} controls className="h-full w-full" />
        )}
        {previewType === 'none' && (
          <div className="flex items-center gap-2 px-3 py-2 text-sm text-foreground">
            <Upload className="h-4 w-4 shrink-0 text-muted-foreground" />
            <span className="truncate">{value}</span>
          </div>
        )}
        {onClear && (
          <button
            type="button"
            onClick={onClear}
            className="absolute right-2 top-2 rounded-full bg-background/80 p-1 text-foreground shadow hover:bg-background"
          >
            <X className="h-3.5 w-3.5" />
          </button>
        )}
      </div>
    )
  }

  return (
    <div className={cn('space-y-1.5', className)}>
      <div
        onClick={() => inputRef.current?.click()}
        onDragOver={onDragOver}
        onDragLeave={onDragLeave}
        onDrop={onDrop}
        className={cn(
          'flex cursor-pointer flex-col items-center justify-center gap-2 rounded-lg border-2 border-dashed px-4 py-8 transition-colors select-none',
          dragging
            ? 'border-primary bg-primary/5'
            : 'border-border hover:border-primary/50 hover:bg-muted/30',
          progress !== null && 'pointer-events-none opacity-75',
        )}
      >
        {progress !== null ? (
          <>
            <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
            <p className="text-sm text-muted-foreground">Uploading… {progress}%</p>
            <div className="h-1.5 w-full max-w-xs overflow-hidden rounded-full bg-muted">
              <div
                className="h-full rounded-full bg-primary transition-all duration-200"
                style={{ width: `${progress}%` }}
              />
            </div>
          </>
        ) : (
          <>
            {previewType === 'image' ? (
              <ImageIcon className="h-8 w-8 text-muted-foreground" />
            ) : previewType === 'video' ? (
              <Video className="h-8 w-8 text-muted-foreground" />
            ) : (
              <Upload className="h-8 w-8 text-muted-foreground" />
            )}
            <p className="text-center text-sm text-muted-foreground">{label}</p>
          </>
        )}
      </div>
      {error && <p className="text-xs text-destructive">{error}</p>}
      <input
        ref={inputRef}
        type="file"
        accept={accept}
        className="hidden"
        onChange={(e) => handleFiles(e.target.files)}
      />
    </div>
  )
}
