import { useEffect } from 'react'
import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { useAuthStore } from '@/store/auth.store'
import { authApi } from '@/api/auth'

export function AuthGuard() {
  const { user, isLoading, setUser } = useAuthStore()
  const location = useLocation()

  useEffect(() => {
    authApi
      .me()
      .then((res) => setUser(res.data?.user ?? null))
      .catch(() => setUser(null))
  }, [setUser])

  if (isLoading) {
    return (
      <div className="flex h-screen items-center justify-center bg-background">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-border border-t-primary" />
      </div>
    )
  }

  if (!user)
    return <Navigate to="/sign-in" state={{ from: location.pathname }} replace />

  return <Outlet />
}
