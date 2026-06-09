export type PostType = 'TEXT' | 'IMAGE' | 'VIDEO'

export interface PostAuthor {
  id: string
  firstname: string
  lastname: string
}

export interface Post {
  id: string
  communityId: string
  authorId: string
  title: string
  content: string
  type: PostType
  category: string | null
  isPinned: boolean
  createdAt: string
  updatedAt: string
  author: PostAuthor
  _count: { comments: number; likes: number }
  likedByMe: boolean
}

export interface Comment {
  id: string
  postId: string
  authorId: string
  content: string
  createdAt: string
  updatedAt: string
  author: PostAuthor
}
