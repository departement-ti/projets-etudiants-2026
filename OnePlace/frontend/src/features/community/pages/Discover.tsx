import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Search } from 'lucide-react'
import { useQuery } from '@tanstack/react-query'
import { PublicNav } from '@/components/shared/PublicNav'
import { CommunityCard } from '../components/CommunityCard'
import { communityApi } from '@/api/community'
import { Pagination } from '@/components/ui/pagination'

function CardSkeleton() {
  return (
    <div className="overflow-hidden rounded-xl border border-border bg-card">
      <div className="h-44 w-full animate-pulse bg-muted" />
      <div className="p-4 space-y-3">
        <div className="flex items-center gap-3">
          <div className="h-10 w-10 animate-pulse rounded-lg bg-muted" />
          <div className="h-4 w-32 animate-pulse rounded bg-muted" />
        </div>
        <div className="space-y-2">
          <div className="h-3 w-full animate-pulse rounded bg-muted" />
          <div className="h-3 w-3/4 animate-pulse rounded bg-muted" />
        </div>
        <div className="h-3 w-24 animate-pulse rounded bg-muted" />
      </div>
    </div>
  )
}

export function Discover() {
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)

  const { data, isLoading, isError } = useQuery({
    queryKey: ['communities', page],
    queryFn: () => communityApi.list(page, 30),
  })

  const communities = data?.data?.communities ?? []
  const totalPages = data?.data?.totalPages ?? 1

  const filtered = search.trim()
    ? communities.filter(
        (c) =>
          c.name.toLowerCase().includes(search.toLowerCase()) ||
          c.description?.toLowerCase().includes(search.toLowerCase()),
      )
    : communities

  function handleSearch(value: string) {
    setSearch(value)
    setPage(1)
  }

  return (
    <div className="min-h-screen bg-background">
      <PublicNav />

      {/* Hero */}
      <div className="mx-auto max-w-3xl px-4 pb-10 pt-16 text-center">
        <h1 className="text-4xl font-bold tracking-tight text-foreground">
          Discover communities
        </h1>
        <p className="mt-3 text-muted-foreground">
          or{' '}
          <Link to="/communities/new" className="font-medium text-primary hover:underline">
            create your own
          </Link>
        </p>

        {/* Search */}
        <div className="relative mx-auto mt-8 max-w-xl">
          <Search className="absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-muted-foreground" />
          <input
            value={search}
            onChange={(e) => handleSearch(e.target.value)}
            placeholder="Search for anything"
            className="w-full rounded-full border border-border bg-muted py-3 pl-12 pr-5 text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-1 focus:ring-offset-background"
          />
        </div>
      </div>

      {/* Grid */}
      <div className="mx-auto max-w-6xl px-4 pb-20">
        {isError && (
          <p className="py-16 text-center text-sm text-destructive">
            Failed to load communities. Please try again.
          </p>
        )}

        {isLoading && (
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {Array.from({ length: 6 }).map((_, i) => (
              <CardSkeleton key={i} />
            ))}
          </div>
        )}

        {!isLoading && !isError && filtered.length === 0 && (
          <p className="py-16 text-center text-sm text-muted-foreground">
            {search ? `No communities found for "${search}"` : 'No communities yet.'}
          </p>
        )}

        {!isLoading && !isError && filtered.length > 0 && (
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {filtered.map((community, i) => (
              <CommunityCard key={community.id} community={community} rank={(page - 1) * 30 + i + 1} />
            ))}
          </div>
        )}

        {!isLoading && !isError && !search && (
          <div className="mt-10">
            <Pagination page={page} totalPages={totalPages} onChange={(p) => { setPage(p); window.scrollTo({ top: 0, behavior: 'smooth' }) }} />
          </div>
        )}
      </div>
    </div>
  )
}
