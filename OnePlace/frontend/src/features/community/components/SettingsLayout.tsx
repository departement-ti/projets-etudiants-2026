import { NavLink, Outlet, useParams, Link } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { ChevronLeft, Settings, DollarSign, Users, BookOpen } from 'lucide-react'
import { cn } from '@/lib/utils'
import { communityApi } from '@/api/community'

function SettingsNavItem({
  to,
  icon: Icon,
  children,
}: {
  to: string
  icon: React.ElementType
  children: React.ReactNode
}) {
  return (
    <NavLink
      to={to}
      className={({ isActive }) =>
        cn(
          'flex items-center gap-2.5 rounded-lg px-3 py-2 text-sm font-medium transition-colors',
          isActive
            ? 'bg-primary/10 text-primary'
            : 'text-muted-foreground hover:bg-muted hover:text-foreground',
        )
      }
    >
      <Icon className="h-4 w-4 shrink-0" />
      {children}
    </NavLink>
  )
}

export function SettingsLayout() {
  const { id } = useParams<{ id: string }>()

  const { data } = useQuery({
    queryKey: ['community', id],
    queryFn: () => communityApi.getById(id!),
    enabled: !!id,
  })

  const community = data?.data?.community

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="sticky top-0 z-50 border-b border-border bg-background/90 backdrop-blur-md">
        <div className="mx-auto flex h-14 max-w-5xl items-center gap-3 px-4">
          <Link
            to={`/communities/${id}/community`}
            className="flex items-center gap-1 text-sm text-muted-foreground transition-colors hover:text-foreground"
          >
            <ChevronLeft className="h-4 w-4" />
            {community?.name ?? 'Community'}
          </Link>
          <div className="h-5 w-px bg-border" />
          <span className="font-semibold text-foreground">Settings</span>
        </div>
      </header>

      <div className="mx-auto flex max-w-5xl gap-8 px-4 py-8">
        {/* Sidebar nav */}
        <nav className="hidden w-48 shrink-0 space-y-1 lg:block">
          <SettingsNavItem to={`/communities/${id}/settings/general`} icon={Settings}>
            General
          </SettingsNavItem>
          <SettingsNavItem to={`/communities/${id}/settings/pricing`} icon={DollarSign}>
            Pricing
          </SettingsNavItem>
          <SettingsNavItem to={`/communities/${id}/settings/members`} icon={Users}>
            Members
          </SettingsNavItem>
          <SettingsNavItem to={`/communities/${id}/settings/knowledge`} icon={BookOpen}>
            Knowledge Base
          </SettingsNavItem>
        </nav>

        {/* Mobile nav */}
        <div className="mb-6 flex gap-2 lg:hidden w-full">
          {[
            { to: 'general', label: 'General' },
            { to: 'pricing', label: 'Pricing' },
            { to: 'members', label: 'Members' },
            { to: 'knowledge', label: 'Knowledge' },
          ].map((item) => (
            <NavLink
              key={item.to}
              to={`/communities/${id}/settings/${item.to}`}
              className={({ isActive }) =>
                cn(
                  'flex-1 rounded-lg border px-3 py-2 text-center text-sm font-medium transition-colors',
                  isActive
                    ? 'border-primary bg-primary/5 text-primary'
                    : 'border-border text-muted-foreground hover:text-foreground',
                )
              }
            >
              {item.label}
            </NavLink>
          ))}
        </div>

        {/* Content */}
        <main className="min-w-0 flex-1">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
