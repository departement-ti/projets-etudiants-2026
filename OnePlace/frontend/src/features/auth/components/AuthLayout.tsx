import type { ReactNode } from 'react'
import { OnePlaceLogo } from '@/components/shared/OnePlaceLogo'

interface AuthLayoutProps {
  children: ReactNode
  title: string
  subtitle?: string
}

export function AuthLayout({ children, title, subtitle }: AuthLayoutProps) {
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="w-full max-w-[420px]">
        {/* Logo */}
        <div className="mb-8 flex flex-col items-center gap-2 text-center">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary shadow-lg shadow-primary/30">
            <OnePlaceLogo className="h-6 w-6 text-white" />
          </div>
          <span className="text-xl font-bold tracking-tight text-foreground">OnePlace</span>
        </div>

        {/* Card */}
        <div className="rounded-xl border border-border bg-card p-8 shadow-2xl shadow-black/40">
          <div className="mb-6 text-center">
            <h1 className="text-2xl font-bold text-foreground">{title}</h1>
            {subtitle && (
              <p className="mt-1.5 text-sm text-muted-foreground">{subtitle}</p>
            )}
          </div>
          {children}
        </div>
      </div>
    </div>
  )
}
