import axios from 'axios'

const API_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:5000/api/v1'

export const api = axios.create({
  baseURL: API_URL,
  withCredentials: true,
})

api.interceptors.response.use(
  (res) => res,
  (error) => {
    const message = error.response?.data?.message ?? error.message
    return Promise.reject(new Error(message))
  },
)
