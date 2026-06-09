import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Pin, MessageSquare, Trash2, Plus, BarChart2, Search, X, Image, PlayCircle, Heart } from 'lucide-react'
import { formatDistanceToNow } from 'date-fns'
import { toast } from 'sonner'
import { postApi } from '@/api/post'
import { useAuthStore } from '@/store/auth.store'
import type { Post } from '@/types/post'
import { Button } from '@/components/ui/button'
import { Pagination } from '@/components/ui/pagination'
import { CreatePostModal } from '../components/CreatePostModal'
import { ConfirmModal } from '@/components/ui/confirm-modal'
import { OnboardingChecklist } from '../components/OnboardingChecklist'

// ─── Helpers ──────────────────────────────────────────────────────────────────

function authorInitials(post: Post) {
  return `${post.author.firstname[0]}${post.author.lastname[0]}`.toUpperCase()
}

function parsePoll(content: string): { options: string[] } | null {
  try {
    const data = JSON.parse(content)
    if (data?.poll === true && Array.isArray(data.options)) return data as { options: string[] }
    return null
  } catch {
    return null
  }
}

// ─── PostCard ─────────────────────────────────────────────────────────────────

function parseMedia(content: string): { mediaUrl: string; text?: string } | null {
  try {
    const data = JSON.parse(content)
    if (data?.mediaUrl) return { mediaUrl: data.mediaUrl, text: data.text }
  } catch {}
  if (content.startsWith('http://') || content.startsWith('https://')) return { mediaUrl: content }
  return null
}

function MediaThumbnail({ post }: { post: Post }) {
  const cls = 'h-24 w-32 shrink-0 self-start rounded-xl object-cover'
  if (post.type === 'IMAGE') {
    const media = parseMedia(post.content)
    return media ? (
      <img src={media.mediaUrl} alt="" className={cls} />
    ) : (
      <div className={`flex items-center justify-center bg-muted ${cls}`}>
        <Image className="h-6 w-6 text-muted-foreground/50" />
      </div>
    )
  }
  if (post.type === 'VIDEO') {
    return (
      <div className={`flex items-center justify-center bg-muted ${cls}`}>
        <PlayCircle className="h-8 w-8 text-muted-foreground/60" />
      </div>
    )
  }
  return null
}

function getTextPreview(content: string): string {
  try {
    const data = JSON.parse(content)
    if (data?.text) return data.text
    if (data?.poll === true) return ''
  } catch {}
  if (content.startsWith('http://') || content.startsWith('https://')) return ''
  return content
}

