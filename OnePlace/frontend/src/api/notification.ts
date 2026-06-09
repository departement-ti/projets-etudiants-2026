import { api } from './client'
import type { ApiResponse } from '@/types/auth'
import type { Notification } from '@/types/notification'

export const notificationApi = {
  list: () =>
    api
      .get<ApiResponse<{ notifications: Notification[] }>>('/notifications')
      .then((r) => r.data),

  unreadCount: () =>
    api
      .get<ApiResponse<{ count: number }>>('/notifications/unread-count')
      .then((r) => r.data),

  markAsRead: (id: string) =>
    api.patch<ApiResponse>(`/notifications/${id}/read`).then((r) => r.data),

  markAllAsRead: () =>
    api.patch<ApiResponse>('/notifications/read-all').then((r) => r.data),
}
