import { Link, useNavigate } from 'react-router-dom'
import { OnePlaceLogo } from '@/components/shared/OnePlaceLogo'
import { ChevronDown } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { NotificationBell } from '@/components/shared/NotificationBell'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { useAuthStore } from '@/store/auth.store'
import { authApi } from '@/api/auth'

function UserMenu() {
  const { user, clear } = useAuthStore()
  const navigate = useNavigate()

  async function handleSignOut() {
    try {
      await authApi.signOut()
    } finally {
      clear()
      navigate('/sign-in')
    }
  }

  if (!user) return null

  const initials = `${user.firstname[0]}${user.lastname[0]}`.toUpperCase()

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <button className="flex items-center gap-2 rounded-lg px-2 py-1 transition-colors hover:bg-muted focus:outline-none">
          {user.avatarUrl ? (
            <img
              src={user.avatarUrl}
              alt={user.firstname}
              className="h-7 w-7 rounded-full object-cover"
            />
          ) : (
            <div className="flex h-7 w-7 items-center justify-center rounded-full bg-primary text-xs font-bold text-white">
              {initials}
            </div>
          )}
          <span className="hidden text-sm font-medium text-foreground sm:block">
            {user.firstname}
          </span>
          <ChevronDown className="h-3.5 w-3.5 text-muted-foreground" />
        </button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-48">
        <DropdownMenuLabel>
          {user.firstname} {user.lastname}
        </DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuItem asChild>
          <Link to="/profile">Profile</Link>
        </DropdownMenuItem>
        <DropdownMenuSeparator />
        <DropdownMenuItem
          onClick={handleSignOut}
          className="text-destructive focus:text-destructive"
        >
          Sign out
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

export function PublicNav() {
  const user = useAuthStore((s) => s.user)

  return (
    <header className="sticky top-0 z-50 border-b border-border bg-background/80 backdrop-blur-md">
      <div className="mx-auto flex h-14 max-w-7xl items-center justify-between px-4">
        <Link to="/communities" className="flex items-center gap-2">
          <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-primary">
            <OnePlaceLogo className="h-4 w-4 text-white" />
          </div>
          <span className="font-bold text-foreground">OnePlace</span>
        </Link>

        <div className="flex items-center gap-2">
          {user ? (
            <>
              <NotificationBell />
              <UserMenu />
            </>
          ) : (
            <>
              <Link to="/sign-in">
                <Button variant="ghost" size="sm">Log in</Button>
              </Link>
              <Link to="/sign-up">
                <Button size="sm">Sign up</Button>
              </Link>
            </>
          )}
        </div>
      </div>
    </header>
  )
}
