import { useEffect, useRef, useState } from 'react'
import { useParams } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { ImagePlus, Loader2, Plus, Trash2, X } from 'lucide-react'
import { communityApi } from '@/api/community'
import { uploadFile } from '@/api/upload'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { getGradient } from '../utils/community.utils'
import { AddMediaModal } from '../components/AddMediaModal'
import type { CommunityMedia } from '@/types/community'

// ─── ImageUploader ─────────────────────────────────────────────────────────────

interface ImageUploaderProps {
  label: string
  hint: string
  currentUrl: string | null
  previewUrl: string | null
  uploading: boolean
  onSelect: (file: File) => void
  onClear: () => void
  aspect?: 'cover' | 'icon'
}

function ImageUploader({
  label,
  hint,
  currentUrl,
  previewUrl,
  uploading,
  onSelect,
  onClear,
  aspect = 'cover',
}: ImageUploaderProps) {
  const inputRef = useRef<HTMLInputElement>(null)
  const display = previewUrl ?? currentUrl

  const isCover = aspect === 'cover'

  return (
    <div className="space-y-1.5">
      <Label>{label}</Label>
      <p className="text-xs text-muted-foreground">{hint}</p>
      <div
        className={`relative overflow-hidden rounded-xl border border-border bg-muted ${
          isCover ? 'h-36 w-full' : 'h-20 w-20'
        }`}
      >
        {display ? (
          <img src={display} alt="" className="h-full w-full object-cover" />
        ) : (
          <div className="flex h-full w-full items-center justify-center text-muted-foreground">
            <ImagePlus className="h-6 w-6" />
          </div>
        )}

        {uploading && (
          <div className="absolute inset-0 flex items-center justify-center bg-black/50">
            <Loader2 className="h-5 w-5 animate-spin text-white" />
          </div>
        )}

        {/* Overlay buttons */}
        {!uploading && (
          <div className="absolute inset-0 flex items-center justify-center gap-2 opacity-0 transition-opacity hover:opacity-100 hover:bg-black/40">
            <button
              type="button"
              onClick={() => inputRef.current?.click()}
              className="rounded-lg bg-white/90 px-2 py-1 text-xs font-medium text-black shadow"
            >
              {display ? 'Change' : 'Upload'}
            </button>
            {display && (
              <button
                type="button"
                onClick={onClear}
                className="rounded-lg bg-white/90 p-1 text-black shadow"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            )}
          </div>
        )}
      </div>
      <input
        ref={inputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp,image/gif"
        className="hidden"
        onChange={(e) => {
          const file = e.target.files?.[0]
          if (file) onSelect(file)
          e.target.value = ''
        }}
      />
    </div>
  )
}

// ─── MediaThumbnail ────────────────────────────────────────────────────────────

function getYouTubeThumbnail(url: string): string | null {
  const match = url.match(
    /(?:youtube\.com\/(?:watch\?v=|embed\/)|youtu\.be\/)([A-Za-z0-9_-]{11})/
  )
  return match ? `https://img.youtube.com/vi/${match[1]}/hqdefault.jpg` : null
}

interface MediaThumbnailProps {
  item: CommunityMedia
  onDelete: () => void
}

function MediaThumbnail({ item, onDelete }: MediaThumbnailProps) {
  const thumbSrc =
    item.type === 'IMAGE'
      ? item.url
      : item.thumbnailUrl ?? getYouTubeThumbnail(item.url) ?? null

  return (
    <div className="group relative h-24 w-36 overflow-hidden rounded-xl border border-border bg-muted">
      {thumbSrc ? (
        <img src={thumbSrc} alt="" className="h-full w-full object-cover" />
      ) : (
        <div className="flex h-full w-full items-center justify-center bg-muted text-muted-foreground">
          <span className="text-xs">Video</span>
        </div>
      )}
      {item.type === 'VIDEO' && (
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="rounded-full bg-black/60 p-2">
            <svg className="h-4 w-4 fill-white" viewBox="0 0 24 24">
              <path d="M8 5v14l11-7z" />
            </svg>
          </div>
        </div>
      )}
      <button
        type="button"
        onClick={onDelete}
        className="absolute right-1.5 top-1.5 rounded-full bg-black/60 p-1 text-white opacity-0 transition-opacity group-hover:opacity-100 hover:bg-red-600"
      >
        <Trash2 className="h-3 w-3" />
      </button>
    </div>
  )
}

// ─── SettingsGeneral ──────────────────────────────────────────────────────────

export function SettingsGeneral() {
  const { id } = useParams<{ id: string }>()
  const queryClient = useQueryClient()

  const { data } = useQuery({
    queryKey: ['community', id],
    queryFn: () => communityApi.getById(id!),
    enabled: !!id,
  })

  const community = data?.data?.community
  const gradient = getGradient(id ?? '')

  // ── Text fields ──
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [isPrivate, setIsPrivate] = useState(false)

  // ── Image state ──
  const [coverPreview, setCoverPreview] = useState<string | null>(null)
  const [coverFile, setCoverFile] = useState<File | null>(null)
  const [coverCleared, setCoverCleared] = useState(false)

  const [iconPreview, setIconPreview] = useState<string | null>(null)
  const [iconFile, setIconFile] = useState<File | null>(null)
  const [iconCleared, setIconCleared] = useState(false)

  const [uploadingCover, setUploadingCover] = useState(false)
  const [uploadingIcon, setUploadingIcon] = useState(false)

  useEffect(() => {
    if (community) {
      setName(community.name)
      setDescription(community.description ?? '')
      setIsPrivate(community.isPrivate)
    }
  }, [community])

  function handleCoverSelect(file: File) {
    setCoverFile(file)
    setCoverPreview(URL.createObjectURL(file))
    setCoverCleared(false)
  }

  function handleCoverClear() {
    setCoverFile(null)
    setCoverPreview(null)
    setCoverCleared(true)
  }

  function handleIconSelect(file: File) {
    setIconFile(file)
    setIconPreview(URL.createObjectURL(file))
    setIconCleared(false)
  }

  function handleIconClear() {
    setIconFile(null)
    setIconPreview(null)
    setIconCleared(true)
  }

  const { mutate: save, isPending } = useMutation({
    mutationFn: async () => {
      let coverUrl: string | null | undefined = undefined
      let iconUrl: string | null | undefined = undefined

      if (coverFile) {
        setUploadingCover(true)
        try {
          coverUrl = await uploadFile(coverFile, 'communities')
        } finally {
          setUploadingCover(false)
        }
      } else if (coverCleared) {
        coverUrl = null
      }

      if (iconFile) {
        setUploadingIcon(true)
        try {
          iconUrl = await uploadFile(iconFile, 'communities')
        } finally {
          setUploadingIcon(false)
        }
      } else if (iconCleared) {
        iconUrl = null
      }

      return communityApi.update(id!, {
        name,
        description: description || undefined,
        isPrivate,
        ...(coverUrl !== undefined && { coverUrl }),
        ...(iconUrl !== undefined && { iconUrl }),
      })
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['community', id] })
      setCoverFile(null)
      setCoverPreview(null)
      setCoverCleared(false)
      setIconFile(null)
      setIconPreview(null)
      setIconCleared(false)
      toast.success('Settings saved')
    },
    onError: (err) => toast.error((err as Error).message),
  })

  const isBusy = isPending || uploadingCover || uploadingIcon

  // ── Media gallery ──
  const [mediaModalOpen, setMediaModalOpen] = useState(false)

  const { mutate: addMedia } = useMutation({
    mutationFn: (vars: { url: string; type: 'IMAGE' | 'VIDEO'; thumbnailUrl?: string }) =>
      communityApi.addMedia(id!, vars),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['community', id] })
      toast.success('Media added')
    },
    onError: (err) => toast.error((err as Error).message),
  })

  const { mutate: deleteMedia } = useMutation({
    mutationFn: (mediaId: string) => communityApi.deleteMedia(id!, mediaId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['community', id] })
      toast.success('Media removed')
    },
    onError: (err) => toast.error((err as Error).message),
  })

  async function handleAddMedia(url: string, type: 'IMAGE' | 'VIDEO', thumbnailUrl?: string) {
    await new Promise<void>((resolve, reject) => {
      addMedia({ url, type, thumbnailUrl }, { onSuccess: () => resolve(), onError: reject })
    })
  }

  const mediaItems: CommunityMedia[] = community?.media ?? []

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-semibold text-foreground">General</h1>
        <p className="mt-1 text-sm text-muted-foreground">Basic community information and visibility.</p>
      </div>

      {/* ── Branding ── */}
      <div className="rounded-xl border border-border bg-card p-6 space-y-5">
        <h2 className="text-sm font-semibold text-foreground">Branding</h2>

        <ImageUploader
          label="Cover image"
          hint="Displayed at the top of your community card. Recommended 1200×400 px."
          currentUrl={community?.coverUrl ?? null}
          previewUrl={coverPreview}
          uploading={uploadingCover}
          onSelect={handleCoverSelect}
          onClear={handleCoverClear}
          aspect="cover"
        />

        <ImageUploader
          label="Community icon"
          hint="Square logo shown in the sidebar and community cards. Recommended 200×200 px."
          currentUrl={community?.iconUrl ?? null}
          previewUrl={iconPreview}
          uploading={uploadingIcon}
          onSelect={handleIconSelect}
          onClear={handleIconClear}
          aspect="icon"
        />

        {/* Live preview */}
        <div className="space-y-1.5">
          <Label>Preview</Label>
          <div className="flex items-center gap-3 rounded-lg border border-border bg-muted/40 p-3">
            <div
              className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-lg overflow-hidden bg-gradient-to-br ${gradient}`}
            >
              {(iconPreview ?? community?.iconUrl) ? (
                <img
                  src={iconPreview ?? community?.iconUrl ?? ''}
                  alt=""
                  className="h-full w-full object-cover"
                />
              ) : (
                <span className="text-sm font-bold text-white">
                  {(name || community?.name || 'C').slice(0, 2).toUpperCase()}
                </span>
              )}
            </div>
            <span className="text-sm font-semibold text-foreground">{name || community?.name}</span>
          </div>
        </div>
      </div>

      {/* ── Media gallery ── */}
      <div className="rounded-xl border border-border bg-card p-6 space-y-4">
        <div>
          <h2 className="text-sm font-semibold text-foreground">Media</h2>
          <p className="mt-0.5 text-xs text-muted-foreground">
            Images and videos shown in your community's about page.
          </p>
        </div>

        <div className="flex flex-wrap gap-3">
          {mediaItems.map((item) => (
            <MediaThumbnail key={item.id} item={item} onDelete={() => deleteMedia(item.id)} />
          ))}

          {/* Add placeholder */}
          <button
            type="button"
            onClick={() => setMediaModalOpen(true)}
            className="flex h-24 w-36 flex-col items-center justify-center gap-1.5 rounded-xl border-2 border-dashed border-border bg-muted/40 text-muted-foreground transition-colors hover:border-primary hover:text-primary"
          >
            <Plus className="h-5 w-5" />
            <span className="text-xs font-medium">Add media</span>
          </button>
        </div>
      </div>

      {/* ── Info ── */}
      <div className="rounded-xl border border-border bg-card p-6 space-y-5">
        <h2 className="text-sm font-semibold text-foreground">Information</h2>

        <div className="space-y-1.5">
          <Label htmlFor="name">Community name</Label>
          <Input
            id="name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Community name"
          />
        </div>

        <div className="space-y-1.5">
          <Label htmlFor="description">
            Description <span className="text-muted-foreground">(optional)</span>
          </Label>
          <textarea
            id="description"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Describe your community..."
            rows={4}
            className="w-full resize-none rounded-md border border-border bg-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 focus:ring-offset-background"
          />
        </div>

        <div className="flex items-center justify-between rounded-lg border border-border p-4">
          <div>
            <p className="text-sm font-medium text-foreground">Private community</p>
            <p className="text-xs text-muted-foreground mt-0.5">Hidden from the Discover page.</p>
          </div>
          <button
            type="button"
            onClick={() => setIsPrivate((v) => !v)}
            className={`relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors ${
              isPrivate ? 'bg-primary' : 'bg-muted'
            }`}
          >
            <span
              className={`pointer-events-none inline-block h-4 w-4 rounded-full bg-white shadow-sm transition-transform ${
                isPrivate ? 'translate-x-4' : 'translate-x-0'
              }`}
            />
          </button>
        </div>

        <div className="flex justify-end">
          <Button onClick={() => save()} disabled={isBusy || !name.trim()}>
            {isBusy ? 'Saving...' : 'Save changes'}
          </Button>
        </div>
      </div>

      <AddMediaModal
        open={mediaModalOpen}
        onClose={() => setMediaModalOpen(false)}
        onAdd={handleAddMedia}
      />
    </div>
  )
}
