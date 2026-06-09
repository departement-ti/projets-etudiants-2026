import { toast } from 'sonner'

export function xpToast(points: number) {
  toast(`+${points} XP`, {
    icon: '⚡',
    description: 'Added to your leaderboard score',
    duration: 3000,
  })
}
