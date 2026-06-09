import { useParams } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { format } from 'date-fns'
import { Lock } from 'lucide-react'
import { cn } from '@/lib/utils'
import { leaderboardApi } from '@/api/leaderboard'
import { useAuthStore } from '@/store/auth.store'
import type { LeaderboardEntry, LevelDistribution } from '@/types/leaderboard'

// ─── Level feature unlocks (static config) ────────────────────────────────────

const LEVEL_FEATURES: Record<number, string> = {
  2: 'Post to feed',
  5: 'Access locked courses',
  9: 'Chat with members',
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function initials(firstname: string, lastname: string) {
  return `${firstname[0] ?? ''}${lastname[0] ?? ''}`.toUpperCase()
}

function Avatar({ firstname, lastname, size = 'md' }: { firstname: string; lastname: string; size?: 'sm' | 'md' | 'lg' }) {
  const cls = {
    sm: 'h-8 w-8 text-xs',
    md: 'h-10 w-10 text-sm',
    lg: 'h-20 w-20 text-2xl',
  }[size]

  return (
    <div className={cn('flex items-center justify-center rounded-full bg-primary font-bold text-white', cls)}>
      {initials(firstname, lastname)}
    </div>
  )
}

// ─── Rank medal ───────────────────────────────────────────────────────────────

function RankBadge({ rank }: { rank: number }) {
  const base = 'flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-sm font-bold'
  if (rank === 1) return <span className={cn(base, 'bg-amber-400 text-white')}>1</span>
  if (rank === 2) return <span className={cn(base, 'bg-slate-400 text-white')}>2</span>
  if (rank === 3) return <span className={cn(base, 'bg-amber-700 text-white')}>3</span>
  return <span className={cn(base, 'bg-muted text-muted-foreground text-xs')}>{rank}</span>
}

// ─── Single leaderboard column ────────────────────────────────────────────────

function LeaderboardColumn({ title, entries }: { title: string; entries: LeaderboardEntry[] }) {
  return (
    <div className="rounded-xl border border-border bg-card p-4">
      <h3 className="mb-3 text-sm font-semibold text-foreground">{title}</h3>
      {entries.length === 0 ? (
        <p className="py-6 text-center text-xs text-muted-foreground">No activity yet</p>
      ) : (
        <div className="space-y-3">
          {entries.map((e) => (
            <div key={e.userId} className="flex items-center gap-3">
              <RankBadge rank={e.rank} />
              <Avatar firstname={e.firstname} lastname={e.lastname} size="sm" />
              <span className="min-w-0 flex-1 truncate text-sm font-medium text-foreground">
                {e.firstname} {e.lastname}
              </span>
              <span className="shrink-0 text-sm font-semibold text-primary">
                +{e.points.toLocaleString()}
              </span>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

// ─── Level grid item ──────────────────────────────────────────────────────────

function LevelItem({
  dist,
  isUnlocked,
  isCurrent,
}: {
  dist: LevelDistribution
  isUnlocked: boolean
  isCurrent: boolean
}) {
  const feature = LEVEL_FEATURES[dist.level]

  return (
    <div className="flex items-start gap-3">
      {/* Icon */}
      <div
        className={cn(
          'flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-sm font-bold',
          isCurrent
            ? 'bg-amber-400 text-white'
            : isUnlocked
            ? 'bg-primary/20 text-primary'
            : 'bg-muted text-muted-foreground',
        )}
      >
        {isUnlocked ? dist.level : <Lock className="h-4 w-4" />}
      </div>

      {/* Info */}
      <div className="min-w-0">
        <p className="text-sm font-medium text-foreground">Level {dist.level}</p>
        <p className="text-xs text-muted-foreground">
          {feature && (
            <>
              Unlock{' '}
              <span className="font-medium text-primary">{feature}</span>{' '}
            </>
          )}
          {dist.percentage}% of members
        </p>
      </div>
    </div>
  )
}

// ─── LeaderboardPage ──────────────────────────────────────────────────────────

export function LeaderboardPage() {
  const { id: communityId } = useParams<{ id: string }>()
  const { user } = useAuthStore()

  const { data, isLoading } = useQuery({
    queryKey: ['leaderboard', communityId],
    queryFn: () => leaderboardApi.get(communityId!),
    enabled: !!communityId,
    refetchInterval: 60_000,
  })

  if (isLoading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="h-6 w-6 animate-spin rounded-full border-2 border-border border-t-primary" />
      </div>
    )
  }

  const d = data?.data
  if (!d) return null

  const { userStats, levelDistribution, leaderboard7d, leaderboard30d, leaderboardAllTime, lastUpdated } = d

  const half = Math.ceil(levelDistribution.length / 2)
  const leftLevels = levelDistribution.slice(0, half)
  const rightLevels = levelDistribution.slice(half)

  return (
    <div className="space-y-6">
      {/* ── User stats card ── */}
      <div className="rounded-xl border border-border bg-card p-6">
        <div className="flex flex-col items-start gap-6 sm:flex-row">
          {/* Avatar + name */}
          <div className="flex flex-col items-center gap-2 sm:w-48">
            <div className="relative">
              <div className="h-28 w-28 rounded-full ring-4 ring-border overflow-hidden flex items-center justify-center bg-primary text-4xl font-bold text-white">
                {user ? initials(user.firstname, user.lastname) : '?'}
              </div>
              {/* Level badge */}
              <div className="absolute -bottom-1 -right-1 flex h-9 w-9 items-center justify-center rounded-full bg-primary text-sm font-bold text-white ring-2 ring-card">
                {userStats.level}
              </div>
            </div>
            <p className="text-base font-bold text-foreground">
              {user?.firstname} {user?.lastname}
            </p>
            <p className="text-sm font-semibold text-primary">Level {userStats.level}</p>
            {userStats.pointsToNextLevel !== null ? (
              <p className="text-xs text-muted-foreground">
                <span className="font-semibold text-foreground">{userStats.pointsToNextLevel}</span>{' '}
                points to level up
              </p>
            ) : (
              <p className="text-xs font-medium text-amber-400">Max level reached!</p>
            )}
          </div>

          {/* Level grid */}
          <div className="flex-1 grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div className="space-y-4">
              {leftLevels.map((dist) => (
                <LevelItem
                  key={dist.level}
                  dist={dist}
                  isUnlocked={userStats.level >= dist.level}
                  isCurrent={userStats.level === dist.level}
                />
              ))}
            </div>
            <div className="space-y-4">
              {rightLevels.map((dist) => (
                <LevelItem
                  key={dist.level}
                  dist={dist}
                  isUnlocked={userStats.level >= dist.level}
                  isCurrent={userStats.level === dist.level}
                />
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* ── Last updated ── */}
      <p className="text-xs text-muted-foreground">
        Last updated:{' '}
        {format(new Date(lastUpdated), "MMM do yyyy h:mma")}
      </p>

      {/* ── Three leaderboards ── */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <LeaderboardColumn title="Leaderboard (7-day)" entries={leaderboard7d} />
        <LeaderboardColumn title="Leaderboard (30-day)" entries={leaderboard30d} />
        <LeaderboardColumn title="Leaderboard (all-time)" entries={leaderboardAllTime} />
      </div>
    </div>
  )
}
