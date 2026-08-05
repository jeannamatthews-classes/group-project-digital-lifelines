"use client"

import { useRef, useState } from "react"
import {
  UploadCloud,
  FileJson,
  Plus,
  Trash2,
  Check,
  ArrowRight,
  Info,
  CheckCircle2,
  Loader2,
} from "lucide-react"
import { Button } from "../Components/buttons"
import { Input } from "../Components/input"
import { Textarea } from "../Components/textarea"
import { Label } from "../Components/label"
import { CATEGORIES, type Category, type FieldType } from "../../lib/templates"
import { cn } from "../../lib/utils"
import { supabase } from "../../lib/supabase"
import { moderateFields, describeFlaggedFields } from "../../lib/moderation"

const FIELD_TYPES: { value: FieldType; label: string }[] = [
  { value: "text", label: "Text" },
  { value: "integer", label: "Whole number" },
  { value: "double", label: "Decimal" },
  { value: "boolean", label: "Yes / No" },
  { value: "date", label: "Date" },
  { value: "select", label: "Choice" },
  { value: "photo", label: "Photo" },
]

const TEMPLATE_VERSION = 1.0

function slugify(name: string): string {
  return name
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "")
    || "template"
}

function randomSlugSuffix(): string {
  return Math.random().toString(36).slice(2, 6)
}

interface DraftField {
  id: string
  name: string
  type: FieldType
  unit: string
}

