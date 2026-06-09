import { api } from './client'
import type { ApiResponse } from '@/types/auth'
import type { CommunityMember } from '@/types/membership'

const base = (communityId: string) => `/membership/community/${communityId}`

export const membershipApi = {
  getCommunityMembers: (communityId: string) =>
    api
      .get<ApiResponse<{ members: CommunityMember[] }>>(base(communityId))
      .then((r) => r.data),

  ban: (communityId: string, userId: string) =>
    api.put(`${base(communityId)}/members/${userId}/ban`).then((r) => r.data),

  unban: (communityId: string, userId: string) =>
    api.put(`${base(communityId)}/members/${userId}/unban`).then((r) => r.data),

  setRole: (communityId: string, userId: string, role: 'admin' | 'member') =>
    api.put(`${base(communityId)}/members/${userId}/role`, { role }).then((r) => r.data),

  exportCsv: (communityId: string) =>
    api
      .get(`${base(communityId)}/export`, { responseType: 'blob' })
      .then((r) => r.data as Blob),
}
