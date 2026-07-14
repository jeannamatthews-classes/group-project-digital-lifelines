"use client"

import { useEffect, useMemo, useState } from "react"
import { Search, SlidersHorizontal, X, Check, Loader2 } from "lucide-react"
import { Button } from "../Components/buttons"
import { Input } from "../Components/input"
import { TemplateCard } from "../Components/templateCard"
import { DynamicIcon } from "../Components/icons"
import { CATEGORIES, type Category } from "../../lib/templates"
import { fetchAllTemplates, splitTags, type DbTemplate } from "../../lib/supabaseTemplates"
import { cn } from "../../lib/utils"

type SortKey = "popular" | "likes" | "recent" | "az"

const SORT_OPTIONS: { key: SortKey; label: string }[] = [
  { key: "popular", label: "Most downloaded" },
  { key: "likes", label: "Most liked" },
  { key: "recent", label: "Recently updated" },
  { key: "az", label: "A to Z" },
]

export default function ExplorePage() {
  const [templates, setTemplates] = useState<DbTemplate[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const [query, setQuery] = useState("")
  const [activeCategories, setActiveCategories] = useState<Category[]>([])
  const [activeTags, setActiveTags] = useState<string[]>([])
  const [sort, setSort] = useState<SortKey>("popular")
  const [mobileFiltersOpen, setMobileFiltersOpen] = useState(false)

  useEffect(() => {
    let cancelled = false

    async function load() {
      setLoading(true)
      setError(null)
      try {
        const data = await fetchAllTemplates()
        if (!cancelled) setTemplates(data)
      } catch (err) {
        if (!cancelled) setError(err instanceof Error ? err.message : "Failed to load templates.")
      } finally {
        if (!cancelled) setLoading(false)
      }
    }

    load()

    function handlePageShow(e: PageTransitionEvent) {
      if (e.persisted) load()
    }
    window.addEventListener("pageshow", handlePageShow)

    return () => {
      cancelled = true
      window.removeEventListener("pageshow", handlePageShow)
    }
  }, [])

  const allTags = useMemo(
    () => Array.from(new Set(templates.flatMap((t) => splitTags(t.tags)))).sort(),
    [templates],
  )

  function toggleCategory(cat: Category) {
    setActiveCategories((prev) =>
      prev.includes(cat) ? prev.filter((c) => c !== cat) : [...prev, cat],
    )
  }
  function toggleTag(tag: string) {
    setActiveTags((prev) => (prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag]))
  }
  function clearAll() {
    setActiveCategories([])
    setActiveTags([])
    setQuery("")
  }

  const filtered = useMemo(() => {
    let result = templates.filter((t) => {
      const tagList = splitTags(t.tags)
      const q = query.toLowerCase()
      const matchesQuery =
        !query ||
        t.template_name.toLowerCase().includes(q) ||
        (t.description ?? "").toLowerCase().includes(q) ||
        tagList.some((tag) => tag.toLowerCase().includes(q))
      const matchesCategory =
        activeCategories.length === 0 || activeCategories.includes(t.category)
      const matchesTags =
        activeTags.length === 0 || activeTags.every((tag) => tagList.includes(tag))
      return matchesQuery && matchesCategory && matchesTags
    })

    result = [...result].sort((a, b) => {
      switch (sort) {
        case "popular":
          return (b.downloads ?? 0) - (a.downloads ?? 0)
        case "likes":
          return (b.likes ?? 0) - (a.likes ?? 0)
        case "recent":
          return b.created_at.localeCompare(a.created_at)
        case "az":
          return a.template_name.localeCompare(b.template_name)
      }
    })
    return result
  }, [templates, query, activeCategories, activeTags, sort])

  const hasFilters = activeCategories.length > 0 || activeTags.length > 0 || query.length > 0

  const FilterPanel = (
    <div className="flex flex-col gap-8">
      <div>
        <h3 className="text-sm font-semibold">Categories</h3>
        <div className="mt-3 flex flex-col gap-1">
          {CATEGORIES.map((cat) => {
            const active = activeCategories.includes(cat.name)
            return (
              <button
                key={cat.name}
                onClick={() => toggleCategory(cat.name)}
                className={cn(
                  "flex items-center gap-3 rounded-lg px-2.5 py-2 text-left text-sm transition-colors",
                  active ? "bg-secondary font-medium" : "text-muted-foreground hover:bg-secondary/60",
                )}
              >
                <span
                  className="flex h-7 w-7 items-center justify-center rounded-md"
                  style={{ backgroundColor: cat.mutedColor, color: cat.color }}
                >
                  <DynamicIcon name={cat.icon} className="h-4 w-4" />
                </span>
                <span className="flex-1">{cat.name}</span>
                {active && <Check className="h-4 w-4 text-primary" />}
              </button>
            )
          })}
        </div>
      </div>

      <div>
        <h3 className="text-sm font-semibold">Tags</h3>
        <div className="mt-3 flex flex-wrap gap-2">
          {allTags.map((tag) => {
            const active = activeTags.includes(tag)
            return (
              <button
                key={tag}
                onClick={() => toggleTag(tag)}
                className={cn(
                  "rounded-full border px-3 py-1 text-xs font-medium transition-colors",
                  active
                    ? "border-primary bg-primary text-primary-foreground"
                    : "border-border text-muted-foreground hover:border-primary/40 hover:text-foreground",
                )}
              >
                {tag}
              </button>
            )
          })}
        </div>
      </div>
    </div>
  )

  return (
    <div className="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
      <div className="max-w-2xl">
        <h1 className="font-serif text-4xl font-bold tracking-tight">Explore Timeline templates</h1>
        <p className="mt-2 text-pretty text-muted-foreground">
          Browse {templates.length} community-made timeline templates. Filter by category, tags, or
          search for exactly what you want to track.
        </p>
      </div>

      {/* Search + sort bar */}
      <div className="mt-8 flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search templates, tags, or keywords..."
            className="pl-9"
          />
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            className="lg:hidden"
            onClick={() => setMobileFiltersOpen((v) => !v)}
          >
            <SlidersHorizontal className="h-4 w-4" />
            Filters
          </Button>
          <select
            value={sort}
            onChange={(e) => setSort(e.target.value as SortKey)}
            className="h-9 rounded-lg border border-input bg-card px-3 text-sm font-medium outline-none focus-visible:ring-2 focus-visible:ring-ring"
            aria-label="Sort templates"
          >
            {SORT_OPTIONS.map((opt) => (
              <option key={opt.key} value={opt.key}>
                {opt.label}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="mt-8 flex gap-8">
        {/* Desktop sidebar */}
        <aside className="hidden w-60 shrink-0 lg:block">
          <div className="sticky top-24">
            <div className="flex items-center justify-between">
              <h2 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">
                Filters
              </h2>
              {hasFilters && (
                <button
                  onClick={clearAll}
                  className="text-xs font-medium text-primary hover:underline"
                >
                  Clear all
                </button>
              )}
            </div>
            <div className="mt-5">{FilterPanel}</div>
          </div>
        </aside>

        {/* Mobile filter sheet */}
        {mobileFiltersOpen && (
          <div className="fixed inset-0 z-50 lg:hidden">
            <div
              className="absolute inset-0 bg-foreground/40"
              onClick={() => setMobileFiltersOpen(false)}
            />
            <div className="absolute inset-y-0 left-0 w-80 max-w-[85%] overflow-y-auto bg-background p-6">
              <div className="flex items-center justify-between">
                <h2 className="text-lg font-semibold">Filters</h2>
                <button onClick={() => setMobileFiltersOpen(false)} aria-label="Close filters">
                  <X className="h-5 w-5" />
                </button>
              </div>
              <div className="mt-6">{FilterPanel}</div>
              <div className="mt-8 flex gap-2">
                <Button variant="outline" className="flex-1" onClick={clearAll}>
                  Clear
                </Button>
                <Button className="flex-1" onClick={() => setMobileFiltersOpen(false)}>
                  Show {filtered.length}
                </Button>
              </div>
            </div>
          </div>
        )}

        {/* Results */}
        <div className="min-w-0 flex-1">
          {error && (
            <div className="mb-5 rounded-xl border border-destructive/30 bg-destructive/10 p-4 text-sm text-destructive">
              Couldn't load templates: {error}
            </div>
          )}

          {loading ? (
            <div className="flex items-center justify-center gap-2 py-20 text-muted-foreground">
              <Loader2 className="h-4 w-4 animate-spin" />
              Loading templates...
            </div>
          ) : (
            <>
              <div className="mb-5 flex items-center justify-between">
                <p className="text-sm text-muted-foreground">
                  <span className="font-medium text-foreground">{filtered.length}</span> templates
                </p>
                {hasFilters && (
                  <div className="flex flex-wrap items-center gap-2">
                    {activeCategories.map((c) => (
                      <span
                        key={c}
                        className="inline-flex items-center gap-1 rounded-full bg-secondary px-2.5 py-1 text-xs"
                      >
                        {c}
                        <button onClick={() => toggleCategory(c)} aria-label={`Remove ${c}`}>
                          <X className="h-3 w-3" />
                        </button>
                      </span>
                    ))}
                    {activeTags.map((t) => (
                      <span
                        key={t}
                        className="inline-flex items-center gap-1 rounded-full bg-secondary px-2.5 py-1 text-xs"
                      >
                        {t}
                        <button onClick={() => toggleTag(t)} aria-label={`Remove ${t}`}>
                          <X className="h-3 w-3" />
                        </button>
                      </span>
                    ))}
                  </div>
                )}
              </div>

              {filtered.length > 0 ? (
                <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
                  {filtered.map((template) => (
                    <TemplateCard key={template.id} template={template} />
                  ))}
                </div>
              ) : (
                <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-border py-20 text-center">
                  <Search className="h-10 w-10 text-muted-foreground/50" />
                  <h3 className="mt-4 text-lg font-semibold">No templates found</h3>
                  <p className="mt-1 max-w-sm text-sm text-muted-foreground">
                    Try adjusting your search or clearing some filters to see more results.
                  </p>
                  <Button variant="outline" className="mt-5" onClick={clearAll}>
                    Clear filters
                  </Button>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  )
}