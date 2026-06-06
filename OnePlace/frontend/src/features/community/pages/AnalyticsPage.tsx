import { useParams } from 'react-router-dom'
import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { TrendingUp, Users, DollarSign, Sparkles, AlertTriangle, Download, SmilePlus } from 'lucide-react'
import { toast } from 'sonner'
import { communityApi } from '@/api/community'
import { aiApi, type ChurnMember, type AnalyticsSummaryData, type SentimentData } from '@/api/ai'
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
      <div className="flex items-end gap-1.5 h-32">
        {data.map(({ month, value }) => {
          const h = max === 0 ? 0 : Math.round((value / max) * 128)
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

function StatCard({
  label,
  value,
  sub,
}: {
  label: string
  value: string
  sub?: string
}) {
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
              <span className="text-muted-foreground capitalize">{label}</span>
              <span className="font-medium text-foreground">{value}</span>
            </div>
            {share !== undefined && (
              <div className="mt-1 h-1 w-full rounded-full bg-muted">
                <div
                  className="h-1 rounded-full bg-primary/70"
                  style={{ width: `${share}%` }}
                />
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  )
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

function AnalyticsSkeleton() {
  return (
    <div className="space-y-6 animate-pulse">
      <div className="h-7 w-40 rounded bg-muted" />
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <div key={i} className="h-24 rounded-xl bg-muted" />
        ))}
      </div>
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
        <div className="h-52 rounded-xl bg-muted" />
        <div className="h-52 rounded-xl bg-muted" />
      </div>
      <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
        {Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className="h-40 rounded-xl bg-muted" />
        ))}
      </div>
    </div>
  )
}


// ─── AI Summary Card ──────────────────────────────────────────────────────────

