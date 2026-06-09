import type { CommunityPricing, PricingModel } from '@/types/community'

const GRADIENTS = [
  'from-violet-600 via-purple-700 to-indigo-900',
  'from-blue-500 via-blue-700 to-indigo-900',
  'from-amber-500 via-orange-600 to-red-800',
  'from-emerald-500 via-teal-600 to-cyan-800',
  'from-pink-500 via-rose-600 to-red-800',
  'from-cyan-500 via-blue-600 to-violet-800',
  'from-orange-500 via-amber-600 to-yellow-700',
  'from-fuchsia-500 via-purple-600 to-violet-900',
]

export function getGradient(id: string): string {
  let hash = 0
  for (let i = 0; i < id.length; i++) {
    hash = (hash << 5) - hash + id.charCodeAt(i)
    hash |= 0
  }
  return GRADIENTS[Math.abs(hash) % GRADIENTS.length]
}

export function formatCount(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`
  if (n >= 1_000) return `${(n / 1_000).toFixed(1)}k`
  return n.toString()
}

export function getPricingLabel(
  pricingModel: PricingModel,
  pricing?: CommunityPricing | null,
): string {
  switch (pricingModel) {
    case 'FREE':
      return 'Free'
    case 'FREEMIUM':
      return pricing?.upgradePrice ? `Free · $${pricing.upgradePrice}/mo to upgrade` : 'Free'
    case 'SUBSCRIPTION':
      return pricing?.monthlyPrice ? `$${pricing.monthlyPrice}/mo` : 'Paid'
    case 'ONE_TIME':
      return pricing?.oneTimePrice ? `$${pricing.oneTimePrice}` : 'One-time'
    default:
      return 'Free'
  }
}