export default function UploadPage() {
  const [name, setName] = useState("")
  const [category, setCategory] = useState<Category>(CATEGORIES[0].name)
  const [tagline, setTagline] = useState("")
  const [description, setDescription] = useState("")
  const [tags, setTags] = useState("")
  const [fields, setFields] = useState<DraftField[]>([
    { id: "f1", name: "", type: "text", unit: "" },
  ])
  const [dragOver, setDragOver] = useState(false)
  const [fileName, setFileName] = useState<string | null>(null)
  const [submitted, setSubmitted] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [submitError, setSubmitError] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  function addField() {
    setFields((prev) => [
      ...prev,
      { id: `f${Date.now()}`, name: "", type: "text", unit: "" },
    ])
  }
  function updateField(id: string, patch: Partial<DraftField>) {
    setFields((prev) => prev.map((f) => (f.id === id ? { ...f, ...patch } : f)))
  }
  function removeField(id: string) {
    setFields((prev) => prev.filter((f) => f.id !== id))
  }

  function handleFile(file: File | undefined) {
    if (!file) return
    setFileName(file.name)
    file.text().then((text) => {
      try {
        const parsed = JSON.parse(text)
        if (parsed.name) setName(parsed.name)
        if (parsed.category) setCategory(parsed.category)
        if (Array.isArray(parsed.tags)) setTags(parsed.tags.join(", "))
        if (Array.isArray(parsed.fields)) {
          setFields(
            parsed.fields.map((f: { name?: string; type?: FieldType; unit?: string }, i: number) => ({
              id: `imp${i}`,
              name: f.name ?? "",
              type: (f.type as FieldType) ?? "text",
              unit: f.unit ?? "",
            })),
          )
        }
      } catch {
        // ignore invalid JSON
      }
    })
  }

  const tagList = tags
    .split(",")
    .map((t) => t.trim())
    .filter(Boolean)

  const namedFields = fields.filter((f) => f.name.trim())

  const previewJson = JSON.stringify(
    {
      name: name || "Untitled Timeline",
      version: TEMPLATE_VERSION,
      category,
      tags: tagList,
      fields: namedFields.map((f) => ({
        name: f.name,
        type: f.type,
        ...(f.unit ? { unit: f.unit } : {}),
      })),
    },
    null,
    2,
  )

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setSubmitError(null)

    if (namedFields.length === 0) {
      setSubmitError("Add at least one named field before submitting.")
      return
    }

    setIsSubmitting(true)

    try {
      // Server-side moderation gate — checked before anything is written.
      const fieldsToCheck: Record<string, string> = {
        "Template name": name,
        Tagline: tagline,
        Description: description,
        Tags: tags,
      }
      namedFields.forEach((f, i) => {
        fieldsToCheck[`Field ${i + 1} name`] = f.name
      })

      const moderation = await moderateFields(fieldsToCheck)
      if (moderation.flagged) {
        setSubmitError(describeFlaggedFields(moderation))
        setIsSubmitting(false)
        return
      }

      const {
        data: { user },
      } = await supabase.auth.getUser()

      if (!user) {
        setSubmitError("You need to be logged in to submit a template.")
        setIsSubmitting(false)
        return
      }

      // 1. Insert the template row, get back its generated id.
      // Slugs must be unique — if the base slug is taken, retry once
      // with a short random suffix appended.
      const baseSlug = slugify(name)
      let template: { id: string } | null = null
      let templateError: { message: string; code?: string } | null = null

      for (const candidateSlug of [baseSlug, `${baseSlug}-${randomSlugSuffix()}`]) {
        const { data, error } = await supabase
          .from("templates")
          .insert({
            slug: candidateSlug,
            template_name: name,
            category,
            tags: tagList.join(", "),
            tagline: tagline || null,
            description: description || null,
            version: TEMPLATE_VERSION,
          })
          .select()
          .single()

        if (!error) {
          template = data
          templateError = null
          break
        }

        // 23505 = unique_violation — try the fallback slug, otherwise bail
        if (error.code !== "23505") {
          templateError = error
          break
        }
        templateError = error
      }

      if (!template) {
        setSubmitError(templateError?.message ?? "Failed to create template.")
        setIsSubmitting(false)
        return
      }

      // 2. Insert the fields, linked to the new template
      const fieldRows = namedFields.map((f, i) => ({
        template_id: template.id,
        name: f.name,
        type: f.type,
        unit: f.unit || null,
        position: i,
      }))

      const { error: fieldsError } = await supabase
        .from("template_fields")
        .insert(fieldRows)

      if (fieldsError) {
        setSubmitError(fieldsError.message)
        setIsSubmitting(false)
        return
      }

      setSubmitted(true)
    } catch (err) {
      setSubmitError(err instanceof Error ? err.message : "Something went wrong.")
    } finally {
      setIsSubmitting(false)
    }
  }

  if (submitted) {
    return (
      <div className="mx-auto flex max-w-xl flex-col items-center px-4 py-24 text-center">
        <div className="flex h-16 w-16 items-center justify-center rounded-full bg-accent/15">
          <CheckCircle2 className="h-8 w-8 text-accent" />
        </div>
        <h1 className="mt-6 font-serif text-3xl font-bold">Template submitted!</h1>
        <p className="mt-3 text-pretty text-muted-foreground">
          Thanks for contributing to the community. Your template &ldquo;{name || "Untitled"}&rdquo;
          is now under quick review and will appear in the gallery shortly.
        </p>
        <div className="mt-8 flex gap-3">
          <Button asChild>
            <a href="/explore">Browse templates</a>
          </Button>
          <Button asChild variant="outline">
            <a href="/dashboard">Go to dashboard</a>
          </Button>
        </div>
      </div>
    )
  }

  return (
    <div className="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
      <div className="max-w-2xl">
        <h1 className="font-serif text-4xl font-bold tracking-tight">Share a template</h1>
        <p className="mt-2 text-pretty text-muted-foreground">
          Upload an existing timeline JSON or build one from scratch. Share the way you track your
          life with the community.
        </p>
      </div>

      <form onSubmit={handleSubmit} className="mt-10 grid gap-10 lg:grid-cols-3">
        {/* Form */}
        <div className="flex flex-col gap-8 lg:col-span-2">
          {/* Dropzone */}
          <div
            onDragOver={(e) => {
              e.preventDefault()
              setDragOver(true)
            }}
            onDragLeave={() => setDragOver(false)}
            onDrop={(e) => {
              e.preventDefault()
              setDragOver(false)
              handleFile(e.dataTransfer.files?.[0])
            }}
            className={cn(
              "flex flex-col items-center justify-center rounded-2xl border-2 border-dashed px-6 py-12 text-center transition-colors",
              dragOver ? "border-primary bg-primary/5" : "border-border bg-card",
            )}
          >
            <input
              ref={fileInputRef}
              type="file"
              accept="application/json,.json"
              className="hidden"
              onChange={(e) => handleFile(e.target.files?.[0])}
            />
            {fileName ? (
              <>
                <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-accent/15">
                  <FileJson className="h-6 w-6 text-accent" />
                </div>
                <p className="mt-3 font-medium">{fileName}</p>
                <p className="mt-1 text-sm text-muted-foreground">
                  Parsed and pre-filled below. Review before submitting.
                </p>
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  className="mt-4"
                  onClick={() => fileInputRef.current?.click()}
                >
                  Choose a different file
                </Button>
              </>
            ) : (
              <>
                <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary/10">
                  <UploadCloud className="h-6 w-6 text-primary" />
                </div>
                <p className="mt-3 font-medium">Drag &amp; drop your JSON file here</p>
                <p className="mt-1 text-sm text-muted-foreground">
                  or fill out the form below to build one from scratch
                </p>
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  className="mt-4"
                  onClick={() => fileInputRef.current?.click()}
                >
                  Browse files
                </Button>
              </>
            )}
          </div>

          {/* Details */}
          <div className="rounded-2xl border border-border bg-card p-6">
            <h2 className="text-lg font-semibold">Template details</h2>
            <div className="mt-5 grid gap-5 sm:grid-cols-2">
              <div className="sm:col-span-2">
                <Label htmlFor="name">Template name</Label>
                <Input
                  id="name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g. Morning Run Tracker"
                  className="mt-1.5"
                  required
                />
              </div>
              <div>
                <Label htmlFor="category">Category</Label>
                <select
                  id="category"
                  value={category}
                  onChange={(e) => setCategory(e.target.value as Category)}
                  className="mt-1.5 h-9 w-full rounded-lg border border-input bg-background px-3 text-sm outline-none focus-visible:ring-2 focus-visible:ring-ring"
                >
                  {CATEGORIES.map((c) => (
                    <option key={c.name} value={c.name}>
                      {c.name}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <Label htmlFor="tags">Tags (comma separated)</Label>
                <Input
                  id="tags"
                  value={tags}
                  onChange={(e) => setTags(e.target.value)}
                  placeholder="running, fitness, daily"
                  className="mt-1.5"
                />
              </div>
              <div className="sm:col-span-2">
                <Label htmlFor="tagline">Tagline</Label>
                <Input
                  id="tagline"
                  value={tagline}
                  onChange={(e) => setTagline(e.target.value)}
                  placeholder="A short, catchy one-liner"
                  className="mt-1.5"
                />
              </div>
              <div className="sm:col-span-2">
                <Label htmlFor="description">Description</Label>
                <Textarea
                  id="description"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Describe what this template tracks and who it's for..."
                  className="mt-1.5 min-h-24"
                />
              </div>
            </div>
          </div>

          {/* Fields builder */}
          <div className="rounded-2xl border border-border bg-card p-6">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-lg font-semibold">Fields</h2>
                <p className="text-sm text-muted-foreground">
                  Define the data points users will record.
                </p>
              </div>
              <Button type="button" variant="outline" size="sm" onClick={addField}>
                <Plus className="h-4 w-4" />
                Add field
              </Button>
            </div>

            <div className="mt-5 flex flex-col gap-3">
              {fields.map((field, i) => (
                <div
                  key={field.id}
                  className="flex flex-col gap-2 rounded-xl border border-border bg-background p-3 sm:flex-row sm:items-center"
                >
                  <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-md bg-secondary text-xs font-semibold text-muted-foreground">
                    {i + 1}
                  </span>
                  <Input
                    value={field.name}
                    onChange={(e) => updateField(field.id, { name: e.target.value })}
                    placeholder="Field name"
                    className="flex-1"
                  />
                  <select
                    value={field.type}
                    onChange={(e) => updateField(field.id, { type: e.target.value as FieldType })}
                    className="h-9 rounded-lg border border-input bg-background px-3 text-sm outline-none focus-visible:ring-2 focus-visible:ring-ring"
                  >
                    {FIELD_TYPES.map((t) => (
                      <option key={t.value} value={t.value}>
                        {t.label}
                      </option>
                    ))}
                  </select>
                  <Input
                    value={field.unit}
                    onChange={(e) => updateField(field.id, { unit: e.target.value })}
                    placeholder="Unit"
                    className="w-full sm:w-24"
                  />
                  <button
                    type="button"
                    onClick={() => removeField(field.id)}
                    className="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:bg-destructive/10 hover:text-destructive"
                    aria-label="Remove field"
                    disabled={fields.length === 1}
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              ))}
            </div>
          </div>

          {submitError && (
            <div className="rounded-xl border border-destructive/30 bg-destructive/10 p-4 text-sm text-destructive">
              {submitError}
            </div>
          )}

          <div className="flex items-center justify-between rounded-xl border border-border bg-secondary/40 p-4">
            <div className="flex items-start gap-3">
              <Info className="mt-0.5 h-4 w-4 shrink-0 text-muted-foreground" />
              <p className="text-xs leading-relaxed text-muted-foreground">
                By submitting, you agree your template will be shared publicly under the community
                license. All copy here is a prototype.
              </p>
            </div>
          </div>

          <div className="flex gap-3">
            <Button type="submit" size="lg" disabled={isSubmitting}>
              {isSubmitting ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Submitting...
                </>
              ) : (
                <>
                  <Check className="h-4 w-4" />
                  Submit template
                </>
              )}
            </Button>
            <Button type="button" size="lg" variant="outline" asChild disabled={isSubmitting}>
              <a href="/explore">Cancel</a>
            </Button>
          </div>
        </div>

        {/* Live preview */}
        <div className="lg:col-span-1">
          <div className="sticky top-24 flex flex-col gap-5">
            <div>
              <h3 className="flex items-center gap-2 text-sm font-semibold text-muted-foreground">
                <ArrowRight className="h-4 w-4" /> Live preview
              </h3>
            </div>

            {/* Card preview */}
            <div className="overflow-hidden rounded-2xl border border-border bg-card">
              <div className="flex h-24 items-center justify-center bg-primary/10">
                <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-primary">
                  <FileJson className="h-7 w-7 text-primary-foreground" />
                </div>
              </div>
              <div className="p-4">
                <span className="inline-block rounded-full bg-primary/10 px-2.5 py-0.5 text-xs font-medium text-primary">
                  {category}
                </span>
                <h4 className="mt-2 font-semibold">{name || "Untitled Timeline"}</h4>
                <p className="mt-0.5 line-clamp-2 text-sm text-muted-foreground">
                  {tagline || "Your tagline will appear here"}
                </p>
                <div className="mt-3 flex flex-wrap gap-1.5">
                  {tagList.slice(0, 4).map((tag) => (
                    <span
                      key={tag}
                      className="rounded-full bg-secondary px-2 py-0.5 text-xs text-muted-foreground"
                    >
                      {tag}
                    </span>
                  ))}
                </div>
                <p className="mt-3 text-xs text-muted-foreground">
                  {namedFields.length} fields defined
                </p>
              </div>
            </div>

            {/* JSON preview */}
            <div className="overflow-hidden rounded-xl border border-border bg-[#1a1d2e]">
              <div className="border-b border-white/10 px-4 py-2.5">
                <span className="font-mono text-xs text-white/50">preview.json</span>
              </div>
              <pre className="max-h-72 overflow-auto p-4 font-mono text-xs leading-relaxed text-[#c8d3f5]">
                <code>{previewJson}</code>
              </pre>
            </div>
          </div>
        </div>
      </form>
    </div>
  )
}