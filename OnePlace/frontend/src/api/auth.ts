import { api } from './client'
import type { ApiResponse, SignInPayload, SignUpPayload, User } from '@/types/auth'

export const authApi = {
  signUp: (payload: SignUpPayload) =>
    api.post<ApiResponse<{ user: User }>>('/auth/sign-up', payload).then((r) => r.data),

  signIn: (payload: SignInPayload) =>
    api.post<ApiResponse<{ user: User }>>('/auth/sign-in', payload).then((r) => r.data),

  signOut: () =>
    api.post<ApiResponse>('/auth/sign-out').then((r) => r.data),

  verifyEmail: (token: string) =>
    api.post<ApiResponse>('/auth/verify-email', { token }).then((r) => r.data),

  forgotPassword: (email: string) =>
    api.post<ApiResponse>('/auth/forgot-password', { email }).then((r) => r.data),

  resetPassword: (token: string, newPassword: string) =>
    api.post<ApiResponse>('/auth/reset-password', { token, newPassword }).then((r) => r.data),

  me: () =>
    api.get<ApiResponse<{ user: User }>>('/user/me').then((r) => r.data),
}