function AISummaryCard({ communityId }: { communityId: string }) {
  const { data, isLoading, refetch, isFetching } = useQuery({
    queryKey: ['ai-analytics-summary', communityId],
    queryFn: () => aiApi.getAnalyticsSummary(communityId),
    enabled: false,
    staleTime: 5 * 60 * 1000,
  })

  const summary = data?.data as AnalyticsSummaryData | undefined

  function downloadCSV() {
    if (!summary) return
    const d = summary.data
    const rows = [
      ['Metric', 'Value'],
      ['Total members', d.totalMembers],
      ['Active members', d.activeMembers],
      ['New this month', d.newThisMonth],
      ['New last month', d.newLastMonth],
      ['Growth %', `${d.growthPct}%`],
      ['Revenue this month', `$${d.revenueThisMonth.toFixed(2)}`],
      ['Revenue last month', `$${d.revenueLastMonth.toFixed(2)}`],
      ['Total revenue', `$${d.totalRevenue.toFixed(2)}`],
      ['Posts this month', d.postsThisMonth],
      ['Comments this month', d.commentsThisMonth],
      ['Likes this month', d.likesThisMonth],
    ]
    const csv = rows.map((r) => r.join(',')).join('\n')
    const blob = new Blob([csv], { type: 'text/csv' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `analytics-${communityId}.csv`
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div className="rounded-xl border border-border bg-card p-5 space-y-4">
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-2">
          <Sparkles className="h-4 w-4 text-primary" />
          <p className="text-sm font-semibold text-foreground">AI Analytics Summary</p>
        </div>
        <div className="flex items-center gap-2">
          {summary && (
            <button
              onClick={downloadCSV}
              className="flex items-center gap-1.5 rounded-lg border border-border px-3 py-1.5 text-xs font-medium text-foreground hover:bg-muted"
            >
              <Download className="h-3.5 w-3.5" />
              Export CSV
            </button>
          )}
          <button
            onClick={() => refetch()}
            disabled={isFetching}
            className="rounded-lg bg-primary px-3 py-1.5 text-xs font-semibold text-white disabled:opacity-50 hover:opacity-90"
          >
            {isFetching ? 'Generating...' : summary ? 'Regenerate' : 'Generate summary'}
          </button>
        </div>
      </div>

      {isFetching && (
        <div className="space-y-2 animate-pulse">
          <div className="h-3.5 w-full rounded bg-muted" />
          <div className="h-3.5 w-5/6 rounded bg-muted" />
          <div className="h-3.5 w-4/6 rounded bg-muted" />
        </div>
      )}

      {summary && !isFetching && (
        <p className="text-sm leading-relaxed text-muted-foreground">{summary.summary}</p>
      )}

      {!summary && !isFetching && (
        <p className="text-xs text-muted-foreground">
          Click "Generate summary" to get an AI-written overview of this month's performance.
        </p>
      )}
    </div>
  )
}

// ─── Churn Risk Card ──────────────────────────────────────────────────────────

function ChurnRiskCard({ communityId }: { communityId: string }) {
  const { data, isLoading, refetch, isFetching } = useQuery({
    queryKey: ['churn-risk', communityId],
    queryFn: () => aiApi.getChurnRisk(communityId),
    enabled: false,
    staleTime: 10 * 60 * 1000,
  })

  const churn = data?.data as { atRisk: ChurnMember[]; summary: string } | undefined

  const riskColor = (level: string) =>
    level === 'high'
      ? 'bg-red-500/10 text-red-600 border-red-200'
      : 'bg-amber-500/10 text-amber-600 border-amber-200'

  return (
    <div className="rounded-xl border border-border bg-card p-5 space-y-4">
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-2">
          <AlertTriangle className="h-4 w-4 text-amber-500" />
          <p className="text-sm font-semibold text-foreground">Churn Risk</p>
        </div>
        <button
          onClick={() => refetch()}
          disabled={isFetching}
          className="rounded-lg bg-amber-500 px-3 py-1.5 text-xs font-semibold text-white disabled:opacity-50 hover:opacity-90"
        >
          {isFetching ? 'Analyzing...' : churn ? 'Refresh' : 'Analyze members'}
        </button>
      </div>

      {isFetching && (
        <div className="space-y-2 animate-pulse">
          {[1, 2, 3].map((i) => <div key={i} className="h-10 rounded bg-muted" />)}
        </div>
      )}

      {churn && !isFetching && (
        <>
          <p className="text-sm text-muted-foreground leading-relaxed">{churn.summary}</p>
          {churn.atRisk.length > 0 ? (
            <div className="space-y-2">
              {churn.atRisk.map((m) => (
                <div
                  key={m.userId}
                  className={`flex items-center justify-between rounded-lg border p-3 ${riskColor(m.riskLevel)}`}
                >
                  <div>
                    <p className="text-sm font-medium">{m.name}</p>
                    <p className="text-xs opacity-70">
                      {m.posts} posts · {m.comments} comments in 30 days
                      {m.expiringIn7Days && ' · sub expiring'}
                    </p>
                  </div>
                  <span className="shrink-0 rounded-full border px-2 py-0.5 text-xs font-semibold capitalize">
                    {m.riskLevel}
                  </span>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-sm text-emerald-600">No at-risk members detected.</p>
          )}
        </>
      )}

      {!churn && !isFetching && (
        <p className="text-xs text-muted-foreground">
          Click "Analyze members" to identify members at risk of churning based on engagement signals.
        </p>
      )}
    </div>
  )
}

// ─── Sentiment Card ───────────────────────────────────────────────────────────

function SentimentCard({ communityId }: { communityId: string }) {
  const { data, refetch, isFetching } = useQuery({
    queryKey: ['ai-sentiment', communityId],
    queryFn: () => aiApi.getSentiment(communityId),
    enabled: false,
    staleTime: 15 * 60 * 1000,
  })

  const sentiment = data?.data as SentimentData | undefined

  const overallColor =
    sentiment?.overall === 'positive'
      ? 'text-emerald-600'
      : sentiment?.overall === 'negative'
      ? 'text-red-500'
      : 'text-amber-500'

  const barColor = (key: keyof SentimentData['breakdown']) =>
    key === 'positive' ? 'bg-emerald-500' : key === 'negative' ? 'bg-red-400' : 'bg-amber-400'

  return (
    <div className="rounded-xl border border-border bg-card p-5 space-y-4">
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-2">
          <SmilePlus className="h-4 w-4 text-primary" />
          <p className="text-sm font-semibold text-foreground">Community Sentiment</p>
        </div>
        <button
          onClick={() => refetch()}
          disabled={isFetching}
          className="rounded-lg bg-primary px-3 py-1.5 text-xs font-semibold text-white disabled:opacity-50 hover:opacity-90"
        >
          {isFetching ? 'Analyzing...' : sentiment ? 'Refresh' : 'Analyze'}
        </button>
      </div>

      {isFetching && (
        <div className="space-y-2 animate-pulse">
          <div className="h-3.5 w-1/3 rounded bg-muted" />
          <div className="h-2 w-full rounded bg-muted" />
          <div className="h-2 w-full rounded bg-muted" />
          <div className="h-2 w-full rounded bg-muted" />
        </div>
      )}

      {sentiment && !isFetching && (
        <>
          <div className="flex items-center gap-2">
            <span className={`text-lg font-bold capitalize ${overallColor}`}>
              {sentiment.overall}
            </span>
            <span className="text-xs text-muted-foreground">
              · {sentiment.postCount} posts analyzed
            </span>
          </div>

          <div className="space-y-2">
            {(['positive', 'neutral', 'negative'] as const).map((key) => (
              <div key={key}>
                <div className="flex justify-between text-xs mb-1">
                  <span className="capitalize text-muted-foreground">{key}</span>
                  <span className="font-medium text-foreground">{sentiment.breakdown[key]}%</span>
                </div>
                <div className="h-1.5 w-full rounded-full bg-muted">
                  <div
                    className={`h-1.5 rounded-full ${barColor(key)}`}
                    style={{ width: `${sentiment.breakdown[key]}%` }}
                  />
                </div>
              </div>
            ))}
          </div>

          {sentiment.themes.length > 0 && (
            <div className="flex flex-wrap gap-1.5">
              {sentiment.themes.map((t) => (
                <span
                  key={t}
                  className="rounded-full border border-border bg-muted px-2.5 py-0.5 text-xs text-foreground/80"
                >
                  {t}
                </span>
              ))}
            </div>
          )}

          <p className="text-sm leading-relaxed text-muted-foreground">{sentiment.summary}</p>
        </>
      )}

      {!sentiment && !isFetching && (
        <p className="text-xs text-muted-foreground">
          Click "Analyze" to get an AI sentiment breakdown of your community's recent posts.
        </p>
      )}
    </div>
  )
}

// ─── AnalyticsPage ────────────────────────────────────────────────────────────

export function AnalyticsPage() {
  const { id } = useParams<{ id: string }>()

  const { data, isLoading, isError } = useQuery({
    queryKey: ['analytics', id],
    queryFn: () => communityApi.getAnalytics(id!),
    enabled: !!id,
  })

  if (isLoading) return <AnalyticsSkeleton />

  if (isError) {
    return (
      <div className="flex flex-col items-center justify-center py-20 gap-2">
        <TrendingUp className="h-8 w-8 text-muted-foreground" />
        <p className="text-sm text-muted-foreground">
          Analytics are only available to creators and admins.
        </p>
      </div>
    )
  }

  const analytics = data?.data
  if (!analytics) return null

  const { members, revenue } = analytics

  const totalMembers = members.total
  const byStatusRows = Object.entries(members.byStatus).map(([status, count]) => ({
    label: status.toLowerCase(),
    value: formatCount(count),
    share: totalMembers > 0 ? Math.round((count / totalMembers) * 100) : 0,
  }))

  const byTierRows = Object.entries(members.byTier).map(([tier, count]) => ({
    label: tier.toLowerCase(),
    value: formatCount(count),
    share: totalMembers > 0 ? Math.round((count / totalMembers) * 100) : 0,
  }))

  const totalRevenue = revenue.total
  const byIntervalRows = Object.entries(revenue.byInterval).map(([interval, amount]) => ({
    label: interval.toLowerCase().replace('_', '-'),
    value: formatCurrency(amount),
    share: totalRevenue > 0 ? Math.round((amount / totalRevenue) * 100) : 0,
  }))

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-xl font-semibold text-foreground">Analytics</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Member and revenue overview for the last 6 months.
        </p>
      </div>

      {/* Summary stats */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <StatCard
          label="Total members"
          value={formatCount(members.total)}
          sub={`${members.active} active`}
        />
        <StatCard
          label="New this month"
          value={`+${members.newThisMonth}`}
        />
        <StatCard
          label="Total revenue"
          value={formatCurrency(revenue.total)}
        />
        <StatCard
          label="Revenue this month"
          value={formatCurrency(revenue.thisMonth)}
        />
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
        <div className="rounded-xl border border-border bg-card p-5 space-y-4">
          <div className="flex items-center gap-2">
            <Users className="h-4 w-4 text-muted-foreground" />
            <p className="text-sm font-semibold text-foreground">Member growth</p>
          </div>
          <BarChart data={members.growthLast6Months} formatValue={formatCount} />
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
        {byStatusRows.length > 0 && (
          <BreakdownList title="By status" rows={byStatusRows} />
        )}
        {byTierRows.length > 0 && (
          <BreakdownList title="By tier" rows={byTierRows} />
        )}
        {byIntervalRows.length > 0 ? (
          <BreakdownList title="Revenue by billing" rows={byIntervalRows} />
        ) : (
          <div className="rounded-xl border border-border bg-card p-5 flex items-center justify-center">
            <p className="text-sm text-muted-foreground">No revenue yet.</p>
          </div>
        )}
      </div>

      {/* AI Features */}
      <AISummaryCard communityId={id!} />
      <ChurnRiskCard communityId={id!} />
      <SentimentCard communityId={id!} />
    </div>
  )
}
