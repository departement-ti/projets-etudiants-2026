import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { Search, ArrowRight, ChevronUp, ChevronDown, ChevronsUpDown } from 'lucide-react'
import { formatDistanceToNow } from 'date-fns'
import { adminApi } from '@/api/admin'
import type { AdminCommunity } from '@/types/admin'
import { getGradient } from '@/features/community/utils/community.utils'

type PricingFilter = 'ALL' | 'FREE' | 'FREEMIUM' | 'SUBSCRIPTION' | 'ONE_TIME'
type SortKey = 'members' | 'posts' | 'created'
type SortDir = 'asc' | 'desc'

const PRICING_COLORS: Record<string, string> = {
  FREE: 'bg-muted text-muted-foreground',
  FREEMIUM: 'bg-blue-500/10 text-blue-400',
  SUBSCRIPTION: 'bg-violet-500/10 text-violet-400',
  ONE_TIME: 'bg-amber-500/10 text-amber-400',
}

const PLAN_COLORS: Record<string, string> = {
  BASIC: 'bg-muted text-muted-foreground',
  PRO: 'bg-amber-500/10 text-amber-400',
}

const FILTER_TABS: { label: string; value: PricingFilter }[] = [
  { label: 'All', value: 'ALL' },
  { label: 'Free', value: 'FREE' },
  { label: 'Freemium', value: 'FREEMIUM' },
  { label: 'Subscription', value: 'SUBSCRIPTION' },
  { label: 'One-time', value: 'ONE_TIME' },
]

function SortIcon({ col, sortKey, sortDir }: { col: SortKey; sortKey: SortKey; sortDir: SortDir }) {
  if (col !== sortKey) return <ChevronsUpDown className="ml-1 inline h-3 w-3 opacity-40" />
  return sortDir === 'asc'
    ? <ChevronUp className="ml-1 inline h-3 w-3" />
    : <ChevronDown className="ml-1 inline h-3 w-3" />
}

