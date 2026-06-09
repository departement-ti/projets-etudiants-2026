import { useEffect, useRef, useState } from 'react'
import { useMutation } from '@tanstack/react-query'
import { toast } from 'sonner'
import { Camera, Trash2 } from 'lucide-react'
import { userApi } from '@/api/user'
import { useAuthStore } from '@/store/auth.store'
import { uploadFile } from '@/api/upload'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

export function ProfilePage() {
  const { user, setUser } = useAuthStore()
  const fileInputRef = useRef<HTMLInputElement>(null)

  const [firstname, setFirstname] = useState('')
  const [lastname, setLastname] = useState('')

  const [currentPassword, setCurrentPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [passwordError, setPasswordError] = useState('')

  useEffect(() => {
    if (user) {
      setFirstname(user.firstname)
      setLastname(user.lastname)
    }
  }, [user])

  const { mutate: saveName, isPending: isSavingName } = useMutation({
    mutationFn: () => userApi.updateMe({ firstname, lastname }),
    onSuccess: (res) => {
      if (res.data?.user) setUser(res.data.user)
      toast.success('Profile updated')
    },
    onError: (err) => toast.error((err as Error).message),
  })

  const { mutate: saveAvatar, isPending: isSavingAvatar } = useMutation({
    mutationFn: (avatarUrl: string | null) => userApi.updateMe({ avatarUrl }),
    onSuccess: (res) => {
      if (res.data?.user) setUser(res.data.user)
      toast.success(res.data?.user?.avatarUrl ? 'Photo updated' : 'Photo removed')
    },
    onError: (err) => toast.error((err as Error).message),
  })

  const {
    mutate: savePassword,
    isPending: isSavingPassword,
    reset: resetPasswordMutation,
  } = useMutation({
    mutationFn: () => userApi.updateMe({ currentPassword, newPassword }),
    onSuccess: () => {
      setCurrentPassword('')
      setNewPassword('')
      setConfirmPassword('')
      toast.success('Password updated')
    },
    onError: (err) => toast.error((err as Error).message),
  })

  async function handleAvatarChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    e.target.value = ''
    try {
      const url = await uploadFile(file, 'avatars')
      saveAvatar(url)
    } catch (err) {
      toast.error((err as Error).message ?? 'Failed to upload image')
    }
  }

  function handlePasswordSubmit() {
    setPasswordError('')
    resetPasswordMutation()
    if (!currentPassword) return setPasswordError('Current password is required.')
    if (newPassword.length < 8) return setPasswordError('New password must be at least 8 characters.')
    if (newPassword !== confirmPassword) return setPasswordError('Passwords do not match.')
    savePassword()
  }

  const initials = user ? `${user.firstname[0]}${user.lastname[0]}`.toUpperCase() : ''

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-semibold text-foreground">Profile</h1>
        <p className="mt-1 text-sm text-muted-foreground">Your name and account details.</p>
      </div>

      {/* Avatar */}
      <div className="rounded-xl border border-border bg-card p-6">
        <h2 className="text-base font-semibold text-foreground mb-4">Profile photo</h2>
        <div className="flex items-center gap-5">
          <div className="relative">
            {user?.avatarUrl ? (
              <img
                src={user.avatarUrl}
                alt={user.firstname}
                className="h-20 w-20 rounded-full object-cover ring-2 ring-border"
              />
            ) : (
              <div className="flex h-20 w-20 items-center justify-center rounded-full bg-primary text-xl font-bold text-white ring-2 ring-border">
                {initials}
              </div>
            )}
            <button
              onClick={() => fileInputRef.current?.click()}
              disabled={isSavingAvatar}
              className="absolute -bottom-1 -right-1 flex h-7 w-7 items-center justify-center rounded-full border-2 border-background bg-primary text-white shadow-sm hover:bg-primary/90 transition-colors"
            >
              <Camera className="h-3.5 w-3.5" />
            </button>
          </div>

          <div className="space-y-1.5">
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => fileInputRef.current?.click()}
                disabled={isSavingAvatar}
              >
                {isSavingAvatar ? 'Uploading...' : 'Upload photo'}
              </Button>
              {user?.avatarUrl && (
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => saveAvatar(null)}
                  disabled={isSavingAvatar}
                  className="text-destructive hover:text-destructive"
                >
                  <Trash2 className="h-4 w-4" />
                </Button>
              )}
            </div>
            <p className="text-xs text-muted-foreground">JPG, PNG or GIF. Max display size 256×256px.</p>
          </div>
        </div>
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          className="hidden"
          onChange={handleAvatarChange}
        />
      </div>

      {/* Account info */}
      <div className="rounded-xl border border-border bg-card p-6 space-y-5">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div className="space-y-1.5">
            <Label htmlFor="firstname">First name</Label>
            <Input
              id="firstname"
              value={firstname}
              onChange={(e) => setFirstname(e.target.value)}
              placeholder="First name"
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="lastname">Last name</Label>
            <Input
              id="lastname"
              value={lastname}
              onChange={(e) => setLastname(e.target.value)}
              placeholder="Last name"
            />
          </div>
        </div>

        <div className="space-y-1.5">
          <Label>Email</Label>
          <Input value={user?.email ?? ''} disabled />
        </div>

        <div className="flex justify-end">
          <Button
            onClick={() => saveName()}
            disabled={isSavingName || !firstname.trim() || !lastname.trim()}
          >
            {isSavingName ? 'Saving...' : 'Save changes'}
          </Button>
        </div>
      </div>

      {/* Change password */}
      <div className="rounded-xl border border-border bg-card p-6 space-y-5">
        <div>
          <h2 className="text-base font-semibold text-foreground">Change password</h2>
          <p className="mt-0.5 text-sm text-muted-foreground">Must be at least 8 characters.</p>
        </div>

        <div className="space-y-1.5">
          <Label htmlFor="current-password">Current password</Label>
          <Input
            id="current-password"
            type="password"
            value={currentPassword}
            onChange={(e) => setCurrentPassword(e.target.value)}
            placeholder="Current password"
          />
        </div>

        <div className="space-y-1.5">
          <Label htmlFor="new-password">New password</Label>
          <Input
            id="new-password"
            type="password"
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
            placeholder="New password"
          />
        </div>

        <div className="space-y-1.5">
          <Label htmlFor="confirm-password">Confirm new password</Label>
          <Input
            id="confirm-password"
            type="password"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            placeholder="Confirm new password"
          />
        </div>

        {passwordError && (
          <p className="text-sm text-destructive">{passwordError}</p>
        )}

        <div className="flex justify-end">
          <Button onClick={handlePasswordSubmit} disabled={isSavingPassword}>
            {isSavingPassword ? 'Updating...' : 'Update password'}
          </Button>
        </div>
      </div>
    </div>
  )
}
