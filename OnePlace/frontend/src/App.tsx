import { useEffect } from 'react'
import { RouterProvider } from 'react-router-dom'
import { QueryClientProvider } from '@tanstack/react-query'
import { Toaster } from 'sonner'
import { router } from '@/routes'
import { queryClient } from '@/lib/queryClient'
import { useAuthStore } from '@/store/auth.store'
import { authApi } from '@/api/auth'

function AuthLoader() {
  const { setUser } = useAuthStore()

  useEffect(() => {
    authApi
      .me()
      .then((res) => setUser(res.data?.user ?? null))
      .catch(() => setUser(null))
  }, [setUser])

  return null
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthLoader />
      <RouterProvider router={router} />
      <Toaster
        theme="dark"
        toastOptions={{
          style: {
            background: '#1E1A2E',
            border: '1px solid #2A2440',
            color: '#F9FAFB',
          },
        }}
      />
    </QueryClientProvider>
  )
}
