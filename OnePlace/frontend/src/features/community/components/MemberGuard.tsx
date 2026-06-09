import { Navigate, Outlet, useParams } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { communityApi } from '@/api/community'
import { getMockMembership } from '@/mocks/communities.mock'

export function MemberGuard() {
  const { id } = useParams<{ id: string }>()
  const isMock = id?.startsWith('mock-')

  const { data, isLoading } = useQuery({
    queryKey: ['membership', id],
    queryFn: () => communityApi.getMyMembership(id!),
    enabled: !!id && !isMock,
  })

  if (isMock) {
    const membership = getMockMembership(id ?? '')
    if (!membership || membership.status !== 'ACTIVE') {
      return <Navigate to={`/communities/${id}/about`} replace />
    }
    return <Outlet />
  }

  if (isLoading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="h-6 w-6 animate-spin rounded-full border-4 border-border border-t-primary" />
      </div>
    )
  }

  const membership = data?.data?.membership
  if (!membership || membership.status !== 'ACTIVE') {
    return <Navigate to={`/communities/${id}/about`} replace />
  }

  return <Outlet />
}
