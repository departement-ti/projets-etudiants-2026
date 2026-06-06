import { useEffect, useRef, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { CheckCircle, XCircle, Loader2 } from 'lucide-react'
import { AuthLayout } from '../components/AuthLayout'
import { Button } from '@/components/ui/button'
import { authApi } from '@/api/auth'

type Status = 'loading' | 'success' | 'error'

export function VerifyEmail() {
  const [searchParams] = useSearchParams()
  const [status, setStatus] = useState<Status>('loading')
  const [message, setMessage] = useState('')
  const navigate = useNavigate()
  // Prevent StrictMode double-fire from calling the endpoint twice
  const called = useRef(false)

  useEffect(() => {
    if (called.current) return
    called.current = true

    const token = searchParams.get('token')
    if (!token) {
      setStatus('error')
      setMessage('No verification token found in the URL.')
      return
    }

    authApi
      .verifyEmail(token)
      .then((res) => {
        setStatus('success')
        setMessage(res.message)
        // Auto-redirect to sign-in after 2 seconds
        setTimeout(() => navigate('/sign-in', {
          state: { message: 'Email verified! You can now sign in.' },
        }), 2000)
      })
      .catch((err: Error) => {
        setStatus('error')
        setMessage(err.message)
      })
  }, [searchParams, navigate])

  return (
    <AuthLayout title="Email verification">
      <div className="flex flex-col items-center gap-4 py-4 text-center">
        {status === 'loading' && (
          <>
            <Loader2 className="h-12 w-12 animate-spin text-primary" />
            <p className="text-sm text-muted-foreground">Verifying your email…</p>
          </>
        )}

        {status === 'success' && (
          <>
            <CheckCircle className="h-12 w-12 text-green-500" />
            <p className="text-sm text-foreground">{message}</p>
            <p className="text-xs text-muted-foreground">Redirecting to sign in…</p>
            <Button asChild className="mt-2 w-full">
              <Link to="/sign-in">Continue to sign in</Link>
            </Button>
          </>
        )}

        {status === 'error' && (
          <>
            <XCircle className="h-12 w-12 text-destructive" />
            <p className="text-sm text-foreground">{message}</p>
            <Button asChild variant="outline" className="mt-2 w-full">
              <Link to="/sign-in">Back to sign in</Link>
            </Button>
          </>
        )}
      </div>
    </AuthLayout>
  )
}
