"use client"

import { useEffect, useMemo, useState } from "react"
import {
  ArrowLeft,
  Download,
  Heart,
  Layers,
  Calendar,
  Tag,
  CheckCircle2,
  Loader2,
  Trash2,
  Pencil,
} from "lucide-react"
import { Button } from "../Components/buttons"
import { DynamicIcon } from "../Components/icons"
import { TemplateCard } from "../Components/templateCard"
import { TemplateActions, JsonPreview } from "../Components/actions"
import { getCategoryMeta } from "../../lib/templates"
import { supabase } from "../../lib/supabase"
import {
  fetchTemplateBySlug,
  fetchAllTemplates,
  splitTags,
  type DbTemplate,
} from "../../lib/supabaseTemplates"

const FIELD_TYPE_LABEL: Record<string, string> = {
  text: "Text",
  integer: "Whole number",
  double: "Decimal",
  boolean: "Yes / No",
  date: "Date",
  select: "Choice",
  photo: "Photo",
}

function formatCount(n: number) {
  if (n >= 1000) return (n / 1000).toFixed(1).replace(/\.0$/, "") + "k"
  return String(n)
}

export default function TemplatePage() {
  const path = typeof window !== "undefined" ? window.location.pathname : ""
  const slug = useMemo(() => path.split("/").filter(Boolean).pop() ?? "", [path])

  const [template, setTemplate] = useState<DbTemplate | null | undefined>(undefined)
  const [related, setRelated] = useState<DbTemplate[]>([])
  const [error, setError] = useState<string | null>(null)
  const [currentUserId, setCurrentUserId] = useState<string | null>(null)
  const [deleting, setDeleting] = useState(false)

  useEffect(() => {
    supabase.auth.getUser().then(({ data: { user } }) => {
      setCurrentUserId(user?.id ?? null)
    })
  }, [])

  async function handleDelete() {
    if (!template) return
    const confirmed = window.confirm(
      `Delete "${template.template_name}"? This can't be undone.`,
    )
    if (!confirmed) return

    setDeleting(true)
    const { error: deleteError } = await supabase
      .from("templates")
      .delete()
      .eq("id", template.id)

    if (deleteError) {
      alert(deleteError.message)
      setDeleting(false)
      return
    }

    window.location.href = "/dashboard"
  }

  useEffect(() => {
    let cancelled = false

    async function load() {
      setTemplate(undefined)
      setError(null)

      try {
        const found = await fetchTemplateBySlug(slug)
        if (cancelled) return
        setTemplate(found)

        if (found) {
          const all = await fetchAllTemplates()
          if (cancelled) return
          setRelated(
            all.filter((t) => t.category === found.category && t.id !== found.id).slice(0, 4),
          )
        }
      } catch (err) {
        if (!cancelled) setError(err instanceof Error ? err.message : "Failed to load template.")
      }
    }

    if (slug) load()
    return () => {
      cancelled = true
    }
  }, [slug])

  if (template === undefined) {
    return (
      <div className="mx-auto flex max-w-7xl items-center justify-center gap-2 px-4 py-24 text-muted-foreground sm:px-6 lg:px-8">
        <Loader2 className="h-4 w-4 animate-spin" />
        Loading template...
      </div>
    )
  }

  if (!template || error) {
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
            {error ?? "The requested template is unavailable right now."}
          </p>
        </div>
      </div>
    )
  }

  const { icon, color, subtleColor, mutedColor } = getCategoryMeta(template.category)
  const tagList = splitTags(template.tags)

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
            style={{ backgroundColor: subtleColor }}
          >
            <div
              className="flex h-20 w-20 shrink-0 items-center justify-center rounded-2xl shadow-sm"
              style={{ backgroundColor: color }}
            >
              <DynamicIcon name={icon} className="h-10 w-10 text-white" />
            </div>
            <div className="min-w-0">
              <span
                className="inline-block rounded-full px-2.5 py-0.5 text-xs font-medium"
                style={{
                  backgroundColor: mutedColor,
                  color: color,
                }}
              >
                {template.category}
              </span>
              <h1 className="mt-2 text-balance font-serif text-3xl font-bold tracking-tight sm:text-4xl">
                {template.template_name}
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
              {tagList.map((tag) => (
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
                  key={field.id}
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
              <TemplateActions
                template={template}
                onCountsChange={(counts) =>
                  setTemplate((prev) => (prev ? { ...prev, ...counts } : prev))
                }
              />

              <dl className="mt-6 grid grid-cols-2 gap-4 border-t border-border pt-6">
                <div>
                  <dt className="flex items-center gap-1.5 text-xs text-muted-foreground">
                    <Download className="h-3.5 w-3.5" /> Downloads
                  </dt>
                  <dd className="mt-1 text-xl font-semibold">{formatCount(template.downloads ?? 0)}</dd>
                </div>
                <div>
                  <dt className="flex items-center gap-1.5 text-xs text-muted-foreground">
                    <Heart className="h-3.5 w-3.5" /> Likes
                  </dt>
                  <dd className="mt-1 text-xl font-semibold">{formatCount(template.likes ?? 0)}</dd>
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
                {template.author?.avatar_url ? (
                  <img
                    src={template.author.avatar_url}
                    alt={template.author.full_name}
                    className="h-12 w-12 rounded-full object-cover"
                  />
                ) : (
                  <span
                    className="flex h-12 w-12 items-center justify-center rounded-full text-lg font-semibold text-white"
                    style={{ backgroundColor: template.author?.avatarColor ?? "var(--chart-1)" }}
                  >
                    {(template.author?.full_name ?? "?").charAt(0)}
                  </span>
                )}
                <div>
                  <p className="font-medium">{template.author?.full_name ?? "Unknown"}</p>
                  <p className="text-sm text-muted-foreground">@{template.author?.username ?? "unknown"}</p>
                </div>
              </div>
              <p className="mt-4 text-xs text-muted-foreground">
                Created{" "}
                {new Date(template.created_at).toLocaleDateString("en-US", {
                  month: "long",
                  day: "numeric",
                  year: "numeric",
                })}
              </p>
            </div>

            {/* Owner controls */}
            {currentUserId === template.user_id && (
              <div className="rounded-2xl border border-destructive/30 bg-card p-6">
                <h3 className="text-sm font-semibold text-muted-foreground">Manage template</h3>
                <p className="mt-1 text-xs text-muted-foreground">
                  Update the details or remove this template permanently.
                </p>
                <div className="mt-4 flex flex-col gap-2">
                  <Button variant="outline" className="w-full" asChild>
                    <a href={`/template/${template.slug}/edit`}>
                      <Pencil className="h-4 w-4" />
                      Edit template
                    </a>
                  </Button>
                  <Button
                    variant="outline"
                    className="w-full border-destructive/40 text-destructive hover:bg-destructive/10"
                    onClick={handleDelete}
                    disabled={deleting}
                  >
                    {deleting ? <Loader2 className="h-4 w-4 animate-spin" /> : <Trash2 className="h-4 w-4" />}
                    {deleting ? "Deleting..." : "Delete template"}
                  </Button>
                </div>
              </div>
            )}
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