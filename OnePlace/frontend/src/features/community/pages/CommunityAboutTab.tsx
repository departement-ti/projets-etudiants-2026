import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { Users, FileText, Calendar, Lock, CheckCircle, Play } from 'lucide-react'
import type { CommunityMedia } from '@/types/community'
import { useQuery } from '@tanstack/react-query'
import { getMockCommunityDetail, getMockMembership } from '@/mocks/communities.mock'
import { communityApi } from '@/api/community'
import { formatCount, getGradient, getPricingLabel } from '../utils/community.utils'
import { JoinModal } from '../components/JoinModal'
import { UpgradeModal } from '../components/UpgradeModal'
import { Button } from '@/components/ui/button'

// ─── MediaGallery ─────────────────────────────────────────────────────────────

function getYouTubeThumbnail(url: string): string | null {
  const match = url.match(
    /(?:youtube\.com\/(?:watch\?v=|embed\/)|youtu\.be\/)([A-Za-z0-9_-]{11})/
  )
  return match ? `https://img.youtube.com/vi/${match[1]}/hqdefault.jpg` : null
}

function getEmbedUrl(url: string): string | null {
  const ytMatch = url.match(
    /(?:youtube\.com\/watch\?v=|youtu\.be\/)([A-Za-z0-9_-]{11})/
  )
  if (ytMatch) return `https://www.youtube.com/embed/${ytMatch[1]}?autoplay=1`

  const vimeoMatch = url.match(/vimeo\.com\/(\d+)/)
  if (vimeoMatch) return `https://player.vimeo.com/video/${vimeoMatch[1]}?autoplay=1`

  return null
}

function MediaGallery({ items }: { items: CommunityMedia[] }) {
  const [active, setActive] = useState(0)
  const [playing, setPlaying] = useState(false)

  if (items.length === 0) return null

  const current = items[active]
  const thumbSrc =
    current.type === 'IMAGE'
      ? current.url
      : current.thumbnailUrl ?? getYouTubeThumbnail(current.url) ?? null
  const embedUrl = current.type === 'VIDEO' ? getEmbedUrl(current.url) : null
  // direct upload (no embed URL) — play with <video> tag
  const isDirectVideo = current.type === 'VIDEO' && !embedUrl

  return (
    <div className="rounded-xl border border-border bg-card overflow-hidden">
      {/* Main display */}
      <div className="relative aspect-video w-full bg-black">
        {playing && embedUrl ? (
          <iframe
            src={embedUrl}
            className="h-full w-full"
            allow="autoplay; fullscreen"
            allowFullScreen
          />
        ) : playing && isDirectVideo ? (
          <video
            src={current.url}
            className="h-full w-full"
            controls
            autoPlay
          />
        ) : (
          <>
            {thumbSrc ? (
              <img src={thumbSrc} alt="" className="h-full w-full object-cover" />
            ) : (
              <div className="flex h-full w-full items-center justify-center bg-muted text-muted-foreground">
                <Play className="h-12 w-12" />
              </div>
            )}
            {current.type === 'VIDEO' && (
              <button
                onClick={() => setPlaying(true)}
                className="absolute inset-0 flex items-center justify-center"
              >
                <div className="rounded-full bg-black/60 p-4 transition-transform hover:scale-110">
                  <Play className="h-8 w-8 fill-white text-white" />
                </div>
              </button>
            )}
          </>
        )}
      </div>

      {/* Thumbnail strip */}
      {items.length > 1 && (
        <div className="flex gap-2 overflow-x-auto p-3">
          {items.map((item, i) => {
            const tn =
              item.type === 'IMAGE'
                ? item.url
                : item.thumbnailUrl ?? getYouTubeThumbnail(item.url) ?? null
            return (
              <button
                key={item.id}
                onClick={() => { setActive(i); setPlaying(false) }}
                className={`relative h-16 w-24 shrink-0 overflow-hidden rounded-lg border-2 transition-colors ${
                  i === active ? 'border-primary' : 'border-transparent'
                }`}
              >
                {tn ? (
                  <img src={tn} alt="" className="h-full w-full object-cover" />
                ) : (
                  <div className="flex h-full w-full items-center justify-center bg-muted">
                    <Play className="h-4 w-4 text-muted-foreground" />
                  </div>
                )}
                {item.type === 'VIDEO' && (
                  <div className="absolute inset-0 flex items-center justify-center bg-black/30">
                    <Play className="h-3.5 w-3.5 fill-white text-white" />
                  </div>
                )}
              </button>
            )
          })}
        </div>
      )}
    </div>
  )
}

// ─── CommunityAboutTab ────────────────────────────────────────────────────────

