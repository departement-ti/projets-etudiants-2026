import type { CommunityDetail, CommunityListItem, Membership } from '@/types/community'

export const MOCK_COMMUNITIES: CommunityListItem[] = [
  {
    id: 'mock-community-1',
    name: 'AI Builders Club',
    description:
      'The go-to community for developers and founders who want to ship AI-powered products faster. Weekly teardowns, live builds, and a tight-knit group of builders.',
    coverUrl: null,
    iconUrl: null,
    pricingModel: 'SUBSCRIPTION',
    platformPlan: 'PRO',
    createdAt: '2024-01-10T00:00:00Z',
    creator: { id: 'creator-1', firstname: 'Bilel', lastname: 'Jabrane' },
    _count: { memberships: 3241 },
  },
  {
    id: 'mock-community-2',
    name: 'Design Systems Mastery',
    description:
      'Learn how to build and maintain design systems at scale. Figma workflows, token architecture, component libraries, and everything in between.',
    coverUrl: null,
    iconUrl: null,
    pricingModel: 'FREE',
    platformPlan: 'BASIC',
    createdAt: '2024-02-05T00:00:00Z',
    creator: { id: 'creator-2', firstname: 'Sara', lastname: 'Chen' },
    _count: { memberships: 8870 },
  },
  {
    id: 'mock-community-3',
    name: 'Indie Hackers Network',
    description:
      'Bootstrap founders sharing revenue numbers, growth tactics, and hard-won lessons. Free tier gets you the feed. Premium unlocks the full course library.',
    coverUrl: null,
    iconUrl: null,
    pricingModel: 'FREEMIUM',
    platformPlan: 'PRO',
    createdAt: '2024-03-12T00:00:00Z',
    creator: { id: 'creator-3', firstname: 'Marc', lastname: 'Dubois' },
    _count: { memberships: 15400 },
  },
  {
    id: 'mock-community-4',
    name: 'Spanish Fluency Lab',
    description:
      'Structured immersion for busy adults. Daily micro-lessons, conversation practice sessions, and a supportive community to keep you accountable.',
    coverUrl: null,
    iconUrl: null,
    pricingModel: 'SUBSCRIPTION',
    platformPlan: 'PRO',
    createdAt: '2024-04-01T00:00:00Z',
    creator: { id: 'creator-4', firstname: 'Lucia', lastname: 'Martinez' },
    _count: { memberships: 2109 },
  },
  {
    id: 'mock-community-5',
    name: 'TypeScript Deep Dive',
    description:
      'From advanced generics to compiler internals. One payment, lifetime access to all courses, challenges, and future updates.',
    coverUrl: null,
    iconUrl: null,
    pricingModel: 'ONE_TIME',
    platformPlan: 'PRO',
    createdAt: '2024-04-20T00:00:00Z',
    creator: { id: 'creator-5', firstname: 'Dan', lastname: 'Park' },
    _count: { memberships: 1893 },
  },
  {
    id: 'mock-community-6',
    name: 'Fitness & Biohacking',
    description:
      'Evidence-based protocols for performance, longevity, and recovery. Open for everyone — no gimmicks, just what the research actually says.',
    coverUrl: null,
    iconUrl: null,
    pricingModel: 'FREE',
    platformPlan: 'BASIC',
    createdAt: '2024-05-08T00:00:00Z',
    creator: { id: 'creator-6', firstname: 'Jake', lastname: 'Turner' },
    _count: { memberships: 22100 },
  },
]

export const MOCK_COMMUNITY_DETAIL: CommunityDetail = {
  ...MOCK_COMMUNITIES[0],
  isPrivate: false,
  updatedAt: '2025-04-10T00:00:00Z',
  pricing: {
    id: 'pricing-1',
    currency: 'USD',
    monthlyPrice: '29',
    yearlyPrice: '249',
    oneTimePrice: null,
    upgradePrice: null,
  },
  media: [],
  _count: { memberships: 3241, posts: 874 },
}

/** Returns a fake active membership only for the first mock community. */
export function getMockMembership(id: string): Membership | null {
  if (id !== MOCK_COMMUNITY_DETAIL.id) return null
  return {
    id: `mock-membership-${id}`,
    role: 'member',
    status: 'ACTIVE',
    membershipTier: 'FREE',
    joinedAt: '2025-01-01T00:00:00Z',
  }
}

/** Returns a CommunityDetail for any mock ID — used by the community layout and about page. */
export function getMockCommunityDetail(id: string): CommunityDetail | undefined {
  if (id === MOCK_COMMUNITY_DETAIL.id) return MOCK_COMMUNITY_DETAIL

  const item = MOCK_COMMUNITIES.find((c) => c.id === id)
  if (!item) return undefined

  return {
    ...item,
    isPrivate: false,
    updatedAt: item.createdAt,
    pricing: null,
    media: [],
    _count: { memberships: item._count.memberships, posts: 0 },
  }
}
