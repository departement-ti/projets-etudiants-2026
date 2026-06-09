import { Link, useParams } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { ArrowLeft, Users, FileText, Lock } from 'lucide-react'
import { PublicNav } from '@/components/shared/PublicNav'
import { Button } from '@/components/ui/button'
import { communityApi } from '@/api/community'
import { formatCount, getGradient, getPricingLabel } from '../utils/community.utils'
import type { CommunityDetail } from '@/types/community'
import { MOCK_COMMUNITY_DETAIL } from '@/mocks/communities.mock'

function PricingSection({ community }: { community: CommunityDetail }) {
  const { pricingModel, pricing } = community

  const label = getPricingLabel(pricingModel, pricing)

  const joinLabel =
    pricingModel === 'FREE' || pricingModel === 'FREEMIUM'
      ? 'Join for free'
      : `Join · ${label}`

  return (
    <div className="rounded-xl border border-border bg-card p-6">
      <h2 className="mb-1 text-lg font-semibold text-foreground">Membership</h2>

      <div className="mb-4 text-sm text-muted-foreground">
        {pricingModel === 'FREE' && 'This community is free to join.'}
        {pricingModel === 'FREEMIUM' &&
          `Free to join. ${pricing?.upgradePrice ? `Upgrade to premium for $${pricing.upgradePrice}/mo.` : 'Premium features available.'}`}
        {pricingModel === 'SUBSCRIPTION' && (
          <span>
            {pricing?.monthlyPrice && (
              <span className="mr-3">
                <span className="text-2xl font-bold text-foreground">${Number(pricing.monthlyPrice).toFixed(2)}</span>
                <span className="text-muted-foreground">/mo</span>
              </span>
            )}
            {pricing?.yearlyPrice && (
              <span>
                <span className="text-xl font-semibold text-foreground">${Number(pricing.yearlyPrice).toFixed(2)}</span>
                <span className="text-muted-foreground">/yr</span>
              </span>
            )}
          </span>
        )}
        {pricingModel === 'ONE_TIME' && pricing?.oneTimePrice && (
          <span>
            <span className="text-2xl font-bold text-foreground">${Number(pricing.oneTimePrice).toFixed(2)}</span>
            <span className="text-muted-foreground"> one-time</span>
          </span>
        )}
      </div>

      <Link to="/sign-up">
        <Button className="w-full">{joinLabel}</Button>
      </Link>

      <p className="mt-3 text-center text-xs text-muted-foreground">
        Already a member?{' '}
        <Link to="/sign-in" className="text-primary hover:underline">
          Sign in
        </Link>
      </p>
    </div>
  )
}

function AboutSkeleton({ gradient }: { gradient: string }) {
  return (
    <div className="min-h-screen bg-background">
      <PublicNav />
      <div className={`h-56 w-full bg-gradient-to-br ${gradient} animate-pulse`} />
      <div className="mx-auto max-w-4xl px-4">
        <div className="-mt-12 flex items-end gap-5">
          <div className={`h-24 w-24 shrink-0 rounded-2xl bg-gradient-to-br ${gradient} border-4 border-background animate-pulse`} />
        </div>
        <div className="mt-5 space-y-3">
          <div className="h-8 w-64 animate-pulse rounded bg-muted" />
          <div className="h-4 w-48 animate-pulse rounded bg-muted" />
        </div>
      </div>
    </div>
  )
}

export function CommunityAbout() {
  const { id } = useParams<{ id: string }>()

  const isMock = id === MOCK_COMMUNITY_DETAIL.id

  const { data, isLoading, isError } = useQuery({
    queryKey: ['community', id],
    queryFn: () => communityApi.getById(id!),
    enabled: !!id && !isMock,
  })

  const community: CommunityDetail | undefined = isMock
    ? MOCK_COMMUNITY_DETAIL
    : data?.data?.community
  const gradient = getGradient(id ?? '')

  if (isLoading) return <AboutSkeleton gradient={gradient} />

  if (isError || !community) {
    return (
      <div className="min-h-screen bg-background">
        <PublicNav />
        <div className="flex flex-col items-center justify-center py-32 text-center">
          <p className="text-lg font-semibold text-foreground">Community not found</p>
          <p className="mt-1 text-sm text-muted-foreground">
            This community may not exist or may be private.
          </p>
          <Link to="/communities" className="mt-6">
            <Button variant="outline">
              <ArrowLeft className="h-4 w-4" />
              Back to communities
            </Button>
          </Link>
        </div>
      </div>
    )
  }

  const initials = community.name.slice(0, 2).toUpperCase()
  const communityGradient = getGradient(community.id)

  return (
    <div className="min-h-screen bg-background">
      <PublicNav />

      {/* Banner */}
      <div className={`h-56 w-full overflow-hidden ${community.coverUrl ? '' : `bg-gradient-to-br ${communityGradient}`}`}>
        {community.coverUrl && (
          <img src={community.coverUrl} alt="" className="h-full w-full object-cover" />
        )}
      </div>

      {/* Main content */}
      <div className="mx-auto max-w-4xl px-4 pb-20">
        {/* Avatar row */}
        <div className="-mt-12 flex items-end justify-between">
          <div
            className={`flex h-24 w-24 shrink-0 items-center justify-center rounded-2xl overflow-hidden border-4 border-background shadow-xl ${community.iconUrl ? '' : `bg-gradient-to-br ${communityGradient}`}`}
          >
            {community.iconUrl ? (
              <img src={community.iconUrl} alt="" className="h-full w-full object-cover" />
            ) : (
              <span className="text-3xl font-bold text-white">{initials}</span>
            )}
          </div>

          <div className="mb-1">
            <Link to="/communities">
              <Button variant="outline" size="sm">
                <ArrowLeft className="h-4 w-4" />
                All communities
              </Button>
            </Link>
          </div>
        </div>

        <div className="mt-5 grid grid-cols-1 gap-8 lg:grid-cols-3">
          {/* Left: info */}
          <div className="lg:col-span-2">
            <h1 className="text-3xl font-bold text-foreground">{community.name}</h1>

            {/* Stats */}
            <div className="mt-3 flex flex-wrap items-center gap-4 text-sm text-muted-foreground">
              <span className="flex items-center gap-1.5">
                <Users className="h-4 w-4" />
                {formatCount(community._count.memberships)} members
              </span>
              <span className="flex items-center gap-1.5">
                <FileText className="h-4 w-4" />
                {formatCount(community._count.posts)} posts
              </span>
              {community.isPrivate && (
                <span className="flex items-center gap-1.5">
                  <Lock className="h-4 w-4" />
                  Private
                </span>
              )}
              <span>
                By{' '}
                <span className="font-medium text-foreground">
                  {community.creator.firstname} {community.creator.lastname}
                </span>
              </span>
            </div>

            {/* Description */}
            {community.description ? (
              <p className="mt-6 leading-relaxed text-foreground/90">{community.description}</p>
            ) : (
              <p className="mt-6 italic text-muted-foreground">No description yet.</p>
            )}
          </div>

          {/* Right: pricing / join */}
          <div>
            <PricingSection community={community} />
          </div>
        </div>
      </div>
    </div>
  )
}