function CommunityRow({ community }: { community: AdminCommunity }) {
  const gradient = getGradient(community.id)

  return (
    <tr className="border-b border-border last:border-0 transition-colors hover:bg-muted/30">
      <td className="py-3 pl-4 pr-4">
        <div className="flex items-center gap-2.5">
          <div
            className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br ${gradient}`}
          >
            <span className="text-xs font-bold text-white">
              {community.name.slice(0, 2).toUpperCase()}
            </span>
          </div>
          <div className="min-w-0">
            <p className="truncate text-sm font-medium text-foreground">{community.name}</p>
            {community.isPrivate && (
              <span className="text-xs text-muted-foreground">Private</span>
            )}
          </div>
        </div>
      </td>

      <td className="py-3 pr-4">
        <p className="text-sm text-foreground">
          {community.creator.firstname} {community.creator.lastname}
        </p>
        <p className="text-xs text-muted-foreground">{community.creator.email}</p>
      </td>

      <td className="py-3 pr-4">
        <span
          className={`rounded-full px-2 py-0.5 text-xs font-medium ${
            PRICING_COLORS[community.pricingModel] ?? 'bg-muted text-muted-foreground'
          }`}
        >
          {community.pricingModel.replace('_', ' ')}
        </span>
      </td>

      <td className="py-3 pr-4">
        <span
          className={`rounded-full px-2 py-0.5 text-xs font-medium ${
            PLAN_COLORS[community.platformPlan] ?? 'bg-muted text-muted-foreground'
          }`}
        >
          {community.platformPlan}
        </span>
      </td>

      <td className="py-3 pr-4 text-sm tabular-nums text-muted-foreground">
        {community._count.memberships}
      </td>

      <td className="py-3 pr-4 text-sm tabular-nums text-muted-foreground">
        {community._count.posts}
      </td>

      <td className="py-3 pr-4 text-xs text-muted-foreground">
        {formatDistanceToNow(new Date(community.createdAt), { addSuffix: true })}
      </td>

      <td className="py-3 pr-4">
        <Link
          to={`/communities/${community.id}/community`}
          className="inline-flex rounded p-1.5 text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
          title="View community"
        >
          <ArrowRight className="h-3.5 w-3.5" />
        </Link>
      </td>
    </tr>
  )
}

export function AdminCommunitiesPage() {
  const [search, setSearch] = useState('')
  const [pricingFilter, setPricingFilter] = useState<PricingFilter>('ALL')
  const [sortKey, setSortKey] = useState<SortKey>('created')
  const [sortDir, setSortDir] = useState<SortDir>('desc')

  const { data, isLoading } = useQuery({
    queryKey: ['admin-communities'],
    queryFn: adminApi.listCommunities,
  })

  const communities = data?.data?.communities ?? []

  function handleSort(key: SortKey) {
    if (sortKey === key) {
      setSortDir((d) => (d === 'asc' ? 'desc' : 'asc'))
    } else {
      setSortKey(key)
      setSortDir('desc')
    }
  }

  const counts: Record<PricingFilter, number> = {
    ALL: communities.length,
    FREE: communities.filter((c) => c.pricingModel === 'FREE').length,
    FREEMIUM: communities.filter((c) => c.pricingModel === 'FREEMIUM').length,
    SUBSCRIPTION: communities.filter((c) => c.pricingModel === 'SUBSCRIPTION').length,
    ONE_TIME: communities.filter((c) => c.pricingModel === 'ONE_TIME').length,
  }

  const filtered = communities
    .filter((c) => pricingFilter === 'ALL' || c.pricingModel === pricingFilter)
    .filter((c) => {
      if (!search.trim()) return true
      const q = search.toLowerCase()
      return (
        c.name.toLowerCase().includes(q) ||
        `${c.creator.firstname} ${c.creator.lastname}`.toLowerCase().includes(q) ||
        c.creator.email.toLowerCase().includes(q)
      )
    })
    .sort((a, b) => {
      let diff = 0
      if (sortKey === 'members') diff = a._count.memberships - b._count.memberships
      if (sortKey === 'posts') diff = a._count.posts - b._count.posts
      if (sortKey === 'created')
        diff = new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()
      return sortDir === 'asc' ? diff : -diff
    })

  const sortableCols: { label: string; key: SortKey }[] = [
    { label: 'Members', key: 'members' },
    { label: 'Posts', key: 'posts' },
    { label: 'Created', key: 'created' },
  ]

  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-semibold text-foreground">Communities</h1>
          <p className="mt-0.5 text-sm text-muted-foreground">{communities.length} total</p>
        </div>
        <div className="relative">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search communities..."
            className="h-9 rounded-lg border border-border bg-background pl-9 pr-3 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-1 focus:ring-offset-background"
          />
        </div>
      </div>

      {/* Filter tabs */}
      <div className="flex items-center gap-1 border-b border-border">
        {FILTER_TABS.map((tab) => {
          const count = counts[tab.value]
          if (tab.value !== 'ALL' && count === 0) return null
          const isActive = pricingFilter === tab.value
          return (
            <button
              key={tab.value}
              onClick={() => setPricingFilter(tab.value)}
              className={`relative flex items-center gap-1.5 px-3 py-2 text-sm font-medium transition-colors ${
                isActive
                  ? 'text-foreground'
                  : 'text-muted-foreground hover:text-foreground'
              }`}
            >
              {tab.label}
              <span
                className={`rounded-full px-1.5 py-0.5 text-xs ${
                  isActive
                    ? 'bg-primary/15 text-primary'
                    : 'bg-muted text-muted-foreground'
                }`}
              >
                {count}
              </span>
              {isActive && (
                <span className="absolute inset-x-0 bottom-0 h-0.5 rounded-full bg-primary" />
              )}
            </button>
          )
        })}
      </div>

      {/* Table */}
      <div className="rounded-xl border border-border bg-card overflow-hidden">
        {isLoading ? (
          <div className="flex h-32 items-center justify-center">
            <div className="h-5 w-5 animate-spin rounded-full border-4 border-border border-t-primary" />
          </div>
        ) : filtered.length === 0 ? (
          <p className="py-10 text-center text-sm text-muted-foreground">
            {search ? `No communities found for "${search}"` : 'No communities yet.'}
          </p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-border bg-muted/40">
                  {['Community', 'Creator', 'Pricing', 'Plan'].map((h) => (
                    <th
                      key={h}
                      className="px-4 py-2.5 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground"
                    >
                      {h}
                    </th>
                  ))}
                  {sortableCols.map(({ label, key }) => (
                    <th
                      key={key}
                      onClick={() => handleSort(key)}
                      className="cursor-pointer select-none px-4 py-2.5 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground hover:text-foreground transition-colors"
                    >
                      {label}
                      <SortIcon col={key} sortKey={sortKey} sortDir={sortDir} />
                    </th>
                  ))}
                  <th className="px-4 py-2.5" />
                </tr>
              </thead>
              <tbody>
                {filtered.map((community) => (
                  <CommunityRow key={community.id} community={community} />
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}
