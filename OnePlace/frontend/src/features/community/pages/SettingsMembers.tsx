import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Download, Shield, ShieldOff, UserMinus, UserPlus } from 'lucide-react'
import { toast } from 'sonner'
import { formatDistanceToNow } from 'date-fns'
import { membershipApi } from '@/api/membership'
import { useAuthStore } from '@/store/auth.store'
import { communityApi } from '@/api/community'
import type { CommunityMember } from '@/types/membership'
import { Button } from '@/components/ui/button'
import { ConfirmModal } from '@/components/ui/confirm-modal'

// ─── Status/Role badges ───────────────────────────────────────────────────────

function RoleBadge({ role }: { role: CommunityMember['role'] }) {
  const map = {
    creator: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
    admin: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
    member: 'bg-muted text-muted-foreground',
  }
  return (
    <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${map[role]}`}>
      {role}
    </span>
  )
}

function StatusBadge({ status }: { status: CommunityMember['status'] }) {
  const map = {
    ACTIVE: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400',
    BANNED: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400',
    CANCELLED: 'bg-muted text-muted-foreground',
    EXPIRED: 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400',
  }
  return (
    <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${map[status]}`}>
      {status}
    </span>
  )
}

// ─── MemberRow ────────────────────────────────────────────────────────────────

function MemberRow({
  member,
  communityId,
  isCreator,
  isAdmin,
}: {
  member: CommunityMember
  communityId: string
  isCreator: boolean
  isAdmin: boolean
}) {
  const queryClient = useQueryClient()
  const [confirmBan, setConfirmBan] = useState(false)
  const invalidate = () =>
    queryClient.invalidateQueries({ queryKey: ['settings-members', communityId] })

  const { mutate: ban, isPending: banning } = useMutation({
    mutationFn: () => membershipApi.ban(communityId, member.userId),
    onSuccess: () => { invalidate(); toast.success(`${member.user.firstname} banned`) },
    onError: (err) => toast.error((err as Error).message),
  })
  const { mutate: unban, isPending: unbanning } = useMutation({
    mutationFn: () => membershipApi.unban(communityId, member.userId),
    onSuccess: () => { invalidate(); toast.success(`${member.user.firstname} unbanned`) },
    onError: (err) => toast.error((err as Error).message),
  })
  const { mutate: promote, isPending: promoting } = useMutation({
    mutationFn: () => membershipApi.setRole(communityId, member.userId, 'admin'),
    onSuccess: () => { invalidate(); toast.success(`${member.user.firstname} promoted to admin`) },
    onError: (err) => toast.error((err as Error).message),
  })
  const { mutate: demote, isPending: demoting } = useMutation({
    mutationFn: () => membershipApi.setRole(communityId, member.userId, 'member'),
    onSuccess: () => { invalidate(); toast.success(`${member.user.firstname} demoted to member`) },
    onError: (err) => toast.error((err as Error).message),
  })

  const latestSub = member.subscriptions[0] ?? null
  const canBan = (isCreator || isAdmin) && member.role !== 'creator'
  const canChangeRole = isCreator && member.role !== 'creator'

  return (
    <>
    <tr className="border-b border-border last:border-0">
      {/* Name + email */}
      <td className="py-3 pr-4">
        <p className="text-sm font-medium text-foreground">
          {member.user.firstname} {member.user.lastname}
        </p>
        <p className="text-xs text-muted-foreground">{member.user.email}</p>
      </td>

      {/* Role */}
      <td className="py-3 pr-4">
        <RoleBadge role={member.role} />
      </td>

      {/* Status */}
      <td className="py-3 pr-4">
        <StatusBadge status={member.status} />
      </td>

      {/* Tier */}
      <td className="py-3 pr-4">
        <span
          className={`rounded-full px-2 py-0.5 text-xs font-medium ${
            member.membershipTier === 'PAID'
              ? 'bg-primary/10 text-primary'
              : 'bg-muted text-muted-foreground'
          }`}
        >
          {member.membershipTier}
        </span>
      </td>

      {/* Joined */}
      <td className="py-3 pr-4 text-xs text-muted-foreground">
        {formatDistanceToNow(new Date(member.joinedAt), { addSuffix: true })}
      </td>

      {/* Sub end */}
      <td className="py-3 pr-4 text-xs text-muted-foreground">
        {latestSub?.subscriptionEnd
          ? new Date(latestSub.subscriptionEnd).toLocaleDateString()
          : '—'}
      </td>

      {/* Actions */}
      <td className="py-3">
        <div className="flex items-center gap-1">
          {canBan && member.status !== 'BANNED' && (
            <button
              onClick={() => setConfirmBan(true)}
              disabled={banning}
              title="Ban member"
              className="rounded p-1.5 text-muted-foreground transition-colors hover:bg-red-50 hover:text-red-600 disabled:opacity-50"
            >
              <UserMinus className="h-3.5 w-3.5" />
            </button>
          )}
          {canBan && member.status === 'BANNED' && (
            <button
              onClick={() => unban()}
              disabled={unbanning}
              title="Unban member"
              className="rounded p-1.5 text-muted-foreground transition-colors hover:bg-emerald-50 hover:text-emerald-600 disabled:opacity-50"
            >
              <UserPlus className="h-3.5 w-3.5" />
            </button>
          )}
          {canChangeRole && member.role === 'member' && (
            <button
              onClick={() => promote()}
              disabled={promoting}
              title="Promote to admin"
              className="rounded p-1.5 text-muted-foreground transition-colors hover:bg-blue-50 hover:text-blue-600 disabled:opacity-50"
            >
              <Shield className="h-3.5 w-3.5" />
            </button>
          )}
          {canChangeRole && member.role === 'admin' && (
            <button
              onClick={() => demote()}
              disabled={demoting}
              title="Demote to member"
              className="rounded p-1.5 text-muted-foreground transition-colors hover:bg-orange-50 hover:text-orange-600 disabled:opacity-50"
            >
              <ShieldOff className="h-3.5 w-3.5" />
            </button>
          )}
        </div>
      </td>
    </tr>
    <ConfirmModal
      open={confirmBan}
      onOpenChange={setConfirmBan}
      title="Ban member?"
      description={`${member.user.firstname} ${member.user.lastname} will be banned and lose access to this community.`}
      confirmLabel="Ban"
      onConfirm={() => ban()}
      isPending={banning}
    />
    </>
  )
}

