import { useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { communityApi } from '@/api/community'
import type { PricingModel } from '@/types/community'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

const MODELS: { value: PricingModel; label: string; description: string }[] = [
  { value: 'FREE', label: 'Free', description: 'Anyone can join at no cost.' },
  {
    value: 'FREEMIUM',
    label: 'Freemium',
    description: 'Free tier + optional paid upgrade for premium content.',
  },
  {
    value: 'SUBSCRIPTION',
    label: 'Subscription',
    description: 'Monthly or yearly recurring payment.',
  },
  { value: 'ONE_TIME', label: 'One-time', description: 'Single payment for lifetime access.' },
]

export function SettingsPricing() {
  const { id } = useParams<{ id: string }>()
  const queryClient = useQueryClient()

  const { data } = useQuery({
    queryKey: ['community', id],
    queryFn: () => communityApi.getById(id!),
    enabled: !!id,
  })

  const community = data?.data?.community
  const pricing = community?.pricing

  const [model, setModel] = useState<PricingModel>('FREE')
  const [monthlyPrice, setMonthlyPrice] = useState('')
  const [yearlyPrice, setYearlyPrice] = useState('')
  const [oneTimePrice, setOneTimePrice] = useState('')
  const [upgradePrice, setUpgradePrice] = useState('')

  useEffect(() => {
    if (community) {
      setModel(community.pricingModel)
      setMonthlyPrice(pricing?.monthlyPrice ?? '')
      setYearlyPrice(pricing?.yearlyPrice ?? '')
      setOneTimePrice(pricing?.oneTimePrice ?? '')
      setUpgradePrice(pricing?.upgradePrice ?? '')
    }
  }, [community, pricing])

  const { mutate: saveModel, isPending: savingModel } = useMutation({
    mutationFn: () => communityApi.changePricingModel(id!, model),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['community', id] })
      toast.success('Pricing model updated')
    },
    onError: (err) => toast.error((err as Error).message),
  })

  const { mutate: savePrices, isPending: savingPrices } = useMutation({
    mutationFn: () =>
      communityApi.configurePricing(id!, {
        ...(monthlyPrice && { monthlyPrice: parseFloat(monthlyPrice) }),
        ...(yearlyPrice && { yearlyPrice: parseFloat(yearlyPrice) }),
        ...(oneTimePrice && { oneTimePrice: parseFloat(oneTimePrice) }),
        ...(upgradePrice && { upgradePrice: parseFloat(upgradePrice) }),
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['community', id] })
      toast.success('Prices saved')
    },
    onError: (err) => toast.error((err as Error).message),
  })

  const showSubscription = model === 'SUBSCRIPTION'
  const showOneTime = model === 'ONE_TIME'
  const showUpgrade = model === 'FREEMIUM'
  const showPrices = showSubscription || showOneTime || showUpgrade

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-semibold text-foreground">Pricing</h1>
        <p className="mt-1 text-sm text-muted-foreground">Choose how members pay to join your community.</p>
      </div>

      {/* Pricing model */}
      <div className="rounded-xl border border-border bg-card p-6 space-y-4">
        <h2 className="text-sm font-semibold text-foreground">Pricing model</h2>
        <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
          {MODELS.map((m) => (
            <button
              key={m.value}
              type="button"
              onClick={() => setModel(m.value)}
              className={`rounded-lg border p-4 text-left transition-colors ${
                model === m.value
                  ? 'border-primary bg-primary/5'
                  : 'border-border hover:border-primary/40'
              }`}
            >
              <p className="text-sm font-medium text-foreground">{m.label}</p>
              <p className="mt-0.5 text-xs text-muted-foreground">{m.description}</p>
            </button>
          ))}
        </div>

        <div className="flex justify-end">
          <Button
            onClick={() => saveModel()}
            disabled={savingModel || model === community?.pricingModel}
            size="sm"
          >
            {savingModel ? 'Saving...' : 'Save model'}
          </Button>
        </div>
      </div>

      {/* Price inputs */}
      {showPrices && (
        <div className="rounded-xl border border-border bg-card p-6 space-y-4">
          <h2 className="text-sm font-semibold text-foreground">Prices</h2>

          {showSubscription && (
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <Label htmlFor="monthly">Monthly price (USD)</Label>
                <Input
                  id="monthly"
                  type="number"
                  min="0"
                  step="0.01"
                  value={monthlyPrice}
                  onChange={(e) => setMonthlyPrice(e.target.value)}
                  placeholder="e.g. 29"
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="yearly">Yearly price (USD)</Label>
                <Input
                  id="yearly"
                  type="number"
                  min="0"
                  step="0.01"
                  value={yearlyPrice}
                  onChange={(e) => setYearlyPrice(e.target.value)}
                  placeholder="e.g. 249"
                />
              </div>
            </div>
          )}

          {showOneTime && (
            <div className="space-y-1.5">
              <Label htmlFor="onetime">One-time price (USD)</Label>
              <Input
                id="onetime"
                type="number"
                min="0"
                step="0.01"
                value={oneTimePrice}
                onChange={(e) => setOneTimePrice(e.target.value)}
                placeholder="e.g. 99"
              />
            </div>
          )}

          {showUpgrade && (
            <div className="space-y-1.5">
              <Label htmlFor="upgrade">Upgrade price (USD)</Label>
              <Input
                id="upgrade"
                type="number"
                min="0"
                step="0.01"
                value={upgradePrice}
                onChange={(e) => setUpgradePrice(e.target.value)}
                placeholder="e.g. 49"
              />
              <p className="text-xs text-muted-foreground">One-time fee for free-tier members to unlock premium content.</p>
            </div>
          )}

          <div className="flex justify-end">
            <Button onClick={() => savePrices()} disabled={savingPrices} size="sm">
              {savingPrices ? 'Saving...' : 'Save prices'}
            </Button>
          </div>
        </div>
      )}
    </div>
  )
}
