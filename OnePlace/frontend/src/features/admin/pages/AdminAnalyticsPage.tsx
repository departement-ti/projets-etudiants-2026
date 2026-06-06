import { useQuery } from '@tanstack/react-query'
import { Users, Building2, DollarSign } from 'lucide-react'
import { adminApi } from '@/api/admin'
import type { MonthDataPoint } from '@/types/community'

// ─── Helpers ──────────────────────────────────────────────────────────────────

function formatMonthLabel(key: string) {
  const [year, month] = key.split('-')
  return new Date(Number(year), Number(month) - 1, 1).toLocaleDateString('en-US', {
    month: 'short',
  })
}

function formatCurrency(v: number) {
  if (v >= 1_000_000) return `$${(v / 1_000_000).toFixed(1)}M`
  if (v >= 1_000) return `$${(v / 1_000).toFixed(1)}K`
  return `$${v.toFixed(2)}`
}

function formatCount(v: number) {
  if (v >= 1_000_000) return `${(v / 1_000_000).toFixed(1)}M`
  if (v >= 1_000) return `${(v / 1_000).toFixed(1)}K`
  return String(v)
}

// ─── BarChart ─────────────────────────────────────────────────────────────────

function BarChart({
  data,
  formatValue = formatCount,
  color = 'bg-primary',
}: {
  data: MonthDataPoint[]
  formatValue?: (v: number) => string
  color?: string
}) {
  const max = Math.max(...data.map((d) => d.value), 1)

  return (
    <div className="space-y-2">
      <div className="flex items-end gap-1.5 h-28">
        {data.map(({ month, value }) => {
          const h = Math.round((value / max) * 112)
          return (
            <div key={month} className="flex flex-1 flex-col justify-end h-full">
              <div
                className={`w-full rounded-t-sm ${color} opacity-80`}
                style={{ height: h > 0 ? `${h}px` : '2px', minHeight: '2px' }}
              />
            </div>
          )
        })}
      </div>
      <div className="flex gap-1.5">
        {data.map(({ month, value }) => (
          <div key={month} className="flex-1 text-center">
            <div className="text-[10px] text-muted-foreground">{formatMonthLabel(month)}</div>
            <div className="text-[10px] font-medium text-foreground">{formatValue(value)}</div>
          </div>
        ))}
      </div>
    </div>
  )
}

// ─── StatCard ─────────────────────────────────────────────────────────────────

function StatCard({ label, value, sub }: { label: string; value: string; sub?: string }) {
  return (
    <div className="rounded-xl border border-border bg-card p-5">
      <p className="text-sm text-muted-foreground">{label}</p>
      <p className="mt-1 text-2xl font-bold text-foreground">{value}</p>
      {sub && <p className="mt-0.5 text-xs text-muted-foreground">{sub}</p>}
    </div>
  )
}

// ─── BreakdownList ────────────────────────────────────────────────────────────