function PostCard({
  post,
  communityId,
  onDelete,
  onPin,
  canDelete,
  canPin,
}: {
  post: Post
  communityId: string
  onDelete: (postId: string) => void
  onPin: (postId: string) => void
  canDelete: boolean
  canPin: boolean
}) {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const poll = parsePoll(post.content)
  const preview = poll ? null : getTextPreview(post.content)
  const hasMedia = post.type === 'IMAGE' || post.type === 'VIDEO'

  const { mutate: toggleLike } = useMutation({
    mutationFn: () =>
      post.likedByMe
        ? postApi.unlike(communityId, post.id)
        : postApi.like(communityId, post.id),
    onMutate: async () => {
      await queryClient.cancelQueries({ queryKey: ['posts', communityId] })
      const previousEntries = queryClient.getQueriesData({ queryKey: ['posts', communityId] })
      queryClient.setQueriesData({ queryKey: ['posts', communityId] }, (old: any) => {
        if (!old?.data?.posts) return old
        return {
          ...old,
          data: {
            ...old.data,
            posts: old.data.posts.map((p: Post) =>
              p.id === post.id
                ? { ...p, likedByMe: !p.likedByMe, _count: { ...p._count, likes: p._count.likes + (p.likedByMe ? -1 : 1) } }
                : p
            ),
          },
        }
      })
      return { previousEntries }
    },
    onError: (_err, _vars, ctx) => {
      ctx?.previousEntries?.forEach(([key, data]) => queryClient.setQueryData(key, data))
    },
    onSettled: () => queryClient.invalidateQueries({ queryKey: ['posts', communityId] }),
  })

  return (
    <div
      onClick={() => navigate(`/communities/${communityId}/community/posts/${post.id}`)}
      className="group flex cursor-pointer items-start gap-4 rounded-xl border border-border bg-card p-5 transition-colors hover:border-primary/40"
    >
      {/* Main content */}
      <div className="min-w-0 flex-1">
        {/* Top row */}
        <div className="mb-3 flex items-center justify-between gap-2">
          <div className="flex items-center gap-2.5">
            <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary/10 text-xs font-bold text-primary">
              {authorInitials(post)}
            </div>
            <div className="flex items-center gap-1.5 text-sm">
              <span className="font-medium text-foreground">
                {post.author.firstname} {post.author.lastname}
              </span>
              <span className="text-muted-foreground">·</span>
              <span className="text-muted-foreground">
                {formatDistanceToNow(new Date(post.createdAt), { addSuffix: true })}
              </span>
            </div>
          </div>
          <div className="flex items-center gap-1">
            {canPin && (
              <button
                onClick={(e) => { e.stopPropagation(); onPin(post.id) }}
                title={post.isPinned ? 'Unpin post' : 'Pin post'}
                className={`rounded p-1 transition-all opacity-0 group-hover:opacity-100 ${
                  post.isPinned
                    ? 'text-primary opacity-100'
                    : 'text-muted-foreground hover:text-primary'
                }`}
              >
                <Pin className="h-3.5 w-3.5" />
              </button>
            )}
            {!canPin && post.isPinned && <Pin className="h-3.5 w-3.5 text-primary" />}
            {canDelete && (
              <button
                onClick={(e) => { e.stopPropagation(); onDelete(post.id) }}
                className="rounded p-1 text-muted-foreground opacity-0 transition-all hover:text-destructive group-hover:opacity-100"
              >
                <Trash2 className="h-3.5 w-3.5" />
              </button>
            )}
          </div>
        </div>

        {/* Title */}
        <h3 className="mb-1.5 font-semibold text-foreground">{post.title}</h3>

        {/* Body preview */}
        {poll ? (
          <div className="flex items-center gap-1.5 text-sm text-muted-foreground">
            <BarChart2 className="h-3.5 w-3.5 shrink-0" />
            <span>{poll.options.length} options</span>
          </div>
        ) : preview ? (
          <p className="line-clamp-2 text-sm leading-relaxed text-muted-foreground">{preview}</p>
        ) : null}

        {/* Footer */}
        <div className="mt-4 flex items-center gap-3">
          {post.category && (
            <span className="rounded-full bg-muted px-2 py-0.5 text-xs font-medium text-foreground/70">
              {post.category}
            </span>
          )}
          <div className="flex items-center gap-3 text-xs text-muted-foreground">
            <button
              onClick={(e) => { e.stopPropagation(); toggleLike() }}
              className={`flex items-center gap-1 transition-colors hover:text-rose-500 ${post.likedByMe ? 'text-rose-500' : ''}`}
            >
              <Heart className={`h-3.5 w-3.5 ${post.likedByMe ? 'fill-rose-500' : ''}`} />
              {post._count.likes}
            </button>
            <div className="flex items-center gap-1">
              <MessageSquare className="h-3.5 w-3.5" />
              {post._count.comments}
            </div>
          </div>
        </div>
      </div>

      {/* Thumbnail */}
      {hasMedia && <MediaThumbnail post={post} />}
    </div>
  )
}

// ─── Feed ─────────────────────────────────────────────────────────────────────

