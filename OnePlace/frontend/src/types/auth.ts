export interface User {
  id: string
  firstname: string
  lastname: string
  email: string
  role: 'USER' | 'ADMIN' | 'moderator'
  avatarUrl?: string | null
  emailVerified: boolean
  createdAt: string
}

export interface SignUpPayload {
  firstname: string
  lastname: string
  email: string
  password: string
}

export interface SignInPayload {
  email: string
  password: string
}

export interface ApiResponse<T = undefined> {
  success: boolean
  message: string
  data?: T
}