export function CommunityAboutTab() {
  const { id } = useParams<{ id: string }>()
  const [joinOpen, setJoinOpen] = useState(false)
  const [upgradeOpen, setUpgradeOpen] = useState(false)

  const isMock = id?.startsWith('mock-')

  const { data: communityData } = useQuery({
    queryKey: ['community', id],
    queryFn: () => communityApi.getById(id!),
    enabled: !!id && !isMock,
  })

  const { data: membershipData } = useQuery({
    queryKey: ['membership', id],
    queryFn: () => communityApi.getMyMembership(id!),
    enabled: !!id && !isMock,
  })

  const community = isMock ? getMockCommunityDetail(id ?? '') : communityData?.data?.community
  const membership = isMock ? getMockMembership(id ?? '') : membershipData?.data?.membership

  if (!community) return null

  const gradient = getGradient(community.id)
  const initials = community.name.slice(0, 2).toUpperCase()

  const isCreatorOrAdmin = membership?.role === 'creator' || membership?.role === 'admin'
  const isActiveMember = membership?.status === 'ACTIVE' || isCreatorOrAdmin
  const isFreeTierInFreemium =
    isActiveMember &&
    community.pricingModel === 'FREEMIUM' &&
    membership?.membershipTier === 'FREE'

  return (
    <div className="space-y-6">
      {/* Header card */}
      <div className="overflow-hidden rounded-xl border border-border bg-card">
        <div className={`h-32 w-full overflow-hidden ${community.coverUrl ? '' : `bg-gradient-to-br ${gradient}`}`}>
          {community.coverUrl && (
            <img src={community.coverUrl} alt="" className="h-full w-full object-cover" />
          )}
        </div>
        <div className="p-6">
          <div className="-mt-12 mb-4">
            <div
              className={`flex h-16 w-16 items-center justify-center rounded-xl overflow-hidden border-4 border-card shadow-lg ${community.iconUrl ? '' : `bg-gradient-to-br ${gradient}`}`}
            >
              {community.iconUrl ? (
                <img src={community.iconUrl} alt="" className="h-full w-full object-cover" />
              ) : (
                <span className="text-xl font-bold text-white">{initials}</span>
              )}
            </div>
          </div>
          <div className="flex items-start justify-between gap-4">
            <div>
              <h1 className="text-2xl font-bold text-foreground">{community.name}</h1>
              <p className="mt-1 text-sm text-muted-foreground">
                Created by {community.creator.firstname} {community.creator.lastname}
              </p>
            </div>

            {/* Action button */}
            {isActiveMember ? (
              isFreeTierInFreemium ? (
                <Button onClick={() => setUpgradeOpen(true)} size="sm">
                  Upgrade
                </Button>
              ) : (
                <div className="flex items-center gap-1.5 text-sm font-medium text-emerald-600">
                  <CheckCircle className="h-4 w-4" />
                  Member
                </div>
              )
            ) : (
              <Button onClick={() => setJoinOpen(true)} size="sm">
                Join
              </Button>
            )}
          </div>
        </div>
      </div>

      {/* Media gallery */}
      {community.media?.length > 0 && <MediaGallery items={community.media} />}

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        {/* Stats */}
        <div className="rounded-xl border border-border bg-card p-5">
          <h2 className="mb-4 text-sm font-semibold uppercase tracking-wide text-muted-foreground">
            Stats
          </h2>
          <div className="space-y-3">
            <div className="flex items-center gap-3 text-sm">
              <Users className="h-4 w-4 text-muted-foreground" />
              <span className="text-foreground">
                <span className="font-semibold">{formatCount(community._count.memberships)}</span>{' '}
                members
              </span>
            </div>
            <div className="flex items-center gap-3 text-sm">
              <FileText className="h-4 w-4 text-muted-foreground" />
              <span className="text-foreground">
                <span className="font-semibold">{formatCount(community._count.posts)}</span> posts
              </span>
            </div>
            <div className="flex items-center gap-3 text-sm">
              <Calendar className="h-4 w-4 text-muted-foreground" />
              <span className="text-foreground">
                Created{' '}
                <span className="font-semibold">
                  {new Date(community.createdAt).toLocaleDateString('en-US', {
                    month: 'long',
                    year: 'numeric',
                  })}
                </span>
              </span>
            </div>
            {community.isPrivate && (
              <div className="flex items-center gap-3 text-sm">
                <Lock className="h-4 w-4 text-muted-foreground" />
                <span className="text-foreground">Private community</span>
              </div>
            )}
          </div>
        </div>

        {/* Pricing */}
        <div className="rounded-xl border border-border bg-card p-5">
          <h2 className="mb-4 text-sm font-semibold uppercase tracking-wide text-muted-foreground">
            Membership
          </h2>
          <span className="inline-flex items-center rounded-full border border-border bg-muted px-3 py-1 text-sm font-medium text-foreground">
            {getPricingLabel(community.pricingModel, community.pricing)}
          </span>
          {community.pricing && (
            <div className="mt-3 space-y-1 text-sm text-muted-foreground">
              {community.pricing.monthlyPrice && (
                <p>
                  <span className="font-semibold text-foreground">
                    ${Number(community.pricing.monthlyPrice).toFixed(2)}
                  </span>{' '}
                  / month
                </p>
              )}
              {community.pricing.yearlyPrice && (
                <p>
                  <span className="font-semibold text-foreground">
                    ${Number(community.pricing.yearlyPrice).toFixed(2)}
                  </span>{' '}
                  / year
                </p>
              )}
              {community.pricing.oneTimePrice && (
                <p>
                  <span className="font-semibold text-foreground">
                    ${Number(community.pricing.oneTimePrice).toFixed(2)}
                  </span>{' '}
                  one-time
                </p>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Description */}
      {community.description && (
        <div className="rounded-xl border border-border bg-card p-5">
          <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-muted-foreground">
            About
          </h2>
          <p className="leading-relaxed text-foreground/90">{community.description}</p>
        </div>
      )}

      <JoinModal open={joinOpen} onOpenChange={setJoinOpen} community={community} />
      <UpgradeModal open={upgradeOpen} onOpenChange={setUpgradeOpen} community={community} />
    </div>
  )
}
