import { api } from './client'
import type { ApiResponse } from '@/types/auth'
import type { LeaderboardData } from '@/types/leaderboard'

export const leaderboardApi = {
  get: (communityId: string) =>
    api
      .get<ApiResponse<LeaderboardData>>(`/communities/${communityId}/leaderboard`)
      .then((r) => r.data),
}
