import { api } from './client'
import type { ApiResponse } from '@/types/auth'
import type {
  BillingInterval,
  CommunityAnalytics,
  CommunityDetail,
  CommunityListItem,
  CommunityMember,
  CommunityMedia,
  MediaType,
  Membership,
  PlatformPlan,
  PricingModel,
  SubscriptionDetail,
} from '@/types/community'

export const communityApi = {
  list: (page = 1, limit = 30) =>
    api
      .get<ApiResponse<{ communities: CommunityListItem[]; total: number; totalPages: number; page: number }>>('/communities', { params: { page, limit } })
      .then((r) => r.data),

  getById: (id: string) =>
    api
      .get<ApiResponse<{ community: CommunityDetail }>>(`/communities/${id}`)
      .then((r) => r.data),

  create: (data: { name: string; description?: string; platformPlan: PlatformPlan }) =>
    api
      .post<ApiResponse<{ community: CommunityDetail; redirectTo: string }>>('/communities', data)
      .then((r) => r.data),

  update: (id: string, data: { name?: string; description?: string; isPrivate?: boolean; coverUrl?: string | null; iconUrl?: string | null }) =>
    api
      .put<ApiResponse<{ community: CommunityDetail }>>(`/communities/${id}`, data)
      .then((r) => r.data),

  configurePricing: (
    id: string,
    data: {
      currency?: string
      monthlyPrice?: number
      yearlyPrice?: number
      oneTimePrice?: number
      upgradePrice?: number
    },
  ) =>
    api.put(`/communities/${id}/pricing`, data).then((r) => r.data),

  changePricingModel: (id: string, pricingModel: PricingModel) =>
    api.put(`/communities/${id}/pricing-model`, { pricingModel }).then((r) => r.data),

  getMyMembership: (id: string) =>
    api
      .get<ApiResponse<{ membership: Membership | null }>>(`/communities/${id}/my-membership`)
      .then((r) => r.data),

  join: (id: string, billingInterval?: BillingInterval) =>
    api
      .post<ApiResponse<{ membership: Membership }>>(`/communities/${id}/join`, { billingInterval })
      .then((r) => r.data),

  upgrade: (id: string) =>
    api
      .post<ApiResponse<{ membership: Membership }>>(`/communities/${id}/upgrade`)
      .then((r) => r.data),

  getSubscription: (id: string) =>
    api
      .get<ApiResponse<SubscriptionDetail>>(`/communities/${id}/subscription`)
      .then((r) => r.data),

  renew: (id: string, billingInterval?: BillingInterval) =>
    api
      .post<ApiResponse>(`/communities/${id}/renew`, { billingInterval })
      .then((r) => r.data),

  leave: (id: string) =>
    api.delete<ApiResponse>(`/communities/${id}/leave`).then((r) => r.data),

  getAnalytics: (id: string) =>
    api
      .get<ApiResponse<CommunityAnalytics>>(`/communities/${id}/analytics`)
      .then((r) => r.data),

  getMembers: (id: string) =>
    api
      .get<ApiResponse<{ members: CommunityMember[] }>>(`/communities/${id}/members`)
      .then((r) => r.data),

  addMedia: (id: string, data: { url: string; type: MediaType; thumbnailUrl?: string | null }) =>
    api
      .post<ApiResponse<{ media: CommunityMedia }>>(`/communities/${id}/media`, data)
      .then((r) => r.data),

  deleteMedia: (id: string, mediaId: string) =>
    api.delete<ApiResponse>(`/communities/${id}/media/${mediaId}`).then((r) => r.data),
}
