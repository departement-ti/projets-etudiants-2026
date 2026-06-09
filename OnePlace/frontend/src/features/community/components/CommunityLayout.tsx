import { useState, useEffect, useRef } from 'react'
import { OnePlaceLogo } from '@/components/shared/OnePlaceLogo'
import { NavLink, Navigate, Outlet, Link, useNavigate, useParams, useLocation } from 'react-router-dom'
import { useMutation, useQuery } from '@tanstack/react-query'
import { ChevronDown, ChevronLeft, Send, Sparkles, Trophy, Users, X } from 'lucide-react'
import { cn } from '@/lib/utils'
import { useAuthStore } from '@/store/auth.store'
import { authApi } from '@/api/auth'
import { communityApi } from '@/api/community'
import { leaderboardApi } from '@/api/leaderboard'
import { getMockCommunityDetail, getMockMembership } from '@/mocks/communities.mock'
import { formatCount, getGradient, getPricingLabel } from '../utils/community.utils'
import type { CommunityDetail } from '@/types/community'
import { JoinModal } from './JoinModal'
import { UpgradeModal } from './UpgradeModal'
import { NotificationBell } from '@/components/shared/NotificationBell'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { aiApi, type CommunityMatch, type ChatMessage } from '@/api/ai'

// ─── NavTab ───────────────────────────────────────────────────────────────────

function NavTab({ to, children }: { to: string; children: React.ReactNode }) {
  return (
    <NavLink
      to={to}
      className={({ isActive }) =>
        cn(
          'flex h-10 shrink-0 items-center border-b-2 px-4 text-sm font-medium whitespace-nowrap transition-colors',
          isActive
            ? 'border-primary text-foreground'
            : 'border-transparent text-muted-foreground hover:text-foreground',
        )
      }
    >
      {children}
    </NavLink>
  )
}

// ─── UserMenu ─────────────────────────────────────────────────────────────────

