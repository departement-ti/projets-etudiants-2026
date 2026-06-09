import { api } from './client'
import type { ApiResponse } from '@/types/auth'

export type KnowledgeDoc = {
  id: string
  name: string
  createdAt: string
  embedding: number[]
}

export const knowledgeApi = {
  list: (communityId: string) =>
    api
      .get<ApiResponse<{ docs: KnowledgeDoc[] }>>(`/communities/${communityId}/knowledge`)
      .then((r) => r.data),

  create: (communityId: string, body: { name: string; content: string }) =>
    api
      .post<ApiResponse<{ doc: KnowledgeDoc }>>(`/communities/${communityId}/knowledge`, body)
      .then((r) => r.data),

  delete: (communityId: string, docId: string) =>
    api
      .delete<ApiResponse<void>>(`/communities/${communityId}/knowledge/${docId}`)
      .then((r) => r.data),
}
