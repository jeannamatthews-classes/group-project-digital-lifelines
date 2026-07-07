"use client"

import { useMemo } from "react"
import {
  ArrowLeft,
  Download,
  Heart,
  Layers,
  Calendar,
  Tag,
  CheckCircle2,
} from "lucide-react"
import { DynamicIcon } from "../Components/icons"
import { TemplateCard } from "../Components/template-card"
import { TemplateActions, JsonPreview } from "../Components/actions"
import { getTemplate, TEMPLATES } from "../../lib/templates"

const FIELD_TYPE_LABEL: Record<string, string> = {
  text: "Text",
  integer: "Whole number",
  double: "Decimal",
  boolean: "Yes / No",
  date: "Date",
  select: "Choice",
  photo: "Photo",
}

export default function TemplatePage() {
  const path = typeof window !== "undefined" ? window.location.pathname : ""
  const templateId = useMemo(() => path.split("/").filter(Boolean).pop() ?? "", [path])
  const template = getTemplate(templateId)

  if (!template) {
    return (
      <div className="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
        <a
          href="/explore"
          className="inline-flex items-center gap-2 text-sm font-medium text-muted-foreground transition-colors hover:text-foreground"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to explore
        </a>
        <div className="mt-10 rounded-2xl border border-dashed border-border bg-card p-10 text-center">
          <h1 className="font-serif text-2xl font-semibold">Template not found</h1>
          <p className="mt-2 text-sm text-muted-foreground">
            The requested template is unavailable right now.
          </p>
        </div>
      </div>
    )
  }

  const related = TEMPLATES.filter(
    (t) => t.category === template.category && t.id !== template.id,
  ).slice(0, 4)

  function formatCount(n: number) {
    if (n >= 1000) return (n / 1000).toFixed(1).replace(/\.0$/, "") + "k"
    return String(n)
  }

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
      <a
        href="/explore"
        className="inline-flex items-center gap-2 text-sm font-medium text-muted-foreground transition-colors hover:text-foreground"
      >
        <ArrowLeft className="h-4 w-4" />
        Back to explore
      </a>

      <div className="mt-6 grid gap-10 lg:grid-cols-3">
        {/* Main */}
        <div className="lg:col-span-2">
          {/* Header banner */}
          <div
            className="flex items-center gap-5 rounded-2xl border border-border p-6"
            style={{ backgroundColor: `color-mix(in oklch, ${template.color} 12%, var(--card))` }}
          >
            <div
              className="flex h-20 w-20 shrink-0 items-center justify-center rounded-2xl shadow-sm"
              style={{ backgroundColor: template.color }}
            >
              <DynamicIcon name={template.icon} className="h-10 w-10 text-white" />
            </div>
            <div className="min-w-0">
              <span
                className="inline-block rounded-full px-2.5 py-0.5 text-xs font-medium"
                style={{
                  backgroundColor: `color-mix(in oklch, ${template.color} 20%, transparent)`,
                  color: template.color,
                }}
              >
                {template.category}
              </span>
              <h1 className="mt-2 text-balance font-serif text-3xl font-bold tracking-tight sm:text-4xl">
                {template.name}
              </h1>
              <p className="mt-1 text-pretty text-muted-foreground">{template.tagline}</p>
            </div>
          </div>

          {/* About */}
          <div className="mt-8">
            <h2 className="text-lg font-semibold">About this template</h2>
            <p className="mt-3 text-pretty leading-relaxed text-muted-foreground">
              {template.description}
            </p>
            <div className="mt-4 flex flex-wrap gap-2">
              {template.tags.map((tag) => (
                <a
                  key={tag}
                  href="/explore"
                  className="inline-flex items-center gap-1 rounded-full border border-border px-3 py-1 text-xs font-medium text-muted-foreground transition-colors hover:border-primary/40 hover:text-foreground"
                >
                  <Tag className="h-3 w-3" />
                  {tag}
                </a>
              ))}
            </div>
          </div>

          {/* Fields */}
          <div className="mt-10">
            <div className="flex items-center gap-2">
              <Layers className="h-5 w-5 text-muted-foreground" />
              <h2 className="text-lg font-semibold">
                Fields <span className="text-muted-foreground">({template.fields.length})</span>
              </h2>
            </div>
            <p className="mt-1 text-sm text-muted-foreground">
              These are the data points you&apos;ll record each time you add an entry.
            </p>
            <div className="mt-4 overflow-hidden rounded-xl border border-border">
              {template.fields.map((field, i) => (
                <div
                  key={field.name}
                  className={`flex items-center justify-between gap-4 px-4 py-3.5 ${
                    i % 2 === 0 ? "bg-card" : "bg-secondary/40"
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <CheckCircle2 className="h-4 w-4 shrink-0 text-accent" />
                    <span className="font-medium">{field.name}</span>
                    {field.unit && (
                      <span className="rounded bg-secondary px-1.5 py-0.5 font-mono text-xs text-muted-foreground">
                        {field.unit}
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-2 text-right">
                    {field.options && (
                      <span className="hidden text-xs text-muted-foreground sm:inline">
                        {field.options.length} options
                      </span>
                    )}
                    <span className="rounded-md bg-primary/10 px-2 py-1 text-xs font-medium text-primary">
                      {FIELD_TYPE_LABEL[field.type]}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* JSON preview */}
          <div className="mt-10">
            <h2 className="text-lg font-semibold">JSON preview</h2>
            <p className="mt-1 text-sm text-muted-foreground">
              The exact file you&apos;ll download and import into Digital Lifelines.
            </p>
            <div className="mt-4">
              <JsonPreview template={template} />
            </div>
          </div>
        </div>

        {/* Sidebar */}
        <div className="lg:col-span-1">
          <div className="sticky top-24 flex flex-col gap-6">
            <div className="rounded-2xl border border-border bg-card p-6">
              <TemplateActions template={template} />

              <dl className="mt-6 grid grid-cols-2 gap-4 border-t border-border pt-6">
                <div>
                  <dt className="flex items-center gap-1.5 text-xs text-muted-foreground">
                    <Download className="h-3.5 w-3.5" /> Downloads
                  </dt>
                  <dd className="mt-1 text-xl font-semibold">{formatCount(template.downloads)}</dd>
                </div>
                <div>
                  <dt className="flex items-center gap-1.5 text-xs text-muted-foreground">
                    <Heart className="h-3.5 w-3.5" /> Likes
                  </dt>
                  <dd className="mt-1 text-xl font-semibold">{formatCount(template.likes)}</dd>
                </div>
                <div>
                  <dt className="flex items-center gap-1.5 text-xs text-muted-foreground">
                    <Layers className="h-3.5 w-3.5" /> Fields
                  </dt>
                  <dd className="mt-1 text-xl font-semibold">{template.fields.length}</dd>
                </div>
                <div>
                  <dt className="flex items-center gap-1.5 text-xs text-muted-foreground">
                    <Calendar className="h-3.5 w-3.5" /> Version
                  </dt>
                  <dd className="mt-1 text-xl font-semibold">{template.version}</dd>
                </div>
              </dl>
            </div>

            {/* Author */}
            <div className="rounded-2xl border border-border bg-card p-6">
              <h3 className="text-sm font-semibold text-muted-foreground">Created by</h3>
              <div className="mt-4 flex items-center gap-3">
                <span
                  className="flex h-12 w-12 items-center justify-center rounded-full text-lg font-semibold text-white"
                  style={{ backgroundColor: template.author.avatarColor }}
                >
                  {template.author.name.charAt(0)}
                </span>
                <div>
                  <p className="font-medium">{template.author.name}</p>
                  <p className="text-sm text-muted-foreground">@{template.author.handle}</p>
                </div>
              </div>
              <p className="mt-4 text-xs text-muted-foreground">
                Last updated{" "}
                {new Date(template.updatedAt).toLocaleDateString("en-US", {
                  month: "long",
                  day: "numeric",
                  year: "numeric",
                })}
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Related */}
      {related.length > 0 && (
        <div className="mt-16 border-t border-border pt-12">
          <h2 className="text-xl font-semibold tracking-tight">
            More in {template.category}
          </h2>
          <div className="mt-6 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
            {related.map((t) => (
              <TemplateCard key={t.id} template={t} />
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
