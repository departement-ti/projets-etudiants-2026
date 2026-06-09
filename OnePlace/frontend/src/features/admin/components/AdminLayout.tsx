import { NavLink, Navigate, Outlet, Link } from 'react-router-dom'
import { Users, Building2, BarChart2, ChevronLeft, ShieldAlert } from 'lucide-react'
import { cn } from '@/lib/utils'
import { useAuthStore } from '@/store/auth.store'

function AdminNavItem({
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

export function AdminLayout() {
  const { user, isLoading } = useAuthStore()

  if (isLoading) {
    return (
      <div className="flex h-screen items-center justify-center bg-background">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-border border-t-primary" />
      </div>
    )
  }

  if (!user || user.role !== 'moderator') {
    return <Navigate to="/communities" replace />
  }

  return (
    <div className="min-h-screen bg-background">
      <header className="sticky top-0 z-50 border-b border-border bg-background/90 backdrop-blur-md">
        <div className="mx-auto flex h-14 max-w-6xl items-center gap-3 px-4">
          <Link
            to="/communities"
            className="flex items-center gap-1 text-sm text-muted-foreground transition-colors hover:text-foreground"
          >
            <ChevronLeft className="h-4 w-4" />
            Communities
          </Link>
          <div className="h-5 w-px bg-border" />
          <div className="flex items-center gap-2">
            <ShieldAlert className="h-4 w-4 text-primary" />
            <span className="font-semibold text-foreground">Admin</span>
          </div>
        </div>
      </header>

      <div className="mx-auto flex max-w-6xl gap-8 px-4 py-8">
        {/* Desktop sidebar */}
        <nav className="hidden w-48 shrink-0 space-y-1 lg:block">
          <AdminNavItem to="/admin/users" icon={Users}>
            Users
          </AdminNavItem>
          <AdminNavItem to="/admin/communities" icon={Building2}>
            Communities
          </AdminNavItem>
          <AdminNavItem to="/admin/analytics" icon={BarChart2}>
            Analytics
          </AdminNavItem>
        </nav>

        {/* Mobile nav */}
        <div className="mb-6 flex w-full gap-2 lg:hidden">
          {[
            { to: '/admin/users', label: 'Users' },
            { to: '/admin/communities', label: 'Communities' },
            { to: '/admin/analytics', label: 'Analytics' },
          ].map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
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

        <main className="min-w-0 flex-1">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
