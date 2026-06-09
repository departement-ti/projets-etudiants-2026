import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { ArrowLeft, Trash2, MessageSquare, Pin, Send, Heart } from 'lucide-react'
import { formatDistanceToNow } from 'date-fns'
import { toast } from 'sonner'
import { xpToast } from '@/lib/xpToast'
import { postApi } from '@/api/post'
import { useAuthStore } from '@/store/auth.store'
import type { Comment } from '@/types/post'
import { Button } from '@/components/ui/button'
import { ConfirmModal } from '@/components/ui/confirm-modal'

interface PollData {
  options: string[]
  text?: string
  mediaUrl?: string
  mediaType?: 'image' | 'video'
}

function parsePoll(content: string): PollData | null {
  try {
    const data = JSON.parse(content)
    if (data?.poll === true && Array.isArray(data.options)) return data as PollData
    return null
  } catch {
    return null
  }
}

interface MediaData { mediaUrl: string; mediaType: 'image' | 'video'; text?: string }

function parseMedia(content: string): MediaData | null {
  try {
    const data = JSON.parse(content)
    if (data?.mediaUrl && data?.mediaType) return data as MediaData
  } catch {}
  // Legacy: plain URL stored directly as content
  if (content.startsWith('http://') || content.startsWith('https://')) {
    return { mediaUrl: content, mediaType: 'image' }
  }
  return null
}

// ─── CommentItem ──────────────────────────────────────────────────────────────

function CommentItem({
  comment,
  communityId,
  postId,
  canDelete,
}: {
  comment: Comment
  communityId: string
  postId: string
  canDelete: boolean
}) {
  const queryClient = useQueryClient()
  const [confirmDelete, setConfirmDelete] = useState(false)

  const { mutate: deleteComment, isPending: deleting } = useMutation({
    mutationFn: () => postApi.deleteComment(communityId, postId, comment.id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['comments', postId] })
      toast.success('Comment deleted')
      setConfirmDelete(false)
    },
    onError: (err) => toast.error((err as Error).message),
  })

  const initials = `${comment.author.firstname[0]}${comment.author.lastname[0]}`.toUpperCase()

  return (
    <>
      <div className="group flex gap-3">
        <div className="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-primary/10 text-xs font-bold text-primary">
          {initials}
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex items-baseline gap-2">
            <span className="text-sm font-medium text-foreground">
              {comment.author.firstname} {comment.author.lastname}
            </span>
            <span className="text-xs text-muted-foreground">
              {formatDistanceToNow(new Date(comment.createdAt), { addSuffix: true })}
            </span>
          </div>
          <p className="mt-0.5 text-sm leading-relaxed text-foreground/90">{comment.content}</p>
        </div>
        {canDelete && (
          <button
            onClick={() => setConfirmDelete(true)}
            className="mt-0.5 shrink-0 rounded p-1 text-muted-foreground opacity-0 transition-all hover:text-destructive group-hover:opacity-100"
          >
            <Trash2 className="h-3.5 w-3.5" />
          </button>
        )}
      </div>
      <ConfirmModal
        open={confirmDelete}
        onOpenChange={setConfirmDelete}
        title="Delete comment?"
        description="This comment will be permanently deleted."
        confirmLabel="Delete"
        onConfirm={() => deleteComment()}
        isPending={deleting}
      />
    </>
  )
}

// ─── PostDetail ───────────────────────────────────────────────────────────────

