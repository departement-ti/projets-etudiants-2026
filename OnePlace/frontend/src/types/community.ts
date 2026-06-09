export type PricingModel = 'FREE' | 'FREEMIUM' | 'SUBSCRIPTION' | 'ONE_TIME'
export type MediaType = 'IMAGE' | 'VIDEO'

export interface CommunityMedia {
  id: string
  url: string
  thumbnailUrl: string | null
  type: MediaType
  order: number
}
export type PlatformPlan = 'BASIC' | 'PRO'
export type MembershipRole = 'creator' | 'admin' | 'member'
export type MembershipStatus = 'ACTIVE' | 'CANCELLED' | 'BANNED' | 'EXPIRED'
export type MembershipTier = 'FREE' | 'PAID'
export type BillingInterval = 'MONTHLY' | 'YEARLY'

export interface Membership {
  id: string
  role: MembershipRole
  status: MembershipStatus
  membershipTier: MembershipTier
  joinedAt: string
}

export interface CommunityCreator {
  id: string
  firstname: string
  lastname: string
}

export interface CommunityPricing {
  id: string
  currency: string
  monthlyPrice: string | null
  yearlyPrice: string | null
  oneTimePrice: string | null
  upgradePrice: string | null
}

export interface CommunityListItem {
  id: string
  name: string
  description: string | null
  coverUrl: string | null
  iconUrl: string | null
  pricingModel: PricingModel
  platformPlan: PlatformPlan
  createdAt: string
  creator: CommunityCreator
  _count: { memberships: number }
}

export interface CommunityDetail {
  id: string
  name: string
  description: string | null
  coverUrl: string | null
  iconUrl: string | null
  pricingModel: PricingModel
  platformPlan: PlatformPlan
  isPrivate: boolean
  createdAt: string
  updatedAt: string
  creator: CommunityCreator
  pricing: CommunityPricing | null
  media: CommunityMedia[]
  _count: { memberships: number; posts: number }
}

export interface UserCommunity {
  membershipId: string
  role: MembershipRole
  membershipTier: MembershipTier
  joinedAt: string
  community: {
    id: string
    name: string
    description: string | null
    iconUrl: string | null
    pricingModel: PricingModel
    platformPlan: PlatformPlan
    creator: CommunityCreator
  }
}

export interface SubscriptionRecord {
  id: string
  billingInterval: string | null
  subscriptionStart: string
  subscriptionEnd: string | null
  pricePaid: string
  paymentStatus: string
  isExpired: boolean
}

export interface SubscriptionDetail {
  membershipId: string
  status: MembershipStatus
  membershipTier: MembershipTier
  pricingModel: PricingModel
  subscription: SubscriptionRecord | null
  pricing: CommunityPricing | null
}

export interface CommunityMember {
  id: string
  role: MembershipRole
  membershipTier: MembershipTier
  joinedAt: string
  user: {
    id: string
    firstname: string
    lastname: string
    avatarUrl: string | null
  }
}

export interface MonthDataPoint {
  month: string
  value: number
}

export interface CommunityAnalytics {
  community: {
    id: string
    name: string
    pricingModel: PricingModel
    platformPlan: PlatformPlan
  }
  members: {
    total: number
    active: number
    byStatus: Record<string, number>
    byTier: Record<string, number>
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
