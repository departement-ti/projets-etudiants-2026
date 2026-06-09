export interface LeaderboardEntry {
  rank: number
  userId: string
  firstname: string
  lastname: string
  avatarUrl: string | null
  points: number
}

export interface LevelDistribution {
  level: number
  minXP: number
  count: number
  percentage: number
}

export interface UserStats {
  totalXP: number
  level: number
  pointsToNextLevel: number | null
}

export interface LeaderboardData {
  userStats: UserStats
  levelDistribution: LevelDistribution[]
  leaderboard7d: LeaderboardEntry[]
  leaderboard30d: LeaderboardEntry[]
  leaderboardAllTime: LeaderboardEntry[]
  lastUpdated: string
}
