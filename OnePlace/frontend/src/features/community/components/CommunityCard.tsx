import { Link } from 'react-router-dom'
import { Users } from 'lucide-react'
import type { CommunityListItem } from '@/types/community'
import { formatCount, getGradient, getPricingLabel } from '../utils/community.utils'

interface CommunityCardProps {
  community: CommunityListItem
  rank: number
}

export function CommunityCard({ community, rank }: CommunityCardProps) {
  const gradient = getGradient(community.id)
  const initials = community.name.slice(0, 2).toUpperCase()

  return (
    <Link
      to={`/communities/${community.id}/about`}
      className="group flex flex-col overflow-hidden rounded-xl border border-border bg-card transition-all duration-200 hover:-translate-y-0.5 hover:border-primary/40 hover:shadow-lg hover:shadow-primary/10"
    >
      {/* Banner */}
      <div className={`relative h-44 w-full overflow-hidden ${community.coverUrl ? '' : `bg-gradient-to-br ${gradient}`}`}>
        {community.coverUrl ? (
          <img src={community.coverUrl} alt="" className="h-full w-full object-cover" />
        ) : null}
        {rank <= 10 && (
          <span className="absolute left-3 top-3 flex h-7 w-7 items-center justify-center rounded-full bg-black/50 text-xs font-bold text-white backdrop-blur-sm">
            #{rank}
          </span>
        )}
      </div>

      {/* Body */}
      <div className="flex flex-1 flex-col p-4">
        {/* Avatar + name */}
        <div className="mb-3 flex items-center gap-3">
          <div
            className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-lg overflow-hidden ${community.iconUrl ? '' : `bg-gradient-to-br ${gradient}`}`}
          >
            {community.iconUrl ? (
              <img src={community.iconUrl} alt="" className="h-full w-full object-cover" />
            ) : (
              <span className="text-sm font-bold text-white">{initials}</span>
            )}
          </div>
          <h3 className="truncate font-semibold text-foreground group-hover:text-primary transition-colors">
            {community.name}
          </h3>
        </div>

        {/* Description */}
        <p className="mb-4 line-clamp-2 flex-1 text-sm text-muted-foreground">
          {community.description ?? 'No description yet.'}
        </p>

        {/* Footer */}
        <div className="flex items-center gap-1 text-xs text-muted-foreground">
          <Users className="h-3.5 w-3.5" />
          <span>{formatCount(community._count.memberships)} Members</span>
          <span className="mx-1">·</span>
          <span className="font-medium text-foreground/70">
            {getPricingLabel(community.pricingModel)}
          </span>
        </div>
      </div>
    </Link>
  )
}
