import type { CommunityPricing, MonthDataPoint, PlatformPlan, PricingModel } from './community'

export interface AdminUser {
  id: string
  firstname: string
  lastname: string
  email: string
  role: string
  isVerified: boolean
  isSuspended: boolean
  lastLogin: string | null
  createdAt: string
  _count: { memberships: number; communities: number }
}

export interface AdminCommunity {
  id: string
  name: string
  description: string | null
  pricingModel: PricingModel
  platformPlan: PlatformPlan
  isPrivate: boolean
  createdAt: string
  creator: {
    id: string
    firstname: string
    lastname: string
    email: string
  }
  pricing: CommunityPricing | null
  _count: { memberships: number; posts: number }
}

export interface PlatformAnalytics {
  users: {
    total: number
    verified: number
    suspended: number
    newThisMonth: number
    growthLast6Months: MonthDataPoint[]
  }
  communities: {
    total: number
    active: number
    newThisMonth: number
    growthLast6Months: MonthDataPoint[]
  }
  revenue: {
    total: number
    thisMonth: number
    last6Months: MonthDataPoint[]
    byInterval: Record<string, number>
  }
}
