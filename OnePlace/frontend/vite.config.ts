import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
    conditions: ['development', 'browser', 'module', 'jsnext:main', 'jsnext'],
  },
  optimizeDeps: {
    include: [
      '@vidstack/react',
      '@vidstack/react/player/layouts/default',
    ],
  },
})
