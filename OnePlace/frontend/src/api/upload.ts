import { api } from '@/api/client'
import type { ApiResponse } from '@/types/auth'

export type UploadFolder = 'avatars' | 'courses' | 'lessons' | 'attachments' | 'posts' | 'communities'

interface PresignResponse {
  uploadUrl: string
  fileUrl: string
  maxSize: number
  expiresIn: number
}

export const uploadApi = {
  presign: (data: { filename: string; contentType: string; folder: UploadFolder }) =>
    api
      .post<ApiResponse<PresignResponse>>('/upload/presign', data)
      .then((r) => r.data),
}

export async function uploadFile(
  file: File,
  folder: UploadFolder,
  onProgress?: (percent: number) => void,
): Promise<string> {
  const res = await uploadApi.presign({ filename: file.name, contentType: file.type, folder })
  const { uploadUrl, fileUrl, maxSize } = res.data!

  if (file.size > maxSize) {
    throw new Error(`File is too large. Maximum size is ${Math.round(maxSize / 1024 / 1024)} MB.`)
  }

  await new Promise<void>((resolve, reject) => {
    const xhr = new XMLHttpRequest()
    xhr.open('PUT', uploadUrl)
    xhr.setRequestHeader('Content-Type', file.type)

    if (onProgress) {
      xhr.upload.addEventListener('progress', (e) => {
        if (e.lengthComputable) onProgress(Math.round((e.loaded / e.total) * 100))
      })
    }

    xhr.addEventListener('load', () => {
      if (xhr.status >= 200 && xhr.status < 300) resolve()
      else reject(new Error('Upload to storage failed. Please try again.'))
    })
    xhr.addEventListener('error', () => reject(new Error('Upload to storage failed. Please try again.')))
    xhr.addEventListener('abort', () => reject(new Error('Upload cancelled.')))

    xhr.send(file)
  })

  return fileUrl
}
