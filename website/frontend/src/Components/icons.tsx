import {
  Activity,
  Baby,
  BookOpen,
  Clapperboard,
  Coffee,
  Dumbbell,
  HeartPulse,
  Palette,
  Plane,
  Smile,
  Sprout,
  UtensilsCrossed,
  Wallet,
  Layers,
  type LucideIcon,
} from "lucide-react"

const ICONS: Record<string, LucideIcon> = {
  Activity,
  Baby,
  BookOpen,
  Clapperboard,
  Coffee,
  Dumbbell,
  HeartPulse,
  Palette,
  Plane,
  Smile,
  Sprout,
  UtensilsCrossed,
  Wallet,
  Layers,
}

export function DynamicIcon({
  name,
  className,
}: {
  name: string
  className?: string
}) {
  const Icon = ICONS[name] ?? Layers
  return <Icon className={className} aria-hidden="true" />
}
