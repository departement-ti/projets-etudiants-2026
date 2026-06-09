import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { ArrowLeft, Loader2, MailCheck } from 'lucide-react'
import { toast } from 'sonner'
import { AuthLayout } from '../components/AuthLayout'
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { authApi } from '@/api/auth'

const schema = z.object({
  email: z.string().email('Invalid email address'),
})
type FormValues = z.infer<typeof schema>

export function ForgotPassword() {
  const [sent, setSent] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)

  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { email: '' },
  })

  async function onSubmit(values: FormValues) {
    setIsSubmitting(true)
    try {
      await authApi.forgotPassword(values.email)
      setSent(true)
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Something went wrong')
    } finally {
      setIsSubmitting(false)
    }
  }

  if (sent) {
    return (
      <AuthLayout title="Check your email">
        <div className="flex flex-col items-center gap-4 py-4 text-center">
          <MailCheck className="h-12 w-12 text-primary" />
          <p className="text-sm text-muted-foreground">
            If an account with that email exists, we&apos;ve sent a password reset link. Check your
            inbox.
          </p>
          <Button asChild variant="outline" className="mt-2 w-full">
            <Link to="/sign-in">
              <ArrowLeft className="h-4 w-4" />
              Back to sign in
            </Link>
          </Button>
        </div>
      </AuthLayout>
    )
  }

  return (
    <AuthLayout
      title="Forgot password"
      subtitle="Enter your email and we'll send you a reset link"
    >
      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
          <FormField
            control={form.control}
            name="email"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Email</FormLabel>
                <FormControl>
                  <Input type="email" placeholder="you@example.com" autoComplete="email" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <Button type="submit" className="w-full" disabled={isSubmitting}>
            {isSubmitting && <Loader2 className="h-4 w-4 animate-spin" />}
            Send reset link
          </Button>
        </form>
      </Form>

      <div className="mt-6 text-center">
        <Link
          to="/sign-in"
          className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground transition-colors"
        >
          <ArrowLeft className="h-3 w-3" />
          Back to sign in
        </Link>
      </div>
    </AuthLayout>
  )
}
