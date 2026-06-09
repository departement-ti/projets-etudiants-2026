export type NotificationType =
  | 'NEW_COMMENT'
  | 'NEW_POST'
  | 'MEMBER_JOINED'
  | 'SUBSCRIPTION_EXPIRING'
  | 'SUBSCRIPTION_EXPIRED'

export interface Notification {
  id: string
  userId: string
  type: NotificationType
  title: string
  body: string | null
  link: string | null
  isRead: boolean
  createdAt: string
}