export function Feed() {
  const { id: communityId } = useParams<{ id: string }>()
  const { user } = useAuthStore()
  const queryClient = useQueryClient()
  const [createOpen, setCreateOpen] = useState(false)
  const [activeCategory, setActiveCategory] = useState<string>('All')
  const [deletingPostId, setDeletingPostId] = useState<string | null>(null)
  const [searchInput, setSearchInput] = useState('')
  const [searchQuery, setSearchQuery] = useState('')
  const [page, setPage] = useState(1)

  const isMock = communityId?.startsWith('mock-')

  useEffect(() => {
    const t = setTimeout(() => { setSearchQuery(searchInput.trim()); setPage(1) }, 400)
    return () => clearTimeout(t)
  }, [searchInput])

  const { data, isLoading } = useQuery({
    queryKey: ['posts', communityId, searchQuery, page],
    queryFn: () => postApi.list(communityId!, searchQuery || undefined, page, 30),
    enabled: !!communityId && !isMock,
  })

  const { mutate: deletePost, isPending: deletingPost } = useMutation({
    mutationFn: (postId: string) => postApi.delete(communityId!, postId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['posts', communityId] })
      toast.success('Post deleted')
      setDeletingPostId(null)
    },
    onError: (err) => toast.error((err as Error).message),
  })

  const { data: communityData } = useQuery({
    queryKey: ['community', communityId],
    queryFn: () => import('@/api/community').then((m) => m.communityApi.getById(communityId!)),
    enabled: !!communityId && !isMock,
  })
  const isCreator = communityData?.data?.community?.creator?.id === user?.id

  const { mutate: togglePin } = useMutation({
    mutationFn: (postId: string) => postApi.togglePin(communityId!, postId),
    onMutate: async (postId) => {
      await queryClient.cancelQueries({ queryKey: ['posts', communityId] })
      const prev = queryClient.getQueriesData({ queryKey: ['posts', communityId] })
      queryClient.setQueriesData({ queryKey: ['posts', communityId] }, (old: any) => {
        if (!old?.data?.posts) return old
        return {
          ...old,
          data: {
            ...old.data,
            posts: old.data.posts.map((p: Post) =>
              p.id === postId ? { ...p, isPinned: !p.isPinned } : p
            ),
          },
        }
      })
      return { prev }
    },
    onError: (_err, _vars, ctx) => {
      ctx?.prev?.forEach(([key, data]) => queryClient.setQueryData(key, data))
      toast.error('Failed to update pin')
    },
    onSettled: () => queryClient.invalidateQueries({ queryKey: ['posts', communityId] }),
  })

  const posts = data?.data?.posts ?? []
  const totalPages = data?.data?.totalPages ?? 1

  // Derive category list from posts
  const categories = [
    'All',
    ...Array.from(new Set(posts.map((p) => p.category).filter(Boolean) as string[])),
  ]

  const filtered =
    activeCategory === 'All'
      ? posts
      : posts.filter((p) => p.category === activeCategory)

  if (isLoading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="h-6 w-6 animate-spin rounded-full border-4 border-border border-t-primary" />
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-foreground">Feed</h2>
        {!isMock && (
          <Button size="sm" onClick={() => setCreateOpen(true)}>
            <Plus className="h-4 w-4" />
            New post
          </Button>
        )}
      </div>

      {/* Search */}
      {!isMock && (
        <div className="relative">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <input
            value={searchInput}
            onChange={(e) => { setSearchInput(e.target.value); setActiveCategory('All') }}
            placeholder="Search posts…"
            className="w-full rounded-lg border border-border bg-muted/40 py-2 pl-9 pr-8 text-sm text-foreground placeholder:text-muted-foreground focus:border-primary focus:bg-background focus:outline-none"
          />
          {searchInput && (
            <button
              onClick={() => setSearchInput('')}
              className="absolute right-2.5 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
            >
              <X className="h-3.5 w-3.5" />
            </button>
          )}
        </div>
      )}

      {isMock && (
        <div className="rounded-lg border border-border bg-muted/50 px-4 py-3 text-sm text-muted-foreground">
          This is a demo community. Create a real community to post and interact.
        </div>
      )}

      {/* Creator onboarding checklist */}
      {!isMock && (
        <OnboardingChecklist
          communityId={communityId!}
          onCreatePost={() => setCreateOpen(true)}
        />
      )}

      {/* Category tabs */}
      {categories.length > 1 && (
        <div className="flex gap-1 overflow-x-auto">
          {categories.map((cat) => (
            <button
              key={cat}
              onClick={() => setActiveCategory(cat)}
              className={`shrink-0 rounded-full px-3 py-1 text-sm font-medium transition-colors ${
                activeCategory === cat
                  ? 'bg-primary text-primary-foreground'
                  : 'bg-muted text-muted-foreground hover:text-foreground'
              }`}
            >
              {cat}
            </button>
          ))}
        </div>
      )}

      {/* Posts */}
      {filtered.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-xl border border-border bg-card py-16 text-center">
          <MessageSquare className="h-9 w-9 text-muted-foreground" />
          {searchQuery ? (
            <>
              <p className="mt-3 font-semibold text-foreground">No results for "{searchQuery}"</p>
              <p className="mt-1 text-sm text-muted-foreground">Try a different search term.</p>
            </>
          ) : (
            <>
              <p className="mt-3 font-semibold text-foreground">No posts yet</p>
              <p className="mt-1 text-sm text-muted-foreground">Be the first to post something.</p>
            </>
          )}
        </div>
      ) : (
        <div className="space-y-3">
          {filtered.map((post) => (
            <PostCard
              key={post.id}
              post={post}
              communityId={communityId!}
              canDelete={user?.id === post.authorId || isCreator}
              canPin={isCreator}
              onDelete={(id) => setDeletingPostId(id)}
              onPin={(id) => togglePin(id)}
            />
          ))}
        </div>
      )}

      {!isMock && totalPages > 1 && (
        <Pagination
          page={page}
          totalPages={totalPages}
          onChange={(p) => { setPage(p); window.scrollTo({ top: 0, behavior: 'smooth' }) }}
        />
      )}

      <CreatePostModal
        open={createOpen}
        onOpenChange={setCreateOpen}
        communityId={communityId!}
      />

      <ConfirmModal
        open={!!deletingPostId}
        onOpenChange={(v) => { if (!v) setDeletingPostId(null) }}
        title="Delete post?"
        description="This post and all its comments will be permanently deleted."
        confirmLabel="Delete"
        onConfirm={() => deletingPostId && deletePost(deletingPostId)}
        isPending={deletingPost}
      />
    </div>
  )
}
