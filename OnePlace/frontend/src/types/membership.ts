import type { MembershipRole, MembershipStatus, MembershipTier } from './community'

export interface MemberUser {
  id: string
  firstname: string
  lastname: string
  email: string
}

export interface MemberSubscription {
  id: string
  billingInterval: string | null
  subscriptionStart: string
  subscriptionEnd: string | null
  pricePaid: string
  paymentStatus: string
}

export interface CommunityMember {
  id: string
  userId: string
  communityId: string
  role: MembershipRole
  status: MembershipStatus
  membershipTier: MembershipTier
  joinedAt: string
  user: MemberUser
  subscriptions: MemberSubscription[]
}
