import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { Search, Crown, Shield, User } from 'lucide-react'
import { communityApi } from '@/api/community'
import { Input } from '@/components/ui/input'
import { cn } from '@/lib/utils'
import type { CommunityMember, MembershipRole } from '@/types/community'

// ─── Role helpers ──────────────────────────────────────────────────────────────

const ROLE_ORDER: Record<MembershipRole, number> = { creator: 0, admin: 1, member: 2 }

function RoleBadge({ role }: { role: MembershipRole }) {
  if (role === 'creator')
    return (
      <span className="inline-flex items-center gap-1 rounded-full bg-amber-500/15 px-2 py-0.5 text-xs font-medium text-amber-500">
        <Crown className="h-3 w-3" />
        Creator
      </span>
    )
  if (role === 'admin')
    return (
      <span className="inline-flex items-center gap-1 rounded-full bg-primary/15 px-2 py-0.5 text-xs font-medium text-primary">
        <Shield className="h-3 w-3" />
        Admin
      </span>
    )
  return (
    <span className="inline-flex items-center gap-1 rounded-full bg-muted px-2 py-0.5 text-xs font-medium text-muted-foreground">
      <User className="h-3 w-3" />
      Member
    </span>
  )
}

// ─── MemberCard ────────────────────────────────────────────────────────────────

function MemberCard({ member }: { member: CommunityMember }) {
  const initials = `${member.user.firstname[0]}${member.user.lastname[0]}`.toUpperCase()
  const joinDate = new Date(member.joinedAt).toLocaleDateString('en-US', {
    month: 'short',
    year: 'numeric',
  })

  return (
    <div className="flex items-center gap-3 rounded-xl border border-border bg-card p-4">
      {member.user.avatarUrl ? (
        <img
          src={member.user.avatarUrl}
          alt={member.user.firstname}
          className="h-10 w-10 shrink-0 rounded-full object-cover"
        />
      ) : (
        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary text-sm font-bold text-white">
          {initials}
        </div>
      )}

      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-semibold text-foreground">
          {member.user.firstname} {member.user.lastname}
        </p>
        <p className="text-xs text-muted-foreground">Joined {joinDate}</p>
      </div>

      <div className="flex shrink-0 flex-col items-end gap-1">
        <RoleBadge role={member.role} />
        {member.membershipTier === 'PAID' && (
          <span className="rounded-full bg-emerald-500/15 px-2 py-0.5 text-xs font-medium text-emerald-500">
            Paid
          </span>
        )}
      </div>
    </div>
  )
}

// ─── Members page ──────────────────────────────────────────────────────────────

export function Members() {
  const { id } = useParams<{ id: string }>()
  const [search, setSearch] = useState('')

  const { data, isLoading } = useQuery({
    queryKey: ['community-members', id],
    queryFn: () => communityApi.getMembers(id!),
    enabled: !!id,
  })

  const members = data?.data?.members ?? []

  const filtered = members
    .filter((m) => {
      if (!search) return true
      const full = `${m.user.firstname} ${m.user.lastname}`.toLowerCase()
      return full.includes(search.toLowerCase())
    })
    .sort((a, b) => ROLE_ORDER[a.role] - ROLE_ORDER[b.role])

  if (isLoading) {
    return (
      <div className="flex justify-center py-20">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-border border-t-primary" />
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted-foreground">
          {members.length} {members.length === 1 ? 'member' : 'members'}
        </p>
        <div className="relative w-56">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Search members…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9"
          />
        </div>
      </div>

      {/* List */}
      {filtered.length === 0 ? (
        <div className={cn(
          'flex flex-col items-center justify-center rounded-xl border border-border bg-card py-20 text-center',
        )}>
          <p className="font-semibold text-foreground">No members found</p>
          <p className="mt-1 text-sm text-muted-foreground">
            {search ? 'Try a different search.' : 'No active members yet.'}
          </p>
        </div>
      ) : (
        <div className="grid gap-3 sm:grid-cols-2">
          {filtered.map((m) => (
            <MemberCard key={m.id} member={m} />
          ))}
        </div>
      )}
    </div>
  )
}
