interface OnePlaceLogoProps {
  className?: string
}

export function OnePlaceLogo({ className }: OnePlaceLogoProps) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="currentColor"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
    >
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M12 2C7.582 2 4 5.582 4 10c0 5.5 8 14 8 14s8-8.5 8-14c0-4.418-3.582-8-8-8zm0 5.5a2.5 2.5 0 100 5 2.5 2.5 0 000-5z"
      />
    </svg>
  )
}
