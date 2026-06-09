import { api } from './client'
import type { ApiResponse, User } from '@/types/auth'
import type { UserCommunity } from '@/types/community'

export const userApi = {
  getMe: () =>
    api.get<ApiResponse<{ user: User }>>('/user/me').then((r) => r.data),

  updateMe: (data: {
    firstname?: string
    lastname?: string
    avatarUrl?: string | null
    currentPassword?: string
    newPassword?: string
  }) =>
    api.put<ApiResponse<{ user: User }>>('/user/me', data).then((r) => r.data),

  getMyCommunities: () =>
    api
      .get<ApiResponse<{ communities: UserCommunity[] }>>('/user/me/communities')
      .then((r) => r.data),
}
