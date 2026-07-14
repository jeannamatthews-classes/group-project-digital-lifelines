import { Download, Heart, Layers } from "lucide-react"
import { DynamicIcon } from "./icons"
import { getCategoryMeta } from "../../lib/templates"
import type { DbTemplate } from "../../lib/supabaseTemplates"

function formatCount(n: number) {
  if (n >= 1000) return (n / 1000).toFixed(1).replace(/\.0$/, "") + "k"
  return String(n)
}

export function TemplateCard({ template }: { template: DbTemplate }) {
  const { icon, color, subtleColor, mutedColor } = getCategoryMeta(template.category)
  const authorName = template.author?.full_name ?? "Unknown"
  const authorHandle = template.author?.username ?? "unknown"
  const authorColor = template.author?.avatarColor ?? "var(--chart-1)"
  const authorAvatarUrl = template.author?.avatar_url ?? null

  return (
    <a
      href={`/template/${template.slug}`}
      className="group flex flex-col overflow-hidden rounded-2xl border border-border bg-card transition-all hover:border-primary/40 hover:shadow-lg hover:shadow-primary/5"
    >
      <div
        className="relative flex h-32 items-center justify-center overflow-hidden"
        style={{ backgroundColor: subtleColor }}
      >
        <div
          className="flex h-16 w-16 items-center justify-center rounded-2xl shadow-sm transition-transform group-hover:scale-110"
          style={{ backgroundColor: color }}
        >
          <DynamicIcon name={icon} className="h-8 w-8 text-white" />
        </div>
        <span className="absolute right-3 top-3 inline-flex items-center gap-1 rounded-full bg-card/80 px-2.5 py-1 text-xs font-medium text-muted-foreground backdrop-blur">
          <Layers className="h-3 w-3" />
          {template.fields.length} fields
        </span>
      </div>

      <div className="flex flex-1 flex-col p-5">
        <div className="flex items-center gap-2">
          <span
            className="inline-block rounded-full px-2.5 py-0.5 text-xs font-medium"
            style={{
              backgroundColor: mutedColor,
              color: color,
            }}
          >
            {template.category}
          </span>
        </div>
        <h3 className="mt-3 font-semibold leading-tight">{template.template_name}</h3>
        <p className="mt-1 line-clamp-2 flex-1 text-sm leading-relaxed text-muted-foreground">
          {template.tagline}
        </p>

        <div className="mt-4 flex items-center justify-between border-t border-border pt-4">
          <div className="flex items-center gap-2">
            {authorAvatarUrl ? (
              <img
                src={authorAvatarUrl}
                alt={authorName}
                className="h-6 w-6 rounded-full object-cover"
              />
            ) : (
              <span
                className="flex h-6 w-6 items-center justify-center rounded-full text-[10px] font-semibold text-white"
                style={{ backgroundColor: authorColor }}
              >
                {authorName.charAt(0)}
              </span>
            )}
            <span className="text-xs text-muted-foreground">@{authorHandle}</span>
          </div>
          <div className="flex items-center gap-3 text-xs text-muted-foreground">
            <span className="inline-flex items-center gap-1">
              <Download className="h-3.5 w-3.5" />
              {formatCount(template.downloads ?? 0)}
            </span>
            <span className="inline-flex items-center gap-1">
              <Heart className="h-3.5 w-3.5" />
              {formatCount(template.likes ?? 0)}
            </span>
          </div>
        </div>
      </div>
    </a>
  )
}