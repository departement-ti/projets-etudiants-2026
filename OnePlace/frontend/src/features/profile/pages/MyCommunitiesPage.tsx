import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { ArrowRight } from 'lucide-react'
import { userApi } from '@/api/user'
import { getGradient } from '@/features/community/utils/community.utils'
import type { UserCommunity } from '@/types/community'

type RoleFilter = 'ALL' | 'CREATOR' | 'MEMBER'

const ROLE_LABELS: Record<string, string> = {
  creator: 'Creator',
  admin: 'Admin',
  member: 'Member',
}

const TIER_LABELS: Record<string, string> = {
  FREE: 'Free',
  PAID: 'Paid',
}

const FILTER_TABS: { label: string; value: RoleFilter }[] = [
  { label: 'All', value: 'ALL' },
  { label: 'Creator', value: 'CREATOR' },
  { label: 'Member', value: 'MEMBER' },
]

function CommunityRow({ item }: { item: UserCommunity }) {
  const gradient = getGradient(item.community.id)
  const isPaidCommunity = item.community.pricingModel !== 'FREE'

  return (
    <div className="flex items-center justify-between gap-4 rounded-xl border border-border bg-card p-4 transition-colors hover:bg-muted/30">
      <div className="flex min-w-0 items-center gap-3">
        <div
          className={`flex h-10 w-10 shrink-0 items-center justify-center overflow-hidden rounded-lg ${item.community.iconUrl ? '' : `bg-gradient-to-br ${gradient}`}`}
        >
          {item.community.iconUrl ? (
            <img src={item.community.iconUrl} alt="" className="h-full w-full object-cover" />
          ) : (
            <span className="text-sm font-bold text-white">
              {item.community.name.slice(0, 2).toUpperCase()}
            </span>
          )}
        </div>
        <div className="min-w-0">
          <p className="truncate font-medium text-foreground">{item.community.name}</p>
          <div className="mt-0.5 flex flex-wrap items-center gap-1.5 text-xs text-muted-foreground">
            <span className="rounded-full border border-border bg-muted px-2 py-0.5">
              {ROLE_LABELS[item.role] ?? item.role}
            </span>
            <span className="rounded-full border border-border bg-muted px-2 py-0.5">
              {TIER_LABELS[item.membershipTier] ?? item.membershipTier}
            </span>
            <span>
              Joined{' '}
              {new Date(item.joinedAt).toLocaleDateString('en-US', {
                month: 'short',
                year: 'numeric',
              })}
            </span>
          </div>
        </div>
      </div>

      <div className="flex shrink-0 items-center gap-2">
        {isPaidCommunity && (
          <Link
            to={`/communities/${item.community.id}/subscription`}
            className="text-xs text-muted-foreground underline-offset-4 hover:text-foreground hover:underline"
          >
            Manage
          </Link>
        )}
        <Link
          to={`/communities/${item.community.id}/community`}
          className="flex items-center gap-1 rounded-lg border border-border px-3 py-1.5 text-xs font-medium text-foreground transition-colors hover:bg-muted"
        >
          Open
          <ArrowRight className="h-3.5 w-3.5" />
        </Link>
      </div>
    </div>
  )
}

function RowSkeleton() {
  return (
    <div className="flex items-center gap-4 rounded-xl border border-border bg-card p-4">
      <div className="h-10 w-10 animate-pulse rounded-lg bg-muted" />
      <div className="flex-1 space-y-2">
        <div className="h-4 w-40 animate-pulse rounded bg-muted" />
        <div className="h-3 w-56 animate-pulse rounded bg-muted" />
      </div>
    </div>
  )
}

export function MyCommunitiesPage() {
  const [roleFilter, setRoleFilter] = useState<RoleFilter>('ALL')

  const { data, isLoading, isError } = useQuery({
    queryKey: ['my-communities'],
    queryFn: userApi.getMyCommunities,
  })

  const communities = data?.data?.communities ?? []

  const counts: Record<RoleFilter, number> = {
    ALL: communities.length,
    CREATOR: communities.filter((c) => c.role === 'creator' || c.role === 'admin').length,
    MEMBER: communities.filter((c) => c.role === 'member').length,
  }

  const filtered =
    roleFilter === 'ALL'
      ? communities
      : roleFilter === 'CREATOR'
      ? communities.filter((c) => c.role === 'creator' || c.role === 'admin')
      : communities.filter((c) => c.role === 'member')

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-semibold text-foreground">My Communities</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Communities you are an active member of.
        </p>
      </div>

      {/* Filter tabs */}
      {!isLoading && !isError && communities.length > 0 && (
        <div className="flex items-center gap-1 border-b border-border">
          {FILTER_TABS.map((tab) => {
            const isActive = roleFilter === tab.value
            return (
              <button
                key={tab.value}
                onClick={() => setRoleFilter(tab.value)}
                className={`relative flex items-center gap-1.5 px-3 py-2 text-sm font-medium transition-colors ${
                  isActive ? 'text-foreground' : 'text-muted-foreground hover:text-foreground'
                }`}
              >
                {tab.label}
                <span
                  className={`rounded-full px-1.5 py-0.5 text-xs ${
                    isActive ? 'bg-primary/15 text-primary' : 'bg-muted text-muted-foreground'
                  }`}
                >
                  {counts[tab.value]}
                </span>
                {isActive && (
                  <span className="absolute inset-x-0 bottom-0 h-0.5 rounded-full bg-primary" />
                )}
              </button>
            )
          })}
        </div>
      )}

      <div className="space-y-3">
        {isError && (
          <p className="py-8 text-center text-sm text-destructive">
            Failed to load communities. Please try again.
          </p>
        )}

        {isLoading && Array.from({ length: 3 }).map((_, i) => <RowSkeleton key={i} />)}

        {!isLoading && !isError && communities.length === 0 && (
          <div className="rounded-xl border border-border bg-card py-12 text-center">
            <p className="text-sm text-muted-foreground">
              You haven't joined any communities yet.
            </p>
            <Link
              to="/communities"
              className="mt-2 inline-block text-sm text-primary hover:underline"
            >
              Browse communities
            </Link>
          </div>
        )}

        {!isLoading && !isError && filtered.length === 0 && communities.length > 0 && (
          <p className="py-8 text-center text-sm text-muted-foreground">
            No communities in this category.
          </p>
        )}

        {!isLoading &&
          !isError &&
          filtered.map((item) => <CommunityRow key={item.membershipId} item={item} />)}
      </div>
    </div>
  )
}