function UserMenu() {
  const { user, clear } = useAuthStore()
  const navigate = useNavigate()

  async function handleSignOut() {
    try {
      await authApi.signOut()
    } finally {
      clear()
      navigate('/sign-in')
    }
  }

  if (!user) return null

  const initials = `${user.firstname[0]}${user.lastname[0]}`.toUpperCase()

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <button className="flex items-center gap-2 rounded-lg px-2 py-1 transition-colors hover:bg-muted focus:outline-none">
          {user.avatarUrl ? (
            <img
              src={user.avatarUrl}
              alt={user.firstname}
              className="h-7 w-7 rounded-full object-cover"
            />
          ) : (
            <div className="flex h-7 w-7 items-center justify-center rounded-full bg-primary text-xs font-bold text-white">
              {initials}
            </div>
          )}
          <span className="hidden text-sm font-medium text-foreground sm:block">
            {user.firstname}
          </span>
          <ChevronDown className="h-3.5 w-3.5 text-muted-foreground" />
        </button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-48">
        <DropdownMenuLabel>
          {user.firstname} {user.lastname}
        </DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuItem asChild>
          <Link to="/profile">Profile</Link>
        </DropdownMenuItem>
        <DropdownMenuSeparator />
        <DropdownMenuItem
          onClick={handleSignOut}
          className="text-destructive focus:text-destructive"
        >
          Sign out
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

// ─── CommunitySidebar ─────────────────────────────────────────────────────────

function CommunitySidebar({ community }: { community: CommunityDetail }) {
  const [joinOpen, setJoinOpen] = useState(false)
  const [upgradeOpen, setUpgradeOpen] = useState(false)
  const { user } = useAuthStore()
  const navigate = useNavigate()
  const location = useLocation()
  const isMock = community.id.startsWith('mock-')

  const { data: membershipData } = useQuery({
    queryKey: ['membership', community.id],
    queryFn: () => communityApi.getMyMembership(community.id),
    enabled: !isMock,
  })

  const membership = isMock
    ? getMockMembership(community.id)
    : membershipData?.data?.membership

  const isCreatorOrAdmin = membership?.role === 'creator' || membership?.role === 'admin'
  const isActiveMember = membership?.status === 'ACTIVE' || isCreatorOrAdmin
  const isFreeTierInFreemium =
    isActiveMember &&
    community.pricingModel === 'FREEMIUM' &&
    membership?.membershipTier === 'FREE'

  const gradient = getGradient(community.id)

  return (
    <div className="rounded-xl border border-border bg-card p-5">
      {/* Avatar + name */}
      <div className="mb-4 flex items-center gap-3">
        <div
          className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-lg overflow-hidden ${community.iconUrl ? '' : `bg-gradient-to-br ${gradient}`}`}
        >
          {community.iconUrl ? (
            <img src={community.iconUrl} alt="" className="h-full w-full object-cover" />
          ) : (
            <span className="text-sm font-bold text-white">
              {community.name.slice(0, 2).toUpperCase()}
            </span>
          )}
        </div>
        <div className="min-w-0">
          <p className="truncate text-sm font-semibold text-foreground">{community.name}</p>
          <p className="text-xs text-muted-foreground">
            By {community.creator.firstname} {community.creator.lastname}
          </p>
        </div>
      </div>

      {/* Description */}
      {community.description && (
        <p className="mb-4 line-clamp-4 text-xs leading-relaxed text-muted-foreground">
          {community.description}
        </p>
      )}

      {/* Stats */}
      <div className="mb-4 flex gap-5 border-t border-border pt-4">
        <div>
          <p className="text-sm font-semibold text-foreground">
            {formatCount(community._count.memberships)}
          </p>
          <p className="text-xs text-muted-foreground">Members</p>
        </div>
        <div>
          <p className="text-sm font-semibold text-foreground">
            {formatCount(community._count.posts)}
          </p>
          <p className="text-xs text-muted-foreground">Posts</p>
        </div>
      </div>

      {/* Pricing badge */}
      <span className="inline-flex items-center rounded-full border border-border bg-muted px-2.5 py-0.5 text-xs font-medium text-foreground/80">
        {getPricingLabel(community.pricingModel, community.pricing)}
      </span>

      {/* Join / Upgrade action */}
      {!isActiveMember && (
        <Button
          size="sm"
          className="mt-4 w-full"
          onClick={() => {
            if (!user) {
              navigate('/sign-in', { state: { from: location.pathname } })
              return
            }
            setJoinOpen(true)
          }}
        >
          Join
        </Button>
      )}
      {isFreeTierInFreemium && (
        <Button
          size="sm"
          variant="outline"
          className="mt-4 w-full"
          onClick={() => setUpgradeOpen(true)}
        >
          Upgrade
        </Button>
      )}

      <JoinModal open={joinOpen} onOpenChange={setJoinOpen} community={community} />
      <UpgradeModal open={upgradeOpen} onOpenChange={setUpgradeOpen} community={community} />
    </div>
  )
}

// ─── LeaderboardSidebar ───────────────────────────────────────────────────────

const RANK_COLORS = ['text-amber-400', 'text-slate-400', 'text-amber-700']
const RANK_MEDALS = ['🥇', '🥈', '🥉']

function LeaderboardSidebar({ communityId, isActiveMember }: { communityId: string; isActiveMember: boolean }) {
  const isMock = communityId.startsWith('mock-')

  const { data, isLoading } = useQuery({
    queryKey: ['leaderboard', communityId],
    queryFn: () => leaderboardApi.get(communityId),
    enabled: !isMock && isActiveMember,
    staleTime: 60_000,
  })

  const top5 = data?.data?.leaderboardAllTime?.slice(0, 5) ?? []

  if (!isActiveMember || isMock) return null

  return (
    <div className="rounded-xl border border-border bg-card p-5">
      <div className="mb-4 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Trophy className="h-4 w-4 text-amber-400" />
          <span className="text-sm font-semibold text-foreground">Leaderboard</span>
        </div>
        <NavLink
          to={`/communities/${communityId}/leaderboards`}
          className="text-xs text-primary hover:underline"
        >
          View all
        </NavLink>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-4">
          <div className="h-5 w-5 animate-spin rounded-full border-2 border-border border-t-primary" />
        </div>
      ) : top5.length === 0 ? (
        <p className="py-4 text-center text-xs text-muted-foreground">No points yet. Be the first!</p>
      ) : (
        <ol className="space-y-2.5">
          {top5.map((entry) => {
            const initials = `${entry.firstname[0]}${entry.lastname[0]}`.toUpperCase()
            return (
              <li key={entry.userId} className="flex items-center gap-2">
                <span className={cn('w-5 shrink-0 text-center text-sm', RANK_COLORS[entry.rank - 1])}>
                  {entry.rank <= 3 ? RANK_MEDALS[entry.rank - 1] : entry.rank}
                </span>
                {entry.avatarUrl ? (
                  <img
                    src={entry.avatarUrl}
                    alt={entry.firstname}
                    className="h-6 w-6 shrink-0 rounded-full object-cover"
                  />
                ) : (
                  <div className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-primary text-[10px] font-bold text-white">
                    {initials}
                  </div>
                )}
                <span className="min-w-0 flex-1 truncate text-sm text-foreground">
                  {entry.firstname} {entry.lastname}
                </span>
                <span className="shrink-0 text-xs font-medium text-muted-foreground">
                  {entry.points} pts
                </span>
              </li>
            )
          })}
        </ol>
      )}
    </div>
  )
}

// ─── MatchmakingSidebar ───────────────────────────────────────────────────────

function getPricingBadge(model: string) {
  if (model === 'FREE') return 'Free'
  if (model === 'FREEMIUM') return 'Freemium'
  if (model === 'SUBSCRIPTION') return 'Subscription'
  if (model === 'ONE_TIME') return 'One-time'
  return model
}

function MatchmakingSidebar() {
  const { data, isLoading } = useQuery({
    queryKey: ['ai-matchmaking'],
    queryFn: () => aiApi.getMatchmaking(),
    staleTime: 15 * 60 * 1000,
  })

  const matches = (data?.data?.matches ?? []) as CommunityMatch[]

  return (
    <div className="rounded-xl border border-border bg-card p-5">
      <div className="mb-4 flex items-center gap-2">
        <Sparkles className="h-4 w-4 text-primary" />
        <span className="text-sm font-semibold text-foreground">Recommended for you</span>
      </div>

      {isLoading ? (
        <div className="space-y-3">
          {[1, 2, 3].map((i) => (
            <div key={i} className="animate-pulse space-y-1.5">
              <div className="h-3.5 w-3/4 rounded bg-muted" />
              <div className="h-3 w-full rounded bg-muted" />
            </div>
          ))}
        </div>
      ) : matches.length === 0 ? (
        <p className="py-2 text-center text-xs text-muted-foreground">No recommendations yet.</p>
      ) : (
        <div className="space-y-3">
          {matches.map((m) => (
            <Link
              key={m.id}
              to={`/communities/${m.id}/about`}
              className="block rounded-lg border border-border p-3 transition-colors hover:bg-muted"
            >
              <div className="flex items-start justify-between gap-2">
                <p className="text-xs font-semibold text-foreground leading-snug">{m.name}</p>
                <span className="shrink-0 rounded-full bg-muted px-2 py-0.5 text-[10px] text-muted-foreground">
                  {getPricingBadge(m.pricingModel)}
                </span>
              </div>
              <p className="mt-1 text-[11px] text-muted-foreground italic leading-snug">{m.reason}</p>
              <div className="mt-1.5 flex items-center gap-1 text-[11px] text-muted-foreground">
                <Users className="h-3 w-3" />
                {m.memberCount.toLocaleString()} members
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  )
}

// ─── QAChatWidget ─────────────────────────────────────────────────────────────

function QAChatWidget({
  communityId,
  iconUrl,
  name,
}: {
  communityId: string
  iconUrl?: string | null
  name: string
}) {
  const [open, setOpen] = useState(false)
  const [input, setInput] = useState('')
  const [messages, setMessages] = useState<ChatMessage[]>([])
  const bottomRef = useRef<HTMLDivElement>(null)
  const gradient = getGradient(communityId)
  const initials = name.slice(0, 2).toUpperCase()

  const { mutate: ask, isPending } = useMutation({
    mutationFn: () => aiApi.askCommunity(communityId, input.trim(), messages),
    onSuccess: (res) => {
      const answer = res.data?.answer ?? 'Sorry, no response.'
      setMessages((prev) => [...prev, { role: 'assistant', content: answer }])
    },
    onError: () => {
      setMessages((prev) => [
        ...prev,
        { role: 'assistant', content: 'Something went wrong. Please try again.' },
      ])
    },
  })

  function submit() {
    const q = input.trim()
    if (!q || isPending) return
    setMessages((prev) => [...prev, { role: 'user', content: q }])
    setInput('')
    ask()
  }

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, isPending])

  return (
    <>
      {/* Floating button */}
      <button
        onClick={() => setOpen((v) => !v)}
        className="fixed bottom-6 right-6 z-50 flex h-16 w-16 items-center justify-center rounded-full shadow-xl ring-2 ring-border transition-transform hover:scale-105 active:scale-95 overflow-hidden"
        title="Ask AI"
      >
        {open ? (
          <div className={`flex h-full w-full items-center justify-center bg-gradient-to-br ${gradient}`}>
            <X className="h-6 w-6 text-white" />
          </div>
        ) : iconUrl ? (
          <img src={iconUrl} alt={name} className="h-full w-full object-cover" />
        ) : (
          <div className={`flex h-full w-full items-center justify-center bg-gradient-to-br ${gradient}`}>
            <span className="text-lg font-bold text-white">{initials}</span>
          </div>
        )}
      </button>

      {/* Chat panel */}
      {open && (
        <div className="fixed bottom-24 right-6 z-50 flex w-80 flex-col rounded-2xl border border-border bg-card shadow-2xl overflow-hidden">
          {/* Header */}
          <div className="flex items-center gap-3 px-4 py-3 border-b border-border">
            <div className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-full overflow-hidden ${iconUrl ? '' : `bg-gradient-to-br ${gradient}`}`}>
              {iconUrl
                ? <img src={iconUrl} alt={name} className="h-full w-full object-cover" />
                : <span className="text-xs font-bold text-white">{initials}</span>
              }
            </div>
            <div className="min-w-0">
              <p className="text-sm font-semibold text-foreground truncate">{name}</p>
              <p className="text-xs text-muted-foreground">Ask anything · powered by AI</p>
            </div>
          </div>

          {/* Messages */}
          <div className="flex-1 overflow-y-auto p-3 space-y-3 max-h-80">
            {messages.length === 0 && (
              <p className="py-6 text-center text-xs text-muted-foreground">
                Ask anything about this community's posts and lessons.
              </p>
            )}
            {messages.map((m, i) => (
              <div
                key={i}
                className={`flex ${m.role === 'user' ? 'justify-end' : 'justify-start'}`}
              >
                <div
                  className={`max-w-[85%] rounded-2xl px-3 py-2 text-xs leading-relaxed ${
                    m.role === 'user'
                      ? 'bg-primary text-white rounded-br-sm'
                      : 'bg-muted text-foreground rounded-bl-sm'
                  }`}
                >
                  {m.content}
                </div>
              </div>
            ))}
            {isPending && (
              <div className="flex justify-start">
                <div className="flex items-center gap-1 rounded-2xl rounded-bl-sm bg-muted px-3 py-2">
                  {[0, 1, 2].map((i) => (
                    <div
                      key={i}
                      className="h-1.5 w-1.5 rounded-full bg-muted-foreground animate-bounce"
                      style={{ animationDelay: `${i * 150}ms` }}
                    />
                  ))}
                </div>
              </div>
            )}
            <div ref={bottomRef} />
          </div>

          {/* Input */}
          <div className="flex items-center gap-2 border-t border-border px-3 py-2">
            <input
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); submit() } }}
              placeholder="Ask a question..."
              className="flex-1 bg-transparent text-xs text-foreground placeholder:text-muted-foreground/60 focus:outline-none"
            />
            <button
              onClick={submit}
              disabled={!input.trim() || isPending}
              className="flex h-7 w-7 items-center justify-center rounded-full bg-primary text-white disabled:opacity-40"
            >
              <Send className="h-3.5 w-3.5" />
            </button>
          </div>
        </div>
      )}
    </>
  )
}