function BreakdownList({
  title,
  rows,
}: {
  title: string
  rows: Array<{ label: string; value: string; share?: number }>
}) {
  return (
    <div className="rounded-xl border border-border bg-card p-5 space-y-4">
      <p className="text-sm font-semibold text-foreground">{title}</p>
      <div className="space-y-3">
        {rows.map(({ label, value, share }) => (
          <div key={label}>
            <div className="flex items-center justify-between text-sm">
              <span className="capitalize text-muted-foreground">{label}</span>
              <span className="font-medium text-foreground">{value}</span>
            </div>
            {share !== undefined && (
              <div className="mt-1 h-1 w-full rounded-full bg-muted">
                <div className="h-1 rounded-full bg-primary/70" style={{ width: `${share}%` }} />
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  )
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

function Skeleton() {
  return (
    <div className="space-y-6 animate-pulse">
      <div className="h-7 w-40 rounded bg-muted" />
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <div key={i} className="h-24 rounded-xl bg-muted" />
        ))}
      </div>
      <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
        {Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className="h-48 rounded-xl bg-muted" />
        ))}
      </div>
    </div>
  )
}

// ─── AdminAnalyticsPage ───────────────────────────────────────────────────────

export function AdminAnalyticsPage() {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['admin-analytics'],
    queryFn: adminApi.getAnalytics,
  })

  if (isLoading) return <Skeleton />

  if (isError || !data?.data) {
    return (
      <p className="py-8 text-center text-sm text-destructive">
        Failed to load analytics.
      </p>
    )
  }

  const { users, communities, revenue } = data.data

  const userBreakdown = [
    { label: 'verified', value: formatCount(users.verified), share: Math.round((users.verified / Math.max(users.total, 1)) * 100) },
    { label: 'unverified', value: formatCount(users.total - users.verified), share: Math.round(((users.total - users.verified) / Math.max(users.total, 1)) * 100) },
    { label: 'suspended', value: formatCount(users.suspended) },
  ]

  const communityBreakdown = [
    { label: 'total', value: formatCount(communities.total) },
    { label: 'active', value: formatCount(communities.active), share: Math.round((communities.active / Math.max(communities.total, 1)) * 100) },
    { label: 'new this month', value: `+${communities.newThisMonth}` },
  ]

  const revenueBreakdown = Object.entries(revenue.byInterval).map(([interval, amount]) => ({
    label: interval.toLowerCase().replace('_', '-'),
    value: formatCurrency(amount),
    share: revenue.total > 0 ? Math.round((amount / revenue.total) * 100) : 0,
  }))

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-semibold text-foreground">Platform Analytics</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Platform-wide overview for the last 6 months.
        </p>
      </div>

      {/* Summary stats */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <StatCard
          label="Total users"
          value={formatCount(users.total)}
          sub={`+${users.newThisMonth} this month`}
        />
        <StatCard
          label="Total communities"
          value={formatCount(communities.total)}
          sub={`${communities.active} active`}
        />
        <StatCard label="Total revenue" value={formatCurrency(revenue.total)} />
        <StatCard label="Revenue this month" value={formatCurrency(revenue.thisMonth)} />
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
        <div className="rounded-xl border border-border bg-card p-5 space-y-4">
          <div className="flex items-center gap-2">
            <Users className="h-4 w-4 text-muted-foreground" />
            <p className="text-sm font-semibold text-foreground">User growth</p>
          </div>
          <BarChart data={users.growthLast6Months} formatValue={formatCount} />
        </div>

        <div className="rounded-xl border border-border bg-card p-5 space-y-4">
          <div className="flex items-center gap-2">
            <Building2 className="h-4 w-4 text-muted-foreground" />
            <p className="text-sm font-semibold text-foreground">Community growth</p>
          </div>
          <BarChart
            data={communities.growthLast6Months}
            formatValue={formatCount}
            color="bg-violet-500"
          />
        </div>

        <div className="rounded-xl border border-border bg-card p-5 space-y-4">
          <div className="flex items-center gap-2">
            <DollarSign className="h-4 w-4 text-muted-foreground" />
            <p className="text-sm font-semibold text-foreground">Revenue</p>
          </div>
          <BarChart
            data={revenue.last6Months}
            formatValue={formatCurrency}
            color="bg-emerald-500"
          />
        </div>
      </div>

      {/* Breakdowns */}
      <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
        <BreakdownList title="Users" rows={userBreakdown} />
        <BreakdownList title="Communities" rows={communityBreakdown} />
        {revenueBreakdown.length > 0 ? (
          <BreakdownList title="Revenue by billing" rows={revenueBreakdown} />
        ) : (
          <div className="rounded-xl border border-border bg-card p-5 flex items-center justify-center">
            <p className="text-sm text-muted-foreground">No revenue yet.</p>
          </div>
        )}
      </div>
    </div>
  )
}
