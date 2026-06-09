import { useNavigate } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Bell, MessageSquare, FileText, UserPlus, Clock, AlertCircle } from 'lucide-react'
import { formatDistanceToNow } from 'date-fns'
import { notificationApi } from '@/api/notification'
import type { Notification, NotificationType } from '@/types/notification'
import { cn } from '@/lib/utils'
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover'
import { Button } from '@/components/ui/button'

// ─── Icon by type ─────────────────────────────────────────────────────────────

function NotifIcon({ type }: { type: NotificationType }) {
  const cls = 'h-4 w-4 shrink-0'
  switch (type) {
    case 'NEW_COMMENT':
      return <MessageSquare className={cn(cls, 'text-blue-400')} />
    case 'NEW_POST':
      return <FileText className={cn(cls, 'text-purple-400')} />
    case 'MEMBER_JOINED':
      return <UserPlus className={cn(cls, 'text-green-400')} />
    case 'SUBSCRIPTION_EXPIRING':
      return <Clock className={cn(cls, 'text-amber-400')} />
    case 'SUBSCRIPTION_EXPIRED':
      return <AlertCircle className={cn(cls, 'text-red-400')} />
  }
}

// ─── Single notification row ──────────────────────────────────────────────────

function NotifRow({
  notification,
  onRead,
}: {
  notification: Notification
  onRead: (n: Notification) => void
}) {
  const navigate = useNavigate()

  function handleClick() {
    onRead(notification)
    if (notification.link) navigate(notification.link)
  }

  return (
    <button
      onClick={handleClick}
      className={cn(
        'flex w-full items-start gap-3 rounded-lg px-3 py-2.5 text-left transition-colors hover:bg-muted',
        !notification.isRead && 'bg-primary/5',
      )}
    >
      <span className="mt-0.5">
        <NotifIcon type={notification.type} />
      </span>
      <div className="min-w-0 flex-1">
        <p className={cn('text-sm', !notification.isRead ? 'font-medium text-foreground' : 'text-muted-foreground')}>
          {notification.title}
        </p>
        {notification.body && (
          <p className="mt-0.5 line-clamp-2 text-xs text-muted-foreground">{notification.body}</p>
        )}
        <p className="mt-1 text-[11px] text-muted-foreground/60">
          {formatDistanceToNow(new Date(notification.createdAt), { addSuffix: true })}
        </p>
      </div>
      {!notification.isRead && (
        <span className="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-primary" />
      )}
    </button>
  )
}

// ─── NotificationBell ─────────────────────────────────────────────────────────

export function NotificationBell() {
  const queryClient = useQueryClient()

  const { data: countData } = useQuery({
    queryKey: ['notifications', 'unread-count'],
    queryFn: notificationApi.unreadCount,
    refetchInterval: 30_000,
  })

  const { data: listData } = useQuery({
    queryKey: ['notifications'],
    queryFn: notificationApi.list,
    staleTime: 10_000,
  })

  const markRead = useMutation({
    mutationFn: (id: string) => notificationApi.markAsRead(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] })
    },
  })

  const markAll = useMutation({
    mutationFn: notificationApi.markAllAsRead,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] })
    },
  })

  const unread = countData?.data?.count ?? 0
  const notifications = listData?.data?.notifications ?? []

  function handleRead(n: Notification) {
    if (!n.isRead) markRead.mutate(n.id)
  }

  return (
    <Popover>
      <PopoverTrigger asChild>
        <button
          className="relative flex h-8 w-8 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:bg-muted hover:text-foreground focus:outline-none"
          aria-label="Notifications"
        >
          <Bell className="h-4.5 w-4.5" />
          {unread > 0 && (
            <span className="absolute -right-0.5 -top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-primary px-1 text-[10px] font-bold text-white">
              {unread > 99 ? '99+' : unread}
            </span>
          )}
        </button>
      </PopoverTrigger>

      <PopoverContent align="end" className="w-80 p-0">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-border px-4 py-3">
          <h3 className="text-sm font-semibold text-foreground">Notifications</h3>
          {unread > 0 && (
            <Button
              variant="ghost"
              size="sm"
              className="h-auto px-2 py-1 text-xs text-muted-foreground hover:text-foreground"
              onClick={() => markAll.mutate()}
              disabled={markAll.isPending}
            >
              Mark all read
            </Button>
          )}
        </div>

        {/* List */}
        <div className="max-h-96 overflow-y-auto py-1">
          {notifications.length === 0 ? (
            <div className="flex flex-col items-center justify-center gap-2 py-10 text-center">
              <Bell className="h-8 w-8 text-muted-foreground/40" />
              <p className="text-sm text-muted-foreground">No notifications yet</p>
            </div>
          ) : (
            notifications.map((n) => (
              <NotifRow key={n.id} notification={n} onRead={handleRead} />
            ))
          )}
        </div>
      </PopoverContent>
    </Popover>
  )
}
