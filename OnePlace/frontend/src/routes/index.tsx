import { createBrowserRouter, Navigate } from 'react-router-dom'
import { useAuthStore } from '@/store/auth.store'
import { AuthGuard } from '@/components/shared/AuthGuard'
import { SignIn } from '@/features/auth/pages/SignIn'
import { SignUp } from '@/features/auth/pages/SignUp'
import { VerifyEmail } from '@/features/auth/pages/VerifyEmail'
import { ForgotPassword } from '@/features/auth/pages/ForgotPassword'
import { ResetPassword } from '@/features/auth/pages/ResetPassword'
import { Discover } from '@/features/community/pages/Discover'
import { CreateCommunity } from '@/features/community/pages/CreateCommunity'
import { CommunityLayout } from '@/features/community/components/CommunityLayout'
import { MemberGuard } from '@/features/community/components/MemberGuard'
import { SettingsLayout } from '@/features/community/components/SettingsLayout'
import { Feed } from '@/features/community/pages/Feed'
import { PostDetail } from '@/features/community/pages/PostDetail'
import { Classroom } from '@/features/community/pages/Classroom'
import { CoursePage } from '@/features/community/pages/CoursePage'
import { Members } from '@/features/community/pages/Members'
import { CommunityAboutTab } from '@/features/community/pages/CommunityAboutTab'
import { SettingsGeneral } from '@/features/community/pages/SettingsGeneral'
import { SettingsPricing } from '@/features/community/pages/SettingsPricing'
import { SettingsMembers } from '@/features/community/pages/SettingsMembers'
import { SettingsKnowledge } from '@/features/community/pages/SettingsKnowledge'
import { CourseBuilder } from '@/features/community/pages/CourseBuilder'
import { CourseEditor } from '@/features/community/pages/CourseEditor'
import { SubscriptionPage } from '@/features/community/pages/SubscriptionPage'
import { AnalyticsPage } from '@/features/community/pages/AnalyticsPage'
import { CalendarPage } from '@/features/community/pages/CalendarPage'
import { LeaderboardPage } from '@/features/community/pages/LeaderboardPage'
import { AdminLayout } from '@/features/admin/components/AdminLayout'
import { AdminUsersPage } from '@/features/admin/pages/AdminUsersPage'
import { AdminCommunitiesPage } from '@/features/admin/pages/AdminCommunitiesPage'
import { AdminAnalyticsPage } from '@/features/admin/pages/AdminAnalyticsPage'
import { ProfileLayout } from '@/features/profile/components/ProfileLayout'
import { ProfilePage } from '@/features/profile/pages/ProfilePage'
import { MyCommunitiesPage } from '@/features/profile/pages/MyCommunitiesPage'

function RootRedirect() {
  const { user } = useAuthStore()
  const lastId = localStorage.getItem('lastCommunityId')
  if (!user) return <Navigate to="/communities" replace />
  return <Navigate to={lastId ? `/communities/${lastId}/community` : '/communities'} replace />
}

export const router = createBrowserRouter([
  // ── Public auth ────────────────────────────────────────────────────────────
  { path: '/sign-in', element: <SignIn /> },
  { path: '/sign-up', element: <SignUp /> },
  { path: '/verify-email', element: <VerifyEmail /> },
  { path: '/forgot-password', element: <ForgotPassword /> },
  { path: '/reset-password', element: <ResetPassword /> },

  // ── Public ─────────────────────────────────────────────────────────────────
  { path: '/', element: <RootRedirect /> },
  { path: '/communities', element: <Discover /> },

  // Community shell — publicly browsable; join requires auth
  {
    path: '/communities/:id',
    element: <CommunityLayout />,
    children: [
      { index: true, element: <Navigate to="community" replace /> },
      { path: 'about', element: <CommunityAboutTab /> },
      {
        element: <MemberGuard />,
        children: [
          { path: 'community', element: <Feed /> },
          { path: 'community/posts/:postId', element: <PostDetail /> },
          { path: 'classroom', element: <Classroom /> },
          { path: 'calendar', element: <CalendarPage /> },
          { path: 'leaderboards', element: <LeaderboardPage /> },
          { path: 'classroom/manage', element: <CourseBuilder /> },
          { path: 'classroom/manage/:courseId', element: <CourseEditor /> },
          { path: 'classroom/:courseId', element: <CoursePage /> },
          { path: 'classroom/:courseId/sections/:sectionId/lessons/:lessonId', element: <CoursePage /> },
          { path: 'members', element: <Members /> },
          { path: 'subscription', element: <SubscriptionPage /> },
          { path: 'analytics', element: <AnalyticsPage /> },
        ],
      },
    ],
  },

  // ── Protected ──────────────────────────────────────────────────────────────
  {
    element: <AuthGuard />,
    children: [
      { path: '/communities/new', element: <CreateCommunity /> },

      // Admin panel
      {
        path: '/admin',
        element: <AdminLayout />,
        children: [
          { index: true, element: <Navigate to="users" replace /> },
          { path: 'users', element: <AdminUsersPage /> },
          { path: 'communities', element: <AdminCommunitiesPage /> },
          { path: 'analytics', element: <AdminAnalyticsPage /> },
        ],
      },

      // Profile
      {
        path: '/profile',
        element: <ProfileLayout />,
        children: [
          { index: true, element: <ProfilePage /> },
          { path: 'communities', element: <MyCommunitiesPage /> },
        ],
      },

      // Community settings
      {
        path: '/communities/:id/settings',
        element: <SettingsLayout />,
        children: [
          { index: true, element: <Navigate to="general" replace /> },
          { path: 'general', element: <SettingsGeneral /> },
          { path: 'pricing', element: <SettingsPricing /> },
          { path: 'members', element: <SettingsMembers /> },
          { path: 'knowledge', element: <SettingsKnowledge /> },
        ],
      },
    ],
  },
])
