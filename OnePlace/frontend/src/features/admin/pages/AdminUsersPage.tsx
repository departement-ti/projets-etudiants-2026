import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Search, UserX, UserCheck } from 'lucide-react'
import { formatDistanceToNow } from 'date-fns'
import { toast } from 'sonner'
import { adminApi } from '@/api/admin'
import { useAuthStore } from '@/store/auth.store'
import type { AdminUser } from '@/types/admin'

// ─── Badges ───────────────────────────────────────────────────────────────────

function VerifiedBadge({ verified }: { verified: boolean }) {
  return (
    <span
      className={`rounded-full px-2 py-0.5 text-xs font-medium ${
        verified
          ? 'bg-emerald-100 text-emerald-700'
          : 'bg-muted text-muted-foreground'
      }`}
    >
      {verified ? 'Verified' : 'Unverified'}
    </span>
  )
}

function SuspendedBadge({ suspended }: { suspended: boolean }) {
  if (!suspended) return null
  return (
    <span className="rounded-full bg-red-100 px-2 py-0.5 text-xs font-medium text-red-700">
      Suspended
    </span>
  )
}

// ─── UserRow ──────────────────────────────────────────────────────────────────

function UserRow({ user, currentUserId }: { user: AdminUser; currentUserId: string }) {
  const queryClient = useQueryClient()
  const invalidate = () => queryClient.invalidateQueries({ queryKey: ['admin-users'] })

  const { mutate: suspend, isPending: suspending } = useMutation({
    mutationFn: () => adminApi.suspendUser(user.id),
    onSuccess: () => { invalidate(); toast.success(`${user.firstname} suspended`) },
    onError: (err) => toast.error((err as Error).message),
  })

  const { mutate: unsuspend, isPending: unsuspending } = useMutation({
    mutationFn: () => adminApi.unsuspendUser(user.id),
    onSuccess: () => { invalidate(); toast.success(`${user.firstname} unsuspended`) },
    onError: (err) => toast.error((err as Error).message),
  })

  const isSelf = user.id === currentUserId
  const isModerator = user.role === 'moderator'
  const canToggle = !isSelf && !isModerator

  return (
    <tr className="border-b border-border last:border-0">
      <td className="py-3 pr-4">
        <p className="text-sm font-medium text-foreground">
          {user.firstname} {user.lastname}
        </p>
        <p className="text-xs text-muted-foreground">{user.email}</p>
      </td>

      <td className="py-3 pr-4">
        <span className="text-xs capitalize text-muted-foreground">{user.role.toLowerCase()}</span>
      </td>

      <td className="py-3 pr-4">
        <VerifiedBadge verified={user.isVerified} />
      </td>

      <td className="py-3 pr-4">
        <SuspendedBadge suspended={user.isSuspended} />
      </td>

      <td className="py-3 pr-4 text-xs text-muted-foreground">
        {user._count.communities} / {user._count.memberships}
      </td>

      <td className="py-3 pr-4 text-xs text-muted-foreground">
        {formatDistanceToNow(new Date(user.createdAt), { addSuffix: true })}
      </td>

      <td className="py-3">
        {canToggle && (
          user.isSuspended ? (
            <button
              onClick={() => unsuspend()}
              disabled={unsuspending}
              title="Unsuspend user"
              className="rounded p-1.5 text-muted-foreground transition-colors hover:bg-emerald-50 hover:text-emerald-600 disabled:opacity-50"
            >
              <UserCheck className="h-3.5 w-3.5" />
            </button>
          ) : (
            <button
              onClick={() => suspend()}
              disabled={suspending}
              title="Suspend user"
              className="rounded p-1.5 text-muted-foreground transition-colors hover:bg-red-50 hover:text-red-600 disabled:opacity-50"
            >
              <UserX className="h-3.5 w-3.5" />
            </button>
          )
        )}
      </td>
    </tr>
  )
}

// ─── AdminUsersPage ───────────────────────────────────────────────────────────

export function AdminUsersPage() {
  const [search, setSearch] = useState('')
  const { user: me } = useAuthStore()

  const { data, isLoading } = useQuery({
    queryKey: ['admin-users'],
    queryFn: adminApi.listUsers,
  })

  const users = data?.data?.users ?? []

  const filtered = search.trim()
    ? users.filter(
        (u) =>
          `${u.firstname} ${u.lastname}`.toLowerCase().includes(search.toLowerCase()) ||
          u.email.toLowerCase().includes(search.toLowerCase()),
      )
    : users

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-semibold text-foreground">Users</h1>
          <p className="mt-1 text-sm text-muted-foreground">{users.length} total</p>
        </div>
        <div className="relative">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search users..."
            className="h-9 rounded-lg border border-border bg-background pl-9 pr-3 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-1 focus:ring-offset-background"
          />
        </div>
      </div>

      <div className="rounded-xl border border-border bg-card overflow-hidden">
        {isLoading ? (
          <div className="flex h-32 items-center justify-center">
            <div className="h-5 w-5 animate-spin rounded-full border-4 border-border border-t-primary" />
          </div>
        ) : filtered.length === 0 ? (
          <p className="py-10 text-center text-sm text-muted-foreground">
            {search ? `No users found for "${search}"` : 'No users yet.'}
          </p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-border bg-muted/40">
                  {['User', 'Role', 'Email', 'Status', 'Comm / Mem', 'Joined', ''].map((h) => (
                    <th
                      key={h}
                      className="px-4 py-2.5 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground"
                    >
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {filtered.map((user) => (
                  <UserRow key={user.id} user={user} currentUserId={me?.id ?? ''} />
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}
