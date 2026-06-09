import type { Config } from 'tailwindcss'
import { fontFamily } from 'tailwindcss/defaultTheme'

export default {
  darkMode: ['class'],
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        background: '#0F0D1A',
        foreground: '#F9FAFB',
        border: '#2A2440',
        input: '#2A2440',
        ring: '#6C3BFF',
        primary: {
          DEFAULT: '#6C3BFF',
          foreground: '#FFFFFF',
        },
        accent: {
          DEFAULT: '#F59E0B',
          foreground: '#0F0D1A',
        },
        muted: {
          DEFAULT: '#1E1A2E',
          foreground: '#9CA3AF',
        },
        card: {
          DEFAULT: '#1E1A2E',
          foreground: '#F9FAFB',
        },
        destructive: {
          DEFAULT: '#EF4444',
          foreground: '#FFFFFF',
        },
        popover: {
          DEFAULT: '#1E1A2E',
          foreground: '#F9FAFB',
        },
        secondary: {
          DEFAULT: '#2A2440',
          foreground: '#F9FAFB',
        },
      },
      borderRadius: {
        lg: '0.5rem',
        md: 'calc(0.5rem - 2px)',
        sm: 'calc(0.5rem - 4px)',
      },
      fontFamily: {
        sans: ['Inter', ...fontFamily.sans],
      },
    },
  },
  plugins: [],
} satisfies Config
