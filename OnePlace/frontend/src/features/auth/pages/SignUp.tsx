import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Check, Eye, EyeOff, Loader2, X } from 'lucide-react'
import { toast } from 'sonner'
import { AuthLayout } from '../components/AuthLayout'
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { authApi } from '@/api/auth'

// ─── Password rules ────────────────────────────────────────────────────────────

const PASSWORD_RULES = [
  { id: 'length',  label: 'At least 8 characters',         test: (p: string) => p.length >= 8 },
  { id: 'upper',   label: 'One uppercase letter',           test: (p: string) => /[A-Z]/.test(p) },
  { id: 'number',  label: 'One number',                     test: (p: string) => /[0-9]/.test(p) },
  { id: 'special', label: 'One special character (!@#$…)',  test: (p: string) => /[^A-Za-z0-9]/.test(p) },
] as const

const schema = z.object({
  firstname: z.string().min(1, 'First name is required'),
  lastname:  z.string().min(1, 'Last name is required'),
  email:     z.string().email('Invalid email address'),
  password:  z
    .string()
    .min(8,          'At least 8 characters')
    .regex(/[A-Z]/,      'One uppercase letter required')
    .regex(/[0-9]/,      'One number required')
    .regex(/[^A-Za-z0-9]/, 'One special character required'),
})

type FormValues = z.infer<typeof schema>

// ─── PasswordChecklist ─────────────────────────────────────────────────────────

function PasswordChecklist({ value }: { value: string }) {
  if (!value) return null
  return (
    <ul className="mt-2 space-y-1">
      {PASSWORD_RULES.map((rule) => {
        const ok = rule.test(value)
        return (
          <li key={rule.id} className={`flex items-center gap-2 text-xs transition-colors ${ok ? 'text-emerald-500' : 'text-muted-foreground'}`}>
            {ok
              ? <Check className="h-3.5 w-3.5 shrink-0" />
              : <X    className="h-3.5 w-3.5 shrink-0 text-muted-foreground/60" />
            }
            {rule.label}
          </li>
        )
      })}
    </ul>
  )
}

// ─── SignUp ────────────────────────────────────────────────────────────────────

export function SignUp() {
  const [showPassword, setShowPassword] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const navigate = useNavigate()

  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { firstname: '', lastname: '', email: '', password: '' },
  })

  const passwordValue = form.watch('password')

  async function onSubmit(values: FormValues) {
    setIsSubmitting(true)
    try {
      await authApi.signUp(values)
      navigate('/sign-in', {
        state: { message: 'Account created! Please check your email to verify your account.' },
      })
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Sign up failed')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <AuthLayout title="Create your account" subtitle="Join thousands of creators on OnePlace">
      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <FormField
              control={form.control}
              name="firstname"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>First name</FormLabel>
                  <FormControl>
                    <Input placeholder="John" autoComplete="given-name" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField
              control={form.control}
              name="lastname"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Last name</FormLabel>
                  <FormControl>
                    <Input placeholder="Doe" autoComplete="family-name" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
          </div>

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

          <FormField
            control={form.control}
            name="password"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Password</FormLabel>
                <FormControl>
                  <div className="relative">
                    <Input
                      type={showPassword ? 'text' : 'password'}
                      placeholder="Create a strong password"
                      autoComplete="new-password"
                      {...field}
                    />
                    <button
                      type="button"
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground transition-colors hover:text-foreground"
                      onClick={() => setShowPassword((p) => !p)}
                      tabIndex={-1}
                    >
                      {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                </FormControl>
                <PasswordChecklist value={passwordValue} />
                <FormMessage />
              </FormItem>
            )}
          />

          <Button type="submit" className="w-full" disabled={isSubmitting}>
            {isSubmitting && <Loader2 className="h-4 w-4 animate-spin" />}
            Create account
          </Button>
        </form>
      </Form>

      <p className="mt-6 text-center text-sm text-muted-foreground">
        Already have an account?{' '}
        <Link to="/sign-in" className="font-medium text-primary hover:underline">
          Sign in
        </Link>
      </p>
    </AuthLayout>
  )
}
