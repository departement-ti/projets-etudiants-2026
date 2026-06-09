import { api } from './client'
import type { ApiResponse } from '@/types/auth'

export type ChatMessage = {
  role: 'user' | 'assistant'
  content: string
}

export type SentimentData = {
  overall: string
  breakdown: { positive: number; neutral: number; negative: number }
  themes: string[]
  summary: string
  postCount: number
}

export type QuizQuestion = {
  question: string
  options: string[]
  correctIndex: number
  explanation: string
}

export type QuizResult = {
  questions: QuizQuestion[]
  transcriptSource: 'youtube_captions' | 'whisper' | 'cached' | 'none'
}

export type ProgressCoachData = {
  message: string
  daysSinceActive: number | null
  completedCount: number
  totalLessons: number
  lastLesson: string | null
  lastCourse: string | null
}

export type CommunityMatch = {
  id: string
  name: string
  description: string | null
  pricingModel: string
  memberCount: number
  reason: string
}

export type ChurnMember = {
  userId: string
  name: string
  email: string
  posts: number
  comments: number
  expiringIn7Days: boolean
  riskScore: number
  riskLevel: 'high' | 'medium' | 'low'
}

export type AnalyticsSummaryData = {
  summary: string
  data: {
    totalMembers: number
    activeMembers: number
    newThisMonth: number
    newLastMonth: number
    growthPct: number
    revenueThisMonth: number
    revenueLastMonth: number
    totalRevenue: number
    postsThisMonth: number
    commentsThisMonth: number
    likesThisMonth: number
  }
}

export const aiApi = {
  generateQuiz: (lessonId: string) =>
    api
      .post<ApiResponse<QuizResult>>(`/ai/lessons/${lessonId}/quiz`)
      .then((r) => r.data),

  getProgressCoach: (communityId: string) =>
    api
      .get<ApiResponse<ProgressCoachData>>(`/ai/communities/${communityId}/progress-coach`)
      .then((r) => r.data),

  getMatchmaking: () =>
    api
      .get<ApiResponse<{ matches: CommunityMatch[] }>>('/ai/matchmaking')
      .then((r) => r.data),

  getChurnRisk: (communityId: string) =>
    api
      .get<ApiResponse<{ atRisk: ChurnMember[]; summary: string }>>(`/ai/communities/${communityId}/churn-risk`)
      .then((r) => r.data),

  getAnalyticsSummary: (communityId: string) =>
    api
      .get<ApiResponse<AnalyticsSummaryData>>(`/ai/communities/${communityId}/analytics-summary`)
      .then((r) => r.data),

  askCommunity: (communityId: string, question: string, history: ChatMessage[]) =>
    api
      .post<ApiResponse<{ answer: string }>>(`/ai/communities/${communityId}/qa`, { question, history })
      .then((r) => r.data),

  postAssist: (content: string, action: 'improve' | 'fix_grammar' | 'expand') =>
    api
      .post<ApiResponse<{ improved: string }>>('/ai/post-assist', { content, action })
      .then((r) => r.data),

  getSentiment: (communityId: string) =>
    api
      .get<ApiResponse<SentimentData>>(`/ai/communities/${communityId}/sentiment`)
      .then((r) => r.data),

  reindex: (communityId: string) =>
    api
      .post<ApiResponse<{ message: string }>>(`/ai/communities/${communityId}/reindex`)
      .then((r) => r.data),

  transcribeVideo: (videoUrl: string) =>
    api
      .post<ApiResponse<{ transcript: string; source: 'youtube_captions' | 'whisper' | 'none' }>>('/ai/transcribe', { videoUrl })
      .then((r) => r.data),
}
