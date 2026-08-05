"use client"

import { useEffect, useMemo, useState } from "react"
import { Plus, Trash2, Check, Loader2, ArrowLeft } from "lucide-react"
import { Button } from "../Components/buttons"
import { Input } from "../Components/input"
import { Textarea } from "../Components/textarea"
import { Label } from "../Components/label"
import { CATEGORIES, type Category, type FieldType } from "../../lib/templates"
import { supabase } from "../../lib/supabase"
import { fetchTemplateBySlug, type DbTemplate } from "../../lib/supabaseTemplates"
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

interface DraftField {
  key: string // stable key for React, independent of dbId
  dbId: string | null // null = new field not yet saved
  name: string
  type: FieldType
  unit: string
}

export default function EditTemplatePage() {
  const path = typeof window !== "undefined" ? window.location.pathname : ""
  const slug = useMemo(() => {
    const parts = path.split("/").filter(Boolean)
    // expects /template/:slug/edit
    const editIndex = parts.indexOf("edit")
    return editIndex > 0 ? parts[editIndex - 1] : ""
  }, [path])

  const [template, setTemplate] = useState<DbTemplate | null | undefined>(undefined)
  const [currentUserId, setCurrentUserId] = useState<string | null | undefined>(undefined)
  const [loadError, setLoadError] = useState<string | null>(null)

  const [name, setName] = useState("")
  const [category, setCategory] = useState<Category>(CATEGORIES[0].name)
  const [tagline, setTagline] = useState("")
  const [description, setDescription] = useState("")
  const [tags, setTags] = useState("")
  const [fields, setFields] = useState<DraftField[]>([])

  const [isSaving, setIsSaving] = useState(false)
  const [saveError, setSaveError] = useState<string | null>(null)
  const [saved, setSaved] = useState(false)

  useEffect(() => {
    let cancelled = false

    async function load() {
      const {
        data: { user },
      } = await supabase.auth.getUser()
      if (!cancelled) setCurrentUserId(user?.id ?? null)

      try {
        const found = await fetchTemplateBySlug(slug)
        if (cancelled) return
        setTemplate(found)

        if (found) {
          setName(found.template_name)
          setCategory(found.category)
          setTagline(found.tagline ?? "")
          setDescription(found.description ?? "")
          setTags(found.tags)
          setFields(
            found.fields.map((f) => ({
              key: f.id,
              dbId: f.id,
              name: f.name,
              type: f.type,
              unit: f.unit ?? "",
            })),
          )
        }
      } catch (err) {
        if (!cancelled) setLoadError(err instanceof Error ? err.message : "Failed to load template.")
      }
    }

    if (slug) load()
    return () => {
      cancelled = true
    }
  }, [slug])

  function addField() {
    setFields((prev) => [
      ...prev,
      { key: `new-${Date.now()}`, dbId: null, name: "", type: "text", unit: "" },
    ])
  }
  function updateField(key: string, patch: Partial<DraftField>) {
    setFields((prev) => prev.map((f) => (f.key === key ? { ...f, ...patch } : f)))
  }
  function removeField(key: string) {
    setFields((prev) => prev.filter((f) => f.key !== key))
  }

  const namedFields = fields.filter((f) => f.name.trim())

  async function handleSave(e: React.FormEvent) {
    e.preventDefault()
    if (!template) return
    setSaveError(null)

    if (namedFields.length === 0) {
      setSaveError("Add at least one named field before saving.")
      return
    }

    setIsSaving(true)

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
        setSaveError(describeFlaggedFields(moderation))
        setIsSaving(false)
        return
      }

      // 1. Update the template row itself. Slug is intentionally left
      // unchanged so existing links/bookmarks to this template keep working.
      const { error: templateError } = await supabase
        .from("templates")
        .update({
          template_name: name,
          category,
          tags,
          tagline: tagline || null,
          description: description || null,
        })
        .eq("id", template.id)

      if (templateError) {
        setSaveError(templateError.message)
        setIsSaving(false)
        return
      }

      // 2. Diff fields against what was originally loaded, rather than
      // wiping and reinserting — that would silently lose `options` data
      // on select fields, since this form has no UI to re-enter them.
      const originalIds = new Set(template.fields.map((f) => f.id))
      const keptIds = new Set(namedFields.filter((f) => f.dbId).map((f) => f.dbId as string))
      const deletedIds = [...originalIds].filter((id) => !keptIds.has(id))

      if (deletedIds.length > 0) {
        const { error: deleteError } = await supabase
          .from("template_fields")
          .delete()
          .in("id", deletedIds)
        if (deleteError) {
          setSaveError(deleteError.message)
          setIsSaving(false)
          return
        }
      }

      // Update existing fields
      const existing = namedFields.filter((f) => f.dbId)
      for (let i = 0; i < existing.length; i++) {
        const f = existing[i]
        const { error: updateError } = await supabase
          .from("template_fields")
          .update({ name: f.name, type: f.type, unit: f.unit || null, position: i })
          .eq("id", f.dbId as string)
        if (updateError) {
          setSaveError(updateError.message)
          setIsSaving(false)
          return
        }
      }

      // Insert new fields
      const newOnes = namedFields.filter((f) => !f.dbId)
      if (newOnes.length > 0) {
        const { error: insertError } = await supabase.from("template_fields").insert(
          newOnes.map((f, i) => ({
            template_id: template.id,
            name: f.name,
            type: f.type,
            unit: f.unit || null,
            options: null,
            position: existing.length + i,
          })),
        )
        if (insertError) {
          setSaveError(insertError.message)
          setIsSaving(false)
          return
        }
      }

      setSaved(true)
      setTimeout(() => {
        window.location.href = `/template/${template.slug}`
      }, 800)
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : "Something went wrong.")
      setIsSaving(false)
    }
  }

  if (template === undefined || currentUserId === undefined) {
    return (
      <div className="mx-auto flex max-w-7xl items-center justify-center gap-2 px-4 py-24 text-muted-foreground sm:px-6 lg:px-8">
        <Loader2 className="h-4 w-4 animate-spin" />
        Loading...
      </div>
    )
  }

  if (!template || loadError) {
    return (
      <div className="mx-auto max-w-xl px-4 py-24 text-center">
        <h1 className="font-serif text-2xl font-semibold">Template not found</h1>
        <p className="mt-2 text-sm text-muted-foreground">{loadError}</p>
      </div>
    )
  }

  if (currentUserId !== template.user_id) {
    return (
      <div className="mx-auto max-w-xl px-4 py-24 text-center">
        <h1 className="font-serif text-2xl font-semibold">Not authorized</h1>
        <p className="mt-2 text-sm text-muted-foreground">
          You can only edit templates you created.
        </p>
        <Button asChild className="mt-6">
          <a href={`/template/${template.slug}`}>Back to template</a>
        </Button>
      </div>
    )
  }

  return (
    <div className="mx-auto max-w-3xl px-4 py-10 sm:px-6 lg:px-8">
      <a
        href={`/template/${template.slug}`}
        className="inline-flex items-center gap-2 text-sm font-medium text-muted-foreground transition-colors hover:text-foreground"
      >
        <ArrowLeft className="h-4 w-4" />
        Back to template
      </a>

      <h1 className="mt-4 font-serif text-4xl font-bold tracking-tight">Edit template</h1>
      <p className="mt-2 text-pretty text-muted-foreground">
        Update the details below. The template's URL won't change.
      </p>

      <form onSubmit={handleSave} className="mt-8 flex flex-col gap-8">
        <div className="rounded-2xl border border-border bg-card p-6">
          <h2 className="text-lg font-semibold">Template details</h2>
          <div className="mt-5 grid gap-5 sm:grid-cols-2">
            <div className="sm:col-span-2">
              <Label htmlFor="name">Template name</Label>
              <Input
                id="name"
                value={name}
                onChange={(e) => setName(e.target.value)}
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
                className="mt-1.5"
              />
            </div>
            <div className="sm:col-span-2">
              <Label htmlFor="tagline">Tagline</Label>
              <Input
                id="tagline"
                value={tagline}
                onChange={(e) => setTagline(e.target.value)}
                className="mt-1.5"
              />
            </div>
            <div className="sm:col-span-2">
              <Label htmlFor="description">Description</Label>
              <Textarea
                id="description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="mt-1.5 min-h-24"
              />
            </div>
          </div>
        </div>

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
                key={field.key}
                className="flex flex-col gap-2 rounded-xl border border-border bg-background p-3 sm:flex-row sm:items-center"
              >
                <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-md bg-secondary text-xs font-semibold text-muted-foreground">
                  {i + 1}
                </span>
                <Input
                  value={field.name}
                  onChange={(e) => updateField(field.key, { name: e.target.value })}
                  placeholder="Field name"
                  className="flex-1"
                />
                <select
                  value={field.type}
                  onChange={(e) => updateField(field.key, { type: e.target.value as FieldType })}
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
                  onChange={(e) => updateField(field.key, { unit: e.target.value })}
                  placeholder="Unit"
                  className="w-full sm:w-24"
                />
                <button
                  type="button"
                  onClick={() => removeField(field.key)}
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

        {saveError && (
          <div className="rounded-xl border border-destructive/30 bg-destructive/10 p-4 text-sm text-destructive">
            {saveError}
          </div>
        )}

        <div className="flex gap-3">
          <Button type="submit" size="lg" disabled={isSaving}>
            {isSaving ? (
              <>
                <Loader2 className="h-4 w-4 animate-spin" />
                Saving...
              </>
            ) : saved ? (
              <>
                <Check className="h-4 w-4" />
                Saved!
              </>
            ) : (
              <>
                <Check className="h-4 w-4" />
                Save changes
              </>
            )}
          </Button>
          <Button type="button" size="lg" variant="outline" asChild disabled={isSaving}>
            <a href={`/template/${template.slug}`}>Cancel</a>
          </Button>
        </div>
      </form>
    </div>
  )
}