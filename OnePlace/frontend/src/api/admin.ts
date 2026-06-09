import { api } from './client'
import type { ApiResponse } from '@/types/auth'
import type { AdminCommunity, AdminUser, PlatformAnalytics } from '@/types/admin'

export const adminApi = {
  listUsers: () =>
    api.get<ApiResponse<{ users: AdminUser[] }>>('/admin/users').then((r) => r.data),

  listCommunities: () =>
    api
      .get<ApiResponse<{ communities: AdminCommunity[] }>>('/admin/communities')
      .then((r) => r.data),

  suspendUser: (id: string) =>
    api.put<ApiResponse<{ user: AdminUser }>>(`/admin/users/${id}/suspend`).then((r) => r.data),

  unsuspendUser: (id: string) =>
    api
      .put<ApiResponse<{ user: AdminUser }>>(`/admin/users/${id}/unsuspend`)
      .then((r) => r.data),

  getAnalytics: () =>
    api.get<ApiResponse<PlatformAnalytics>>('/admin/analytics').then((r) => r.data),
}