export function PostDetail() {
  const { id: communityId, postId } = useParams<{ id: string; postId: string }>()
  const isMock = communityId?.startsWith('mock-')
  const navigate = useNavigate()
  const { user } = useAuthStore()
  const queryClient = useQueryClient()
  const [commentText, setCommentText] = useState('')
  const [confirmDeletePost, setConfirmDeletePost] = useState(false)
  const [selectedPollOption, setSelectedPollOption] = useState<number | null>(null)

  const { data: postData, isLoading: postLoading } = useQuery({
    queryKey: ['post', postId],
    queryFn: () => postApi.getById(communityId!, postId!),
    enabled: !!communityId && !!postId,
  })

  const { data: commentsData } = useQuery({
    queryKey: ['comments', postId],
    queryFn: () => postApi.getComments(communityId!, postId!),
    enabled: !!communityId && !!postId,
  })

  const { mutate: deletePost, isPending: deletingPost } = useMutation({
    mutationFn: () => postApi.delete(communityId!, postId!),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['posts', communityId] })
      toast.success('Post deleted')
      navigate(`/communities/${communityId}/community`)
    },
    onError: (err) => toast.error((err as Error).message),
  })

  const { mutate: addComment, isPending: commenting } = useMutation({
    mutationFn: () => postApi.createComment(communityId!, postId!, commentText),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['comments', postId] })
      setCommentText('')
      xpToast(2)
    },
  })

  const { mutate: toggleLike } = useMutation({
    mutationFn: () =>
      post?.likedByMe
        ? postApi.unlike(communityId!, postId!)
        : postApi.like(communityId!, postId!),
    onMutate: async () => {
      await queryClient.cancelQueries({ queryKey: ['post', postId] })
      const previous = queryClient.getQueryData(['post', postId])
      queryClient.setQueryData(['post', postId], (old: any) => {
        if (!old?.data?.post) return old
        const p = old.data.post
        return {
          ...old,
          data: {
            ...old.data,
            post: { ...p, likedByMe: !p.likedByMe, _count: { ...p._count, likes: p._count.likes + (p.likedByMe ? -1 : 1) } },
          },
        }
      })
      return { previous }
    },
    onError: (_err, _vars, ctx) => {
      if (ctx?.previous) queryClient.setQueryData(['post', postId], ctx.previous)
    },
    onSettled: () => queryClient.invalidateQueries({ queryKey: ['post', postId] }),
  })

  const post = postData?.data?.post
  const comments = commentsData?.data?.comments ?? []

  if (postLoading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="h-6 w-6 animate-spin rounded-full border-4 border-border border-t-primary" />
      </div>
    )
  }

  if (!post) {
    return (
      <div className="rounded-xl border border-border bg-card p-8 text-center text-muted-foreground">
        Post not found.
      </div>
    )
  }

  const initials = `${post.author.firstname[0]}${post.author.lastname[0]}`.toUpperCase()
  const canDeletePost = user?.id === post.authorId

  return (
    <div className="space-y-4">
      {/* Back */}
      <button
        onClick={() => navigate(`/communities/${communityId}/community`)}
        className="flex items-center gap-1.5 text-sm text-muted-foreground transition-colors hover:text-foreground"
      >
        <ArrowLeft className="h-4 w-4" />
        Back to feed
      </button>

      {/* Post */}
      <div className="rounded-xl border border-border bg-card p-6">
        {/* Author row */}
        <div className="mb-4 flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary/10 text-xs font-bold text-primary">
              {initials}
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
          <div className="flex items-center gap-2">
            {post.isPinned && <Pin className="h-3.5 w-3.5 text-primary" />}
            {canDeletePost && (
              <button
                onClick={() => setConfirmDeletePost(true)}
                className="rounded p-1 text-muted-foreground transition-colors hover:text-destructive"
              >
                <Trash2 className="h-4 w-4" />
              </button>
            )}
          </div>
        </div>

        {/* Title + content */}
        <h1 className="mb-3 text-xl font-bold text-foreground">{post.title}</h1>
        {(() => {
          const poll = parsePoll(post.content)
          if (poll) {
            return (
              <div className="space-y-3">
                {poll.text && (
                  <p className="leading-relaxed text-foreground/90 whitespace-pre-wrap">{poll.text}</p>
                )}
                {poll.mediaUrl && poll.mediaType === 'image' && (
                  <img src={poll.mediaUrl} alt={post.title} className="w-full rounded-lg object-cover" />
                )}
                {poll.mediaUrl && poll.mediaType === 'video' && (
                  <video src={poll.mediaUrl} controls className="w-full rounded-lg" />
                )}
                <div className="space-y-2">
                  {poll.options.map((opt, i) => (
                    <button
                      key={i}
                      type="button"
                      onClick={() => setSelectedPollOption(i === selectedPollOption ? null : i)}
                      className={`w-full rounded-lg border px-4 py-2.5 text-left text-sm transition-colors ${
                        selectedPollOption === i
                          ? 'border-primary bg-primary/10 font-medium text-primary'
                          : 'border-border text-foreground hover:border-primary/40 hover:bg-muted/40'
                      }`}
                    >
                      {opt}
                    </button>
                  ))}
                </div>
              </div>
            )
          }
          if (post.type === 'IMAGE' || post.type === 'VIDEO') {
            const media = parseMedia(post.content)
            if (media) {
              return (
                <div className="space-y-3">
                  {media.text && (
                    <p className="leading-relaxed text-foreground/90 whitespace-pre-wrap">{media.text}</p>
                  )}
                  {post.type === 'IMAGE'
                    ? <img src={media.mediaUrl} alt={post.title} className="max-h-[600px] w-full rounded-lg object-cover" />
                    : <video src={media.mediaUrl} controls className="w-full rounded-lg" />
                  }
                </div>
              )
            }
            return <p className="leading-relaxed text-foreground/90 whitespace-pre-wrap">{post.content}</p>
          }
          return <p className="leading-relaxed text-foreground/90 whitespace-pre-wrap">{post.content}</p>
        })()}

        {/* Meta */}
        <div className="mt-4 flex items-center gap-3 border-t border-border pt-4">
          {post.category && (
            <span className="rounded-full bg-muted px-2 py-0.5 text-xs font-medium text-foreground/70">
              {post.category}
            </span>
          )}
          <div className="ml-auto flex items-center gap-4 text-sm text-muted-foreground">
            <button
              onClick={() => toggleLike()}
              className={`flex items-center gap-1.5 transition-colors hover:text-rose-500 ${post.likedByMe ? 'text-rose-500' : ''}`}
            >
              <Heart className={`h-4 w-4 ${post.likedByMe ? 'fill-rose-500' : ''}`} />
              <span>{post._count.likes}</span>
            </button>
            <span className="flex items-center gap-1.5">
              <MessageSquare className="h-4 w-4" />
              {comments.length} comment{comments.length !== 1 ? 's' : ''}
            </span>
          </div>
        </div>
      </div>

      {/* Comments */}
      <div className="rounded-xl border border-border bg-card p-6">
        <h2 className="mb-4 text-sm font-semibold text-foreground">
          Comments{comments.length > 0 && ` (${comments.length})`}
        </h2>

        {comments.length > 0 && (
          <div className="mb-6 space-y-4">
            {comments.map((comment) => (
              <CommentItem
                key={comment.id}
                comment={comment}
                communityId={communityId!}
                postId={postId!}
                canDelete={user?.id === comment.authorId}
              />
            ))}
          </div>
        )}

        {/* Comment input */}
        {isMock ? (
          <p className="text-sm text-muted-foreground">
            This is a demo community. Comments are disabled.
          </p>
        ) : (
          <>
            <form
              onSubmit={(e) => {
                e.preventDefault()
                if (commentText.trim()) addComment()
              }}
              className="flex gap-2"
            >
              <textarea
                value={commentText}
                onChange={(e) => setCommentText(e.target.value)}
                placeholder="Write a comment..."
                rows={2}
                className="flex-1 resize-none rounded-md border border-border bg-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 focus:ring-offset-background"
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault()
                    if (commentText.trim()) addComment()
                  }
                }}
              />
              <Button
                type="submit"
                size="icon"
                disabled={commenting || !commentText.trim()}
                className="self-end"
              >
                <Send className="h-4 w-4" />
              </Button>
            </form>
            <p className="mt-1.5 text-xs text-muted-foreground">Enter to send · Shift+Enter for newline</p>
          </>
        )}
      </div>

      <ConfirmModal
        open={confirmDeletePost}
        onOpenChange={setConfirmDeletePost}
        title="Delete post?"
        description="This post and all its comments will be permanently deleted."
        confirmLabel="Delete"
        onConfirm={() => deletePost()}
        isPending={deletingPost}
      />
    </div>
  )
}
