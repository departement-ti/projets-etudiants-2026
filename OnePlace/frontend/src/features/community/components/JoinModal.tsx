import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { xpToast } from '@/lib/xpToast'
import { communityApi } from '@/api/community'
import type { BillingInterval, CommunityDetail } from '@/types/community'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'

interface JoinModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  community: CommunityDetail
}

export function JoinModal({ open, onOpenChange, community }: JoinModalProps) {
  const queryClient = useQueryClient()
  const navigate = useNavigate()
  const [billingInterval, setBillingInterval] = useState<BillingInterval>('MONTHLY')

  const { mutate: join, isPending } = useMutation({
    mutationFn: () => {
      const interval =
        community.pricingModel === 'SUBSCRIPTION' ? billingInterval : undefined
      return communityApi.join(community.id, interval)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['membership', community.id] })
      toast.success(`Welcome to ${community.name}!`)
      xpToast(5)
      onOpenChange(false)
      navigate(`/communities/${community.id}/community`)
    },
    onError: (err) => toast.error((err as Error).message),
  })

  const { pricing } = community

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Join {community.name}</DialogTitle>
          <DialogDescription>
            {community.pricingModel === 'FREE' && 'This community is free to join.'}
            {community.pricingModel === 'FREEMIUM' &&
              'Join for free. Upgrade to paid anytime for premium content.'}
            {community.pricingModel === 'SUBSCRIPTION' && 'Choose a billing plan to join.'}
            {community.pricingModel === 'ONE_TIME' && 'One-time payment for lifetime access.'}
          </DialogDescription>
        </DialogHeader>

        {community.pricingModel === 'SUBSCRIPTION' && pricing && (
          <div className="mb-4 grid grid-cols-2 gap-3">
            <button
              onClick={() => setBillingInterval('MONTHLY')}
              className={`rounded-lg border p-4 text-left transition-colors ${
                billingInterval === 'MONTHLY'
                  ? 'border-primary bg-primary/5'
                  : 'border-border hover:border-primary/50'
              }`}
            >
              <p className="text-sm font-medium text-foreground">Monthly</p>
              <p className="mt-1 text-xl font-bold text-foreground">
                ${pricing.monthlyPrice}
                <span className="text-sm font-normal text-muted-foreground">/mo</span>
              </p>
            </button>
            <button
              onClick={() => setBillingInterval('YEARLY')}
              className={`rounded-lg border p-4 text-left transition-colors ${
                billingInterval === 'YEARLY'
                  ? 'border-primary bg-primary/5'
                  : 'border-border hover:border-primary/50'
              }`}
            >
              <p className="text-sm font-medium text-foreground">Yearly</p>
              <p className="mt-1 text-xl font-bold text-foreground">
                ${Number(pricing.yearlyPrice).toFixed(2)}
                <span className="text-sm font-normal text-muted-foreground">/yr</span>
              </p>
              {pricing.monthlyPrice && pricing.yearlyPrice && (
                <p className="mt-1 text-xs text-emerald-600">
                  Save $
                  {(
                    Number(pricing.monthlyPrice) * 12 - Number(pricing.yearlyPrice)
                  ).toFixed(0)}
                </p>
              )}
            </button>
          </div>
        )}

        {community.pricingModel === 'ONE_TIME' && pricing?.oneTimePrice && (
          <div className="mb-4 rounded-lg border border-border bg-muted/50 p-4">
            <p className="text-sm text-muted-foreground">One-time price</p>
            <p className="mt-1 text-2xl font-bold text-foreground">${pricing.oneTimePrice}</p>
            <p className="mt-1 text-xs text-muted-foreground">Lifetime access, no recurring charges.</p>
          </div>
        )}

        <Button onClick={() => join()} disabled={isPending} className="w-full">
          {isPending
            ? 'Joining...'
            : community.pricingModel === 'FREE' || community.pricingModel === 'FREEMIUM'
            ? 'Join for free'
            : community.pricingModel === 'ONE_TIME'
            ? `Buy access — $${Number(pricing?.oneTimePrice).toFixed(2)}`
            : `Subscribe — $${billingInterval === 'MONTHLY' ? Number(pricing?.monthlyPrice).toFixed(2) + '/mo' : Number(pricing?.yearlyPrice).toFixed(2) + '/yr'}`}
        </Button>
      </DialogContent>
    </Dialog>
  )
}
