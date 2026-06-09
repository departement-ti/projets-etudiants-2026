import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import { toast } from 'sonner'
import { ChevronLeft } from 'lucide-react'
import { communityApi } from '@/api/community'
import type { PlatformPlan } from '@/types/community'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

const PLANS: { value: PlatformPlan; label: string; description: string }[] = [
  {
    value: 'BASIC',
    label: 'Basic',
    description: 'Community feed and free courses. No paid access.',
  },
  {
    value: 'PRO',
    label: 'Pro',
    description: 'Everything in Basic + paid memberships, premium courses, and analytics.',
  },
]

export function CreateCommunity() {
  const navigate = useNavigate()
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [plan, setPlan] = useState<PlatformPlan>('BASIC')

  const { mutate: create, isPending, error } = useMutation({
    mutationFn: () => communityApi.create({ name, description: description || undefined, platformPlan: plan }),
    onSuccess: (res) => {
      const communityId = res.data?.community.id
      if (communityId) navigate(`/communities/${communityId}/about`)
    },
    onError: (err) => toast.error((err as Error).message),
  })

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    create()
  }

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b border-border bg-background/90 backdrop-blur-md">
        <div className="mx-auto flex h-14 max-w-2xl items-center gap-3 px-4">
          <Link
            to="/communities"
            className="flex items-center gap-1 text-sm text-muted-foreground transition-colors hover:text-foreground"
          >
            <ChevronLeft className="h-4 w-4" />
            Back
          </Link>
          <div className="h-5 w-px bg-border" />
          <span className="font-semibold text-foreground">Create community</span>
        </div>
      </header>

      <div className="mx-auto max-w-2xl px-4 py-10">
        <form onSubmit={handleSubmit} className="space-y-8">
          {/* Basic info */}
          <div className="rounded-xl border border-border bg-card p-6 space-y-5">
            <h2 className="font-semibold text-foreground">Basic info</h2>

            <div className="space-y-1.5">
              <Label htmlFor="name">Community name <span className="text-destructive">*</span></Label>
              <Input
                id="name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g. AI Builders Club"
                required
              />
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="description">
                Description <span className="text-muted-foreground">(optional)</span>
              </Label>
              <textarea
                id="description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="What's your community about?"
                rows={3}
                className="w-full resize-none rounded-md border border-border bg-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 focus:ring-offset-background"
              />
            </div>
          </div>

          {/* Platform plan */}
          <div className="rounded-xl border border-border bg-card p-6 space-y-4">
            <h2 className="font-semibold text-foreground">Platform plan</h2>
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              {PLANS.map((p) => (
                <button
                  key={p.value}
                  type="button"
                  onClick={() => setPlan(p.value)}
                  className={`rounded-lg border p-4 text-left transition-colors ${
                    plan === p.value
                      ? 'border-primary bg-primary/5'
                      : 'border-border hover:border-primary/40'
                  }`}
                >
                  <p className="font-medium text-foreground">{p.label}</p>
                  <p className="mt-1 text-sm text-muted-foreground">{p.description}</p>
                </button>
              ))}
            </div>
          </div>

          {error && (
            <p className="text-sm text-destructive">{(error as Error).message}</p>
          )}

          <div className="flex justify-end">
            <Button type="submit" disabled={isPending || !name.trim()}>
              {isPending ? 'Creating...' : 'Create community'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  )
}
