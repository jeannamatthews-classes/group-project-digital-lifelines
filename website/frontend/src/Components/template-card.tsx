import { Download, Heart, Layers } from "lucide-react"
import { DynamicIcon } from "./icons"
import type { TeamTemplate } from "../../lib/templates"

function formatCount(n: number) {
  if (n >= 1000) return (n / 1000).toFixed(1).replace(/\.0$/, "") + "k"
  return String(n)
}

export function TemplateCard({ template }: { template: TeamTemplate }) {
  return (
    <a
      href={`/template/${template.id}`}
      className="group flex flex-col overflow-hidden rounded-2xl border border-border bg-card transition-all hover:border-primary/40 hover:shadow-lg hover:shadow-primary/5"
    >
      <div
        className="relative flex h-32 items-center justify-center overflow-hidden"
        style={{ backgroundColor: `color-mix(in oklch, ${template.color} 14%, var(--card))` }}
      >
        <div
          className="flex h-16 w-16 items-center justify-center rounded-2xl shadow-sm transition-transform group-hover:scale-110"
          style={{ backgroundColor: template.color }}
        >
          <DynamicIcon name={template.icon} className="h-8 w-8 text-white" />
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
              backgroundColor: `color-mix(in oklch, ${template.color} 16%, transparent)`,
              color: template.color,
            }}
          >
            {template.category}
          </span>
        </div>
        <h3 className="mt-3 font-semibold leading-tight">{template.name}</h3>
        <p className="mt-1 line-clamp-2 flex-1 text-sm leading-relaxed text-muted-foreground">
          {template.tagline}
        </p>

        <div className="mt-4 flex items-center justify-between border-t border-border pt-4">
          <div className="flex items-center gap-2">
            <span
              className="flex h-6 w-6 items-center justify-center rounded-full text-[10px] font-semibold text-white"
              style={{ backgroundColor: template.author.avatarColor }}
            >
              {template.author.name.charAt(0)}
            </span>
            <span className="text-xs text-muted-foreground">@{template.author.handle}</span>
          </div>
          <div className="flex items-center gap-3 text-xs text-muted-foreground">
            <span className="inline-flex items-center gap-1">
              <Download className="h-3.5 w-3.5" />
              {formatCount(template.downloads)}
            </span>
            <span className="inline-flex items-center gap-1">
              <Heart className="h-3.5 w-3.5" />
              {formatCount(template.likes)}
            </span>
          </div>
        </div>
      </div>
    </a>
  )
}