// ─── SettingsMembers ──────────────────────────────────────────────────────────

export function SettingsMembers() {
  const { id: communityId } = useParams<{ id: string }>()
  const { user } = useAuthStore()

  const { data: communityData } = useQuery({
    queryKey: ['community', communityId],
    queryFn: () => communityApi.getById(communityId!),
    enabled: !!communityId,
  })

  const { data, isLoading } = useQuery({
    queryKey: ['settings-members', communityId],
    queryFn: () => membershipApi.getCommunityMembers(communityId!),
    enabled: !!communityId,
  })

  const members = data?.data?.members ?? []
  const community = communityData?.data?.community
  const myMembership = members.find((m) => m.userId === user?.id)
  const isCreator = community?.creator.id === user?.id
  const isAdmin = myMembership?.role === 'admin'

  function handleExport() {
    membershipApi.exportCsv(communityId!).then((blob) => {
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `members-${communityId}.csv`
      a.click()
      URL.revokeObjectURL(url)
    })
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold text-foreground">Members</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            {members.length} member{members.length !== 1 ? 's' : ''}
          </p>
        </div>
        <Button variant="outline" size="sm" onClick={handleExport}>
          <Download className="h-4 w-4" />
          Export CSV
        </Button>
      </div>

      <div className="rounded-xl border border-border bg-card overflow-hidden">
        {isLoading ? (
          <div className="flex h-32 items-center justify-center">
            <div className="h-5 w-5 animate-spin rounded-full border-4 border-border border-t-primary" />
          </div>
        ) : members.length === 0 ? (
          <p className="py-10 text-center text-sm text-muted-foreground">No members yet.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-border bg-muted/40">
                  {['Member', 'Role', 'Status', 'Tier', 'Joined', 'Sub ends', ''].map((h) => (
                    <th
                      key={h}
                      className="px-4 py-2.5 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground first:pl-4"
                    >
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-border px-4">
                {members.map((member) => (
                  <MemberRow
                    key={member.id}
                    member={member}
                    communityId={communityId!}
                    isCreator={isCreator}
                    isAdmin={isAdmin}
                  />
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}
