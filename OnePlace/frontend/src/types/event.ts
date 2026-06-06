export type EventAccess = 'ALL_MEMBERS' | 'PAID_MEMBERS'

export interface EventCreator {
  id: string
  firstname: string
  lastname: string
}

export interface CommunityEvent {
  id: string
  communityId: string
  creatorId: string
  title: string
  description: string | null
  coverUrl: string | null
  location: string | null
  callRoomUrl: string | null
  startAt: string
  duration: number | null
  timezone: string
  isRecurring: boolean
  accessType: EventAccess
  emailReminder: boolean
  createdAt: string
  updatedAt: string
  creator: EventCreator
}

export interface CreateEventPayload {
  title: string
  description?: string
  coverUrl?: string
  location?: string
  startAt: string
  duration?: number
  timezone?: string
  isRecurring?: boolean
  accessType?: EventAccess
  emailReminder?: boolean
}