// ─── CommunityLayout ──────────────────────────────────────────────────────────

export function CommunityLayout() {
  const { id } = useParams<{ id: string }>()
  const { user } = useAuthStore()
  const location = useLocation()
  const hideSidebar =
    location.pathname.includes('/classroom') || location.pathname.includes('/analytics')

  const mockCommunity = getMockCommunityDetail(id ?? '')

  const { data, isLoading } = useQuery({
    queryKey: ['community', id],
    queryFn: () => communityApi.getById(id!),
    enabled: !!id && !mockCommunity,
  })

  const { data: membershipData } = useQuery({
    queryKey: ['membership', id],
    queryFn: () => communityApi.getMyMembership(id!),
    enabled: !!id && !mockCommunity,
  })

  const memberRole = membershipData?.data?.membership?.role
  const canViewAnalytics = memberRole === 'creator' || memberRole === 'admin'

  const community: CommunityDetail | undefined = mockCommunity ?? data?.data?.community

  useEffect(() => {
    if (community && id) {
      localStorage.setItem('lastCommunityId', id)
    }
  }, [community, id])

  if (isLoading) {
    return (
      <div className="flex h-screen items-center justify-center bg-background">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-border border-t-primary" />
      </div>
    )
  }

  if (!community) return <Navigate to="/communities" replace />

  return (
    <div className="min-h-screen bg-background">
      {/* ── Header ── */}
      <header className="sticky top-0 z-50 border-b border-border bg-background/90 backdrop-blur-md">
        <div className="mx-auto max-w-7xl px-4">
          {/* Top row: logo + community name + user menu */}
          <div className="flex h-14 items-center justify-between gap-4">
            <div className="flex min-w-0 items-center gap-3">
              <Link
                to="/communities"
                className="flex shrink-0 items-center gap-1 text-muted-foreground transition-colors hover:text-foreground"
              >
                <ChevronLeft className="h-4 w-4" />
                <div className="flex h-6 w-6 items-center justify-center rounded-md bg-primary">
                  <OnePlaceLogo className="h-3.5 w-3.5 text-white" />
                </div>
              </Link>
              <div className="h-5 w-px shrink-0 bg-border" />
              <span className="truncate font-semibold text-foreground">{community.name}</span>
            </div>
            <div className="flex items-center gap-1">
              <NotificationBell />
              <UserMenu />
            </div>
          </div>

          {/* Tabs row */}
          <div className="-mb-px flex overflow-x-auto">
            <NavTab to={`/communities/${id}/community`}>Community</NavTab>
            <NavTab to={`/communities/${id}/classroom`}>Classroom</NavTab>
            <NavTab to={`/communities/${id}/calendar`}>Calendar</NavTab>
            <NavTab to={`/communities/${id}/members`}>Members</NavTab>
            <NavTab to={`/communities/${id}/leaderboards`}>Leaderboards</NavTab>
            <NavTab to={`/communities/${id}/about`}>About</NavTab>
            {canViewAnalytics && (
              <NavTab to={`/communities/${id}/analytics`}>Analytics</NavTab>
            )}
            {community.creator.id === user?.id && (
              <NavTab to={`/communities/${id}/settings/general`}>Settings</NavTab>
            )}
          </div>
        </div>
      </header>

      {/* ── Floating Q&A bot ── */}
      <QAChatWidget communityId={id!} iconUrl={community.iconUrl} name={community.name} />

      {/* ── Body ── */}
      <div className="mx-auto max-w-7xl px-4 py-6">
        <div className="flex gap-6">
          {/* Main content */}
          <main className="min-w-0 flex-1">
            <Outlet />
          </main>

          {/* Sidebar */}
          {!hideSidebar && (
            <aside className="hidden w-72 shrink-0 space-y-4 lg:block">
              <CommunitySidebar community={community} />
              <LeaderboardSidebar
                communityId={id!}
                isActiveMember={
                  membershipData?.data?.membership?.status === 'ACTIVE' ||
                  membershipData?.data?.membership?.role === 'creator' ||
                  membershipData?.data?.membership?.role === 'admin'
                }
              />
              <MatchmakingSidebar />
            </aside>
          )}
        </div>
      </div>
    </div>
  )
}
