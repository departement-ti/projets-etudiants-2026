import { api } from './client'
import type { ApiResponse } from '@/types/auth'
import type { CommunityEvent, CreateEventPayload } from '@/types/event'

export const eventApi = {
  list: (communityId: string, year: number, month: number) =>
    api
      .get<ApiResponse<{ events: CommunityEvent[] }>>(
        `/communities/${communityId}/events`,
        { params: { year, month } },
      )
      .then((r) => r.data),

  create: (communityId: string, data: CreateEventPayload) =>
    api
      .post<ApiResponse<{ event: CommunityEvent }>>(
        `/communities/${communityId}/events`,
        data,
      )
      .then((r) => r.data),

  delete: (communityId: string, eventId: string) =>
    api
      .delete<ApiResponse>(`/communities/${communityId}/events/${eventId}`)
      .then((r) => r.data),
}
