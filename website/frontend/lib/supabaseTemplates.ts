import { supabase } from "./supabase"
import type { Category, FieldType } from "./templates"

export interface DbTemplateField {
  id: string
  name: string
  type: FieldType
  unit: string | null
  options: string[] | null
  position: number
}

export interface DbTemplateAuthor {
  id: string
  full_name: string
  username: string
  avatarColor: string
  avatar_url: string | null
}

export interface DbTemplate {
  id: string
  slug: string
  template_name: string
  category: Category
  tags: string
  tagline: string | null
  description: string | null
  downloads: number
  likes: number
  version: number
  featured: boolean
  created_at: string
  user_id: string
  fields: DbTemplateField[]
  author: DbTemplateAuthor | null
}

export interface DbProfile {
  id: string
  full_name: string
  username: string
  bio: string | null
  avatar_url: string | null
}

// Deterministic avatar color per user, pulled from the same chart palette
// used elsewhere in the UI, since users_profiles has no color column.
const AVATAR_COLORS = [
  "var(--chart-1)",
  "var(--chart-2)",
  "var(--chart-3)",
  "var(--chart-4)",
  "var(--chart-5)",
  "var(--chart-7)",
  "var(--chart-8)",
]

export function colorForUsername(username: string) {
  let hash = 0
  for (let i = 0; i < username.length; i++) {
    hash = (hash << 5) - hash + username.charCodeAt(i)
    hash |= 0
  }
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length]
}

export function splitTags(tags: string): string[] {
  return tags
    .split(",")
    .map((t) => t.trim())
    .filter(Boolean)
}

type RawTemplateRow = Omit<DbTemplate, "fields" | "author"> & {
  template_fields: DbTemplateField[]
}

async function attachAuthors(rows: RawTemplateRow[]): Promise<DbTemplate[]> {
  if (rows.length === 0) return []

  const userIds = [...new Set(rows.map((r) => r.user_id))]

  const { data: profiles, error } = await supabase
    .from("users_profiles")
    .select("id, full_name, username, avatar_url")
    .in("id", userIds)

  if (error) throw error

  const profileMap = new Map(
    (profiles ?? []).map((p) => [
      p.id,
      {
        id: p.id,
        full_name: p.full_name,
        username: p.username,
        avatarColor: colorForUsername(p.username),
        avatar_url: p.avatar_url ?? null,
      },
    ]),
  )

  return rows.map((row) => ({
    ...row,
    fields: (row.template_fields ?? []).sort((a, b) => a.position - b.position),
    author: profileMap.get(row.user_id) ?? null,
  }))
}

export async function fetchFeaturedTemplates(limit = 8): Promise<DbTemplate[]> {
  const { data, error } = await supabase
    .from("templates")
    .select("*, template_fields(*)")
    .eq("featured", true)
    .order("created_at", { ascending: false })
    .limit(limit)

  if (error) throw error
  return attachAuthors(data as unknown as RawTemplateRow[])
}

export async function fetchTrendingTemplates(limit = 8): Promise<DbTemplate[]> {
  const { data, error } = await supabase
    .from("templates")
    .select("*, template_fields(*)")
    .order("downloads", { ascending: false })
    .limit(limit)

  if (error) throw error
  return attachAuthors(data as unknown as RawTemplateRow[])
}

export async function fetchAllTemplates(limit = 200): Promise<DbTemplate[]> {
  const { data, error } = await supabase
    .from("templates")
    .select("*, template_fields(*)")
    .order("created_at", { ascending: false })
    .limit(limit)

  if (error) throw error
  return attachAuthors(data as unknown as RawTemplateRow[])
}

export async function fetchTemplateBySlug(slug: string): Promise<DbTemplate | null> {
  const { data, error } = await supabase
    .from("templates")
    .select("*, template_fields(*)")
    .eq("slug", slug)
    .maybeSingle()

  if (error) throw error
  if (!data) return null

  const [withAuthor] = await attachAuthors([data as unknown as RawTemplateRow])
  return withAuthor
}

export async function fetchTemplatesByUser(userId: string): Promise<DbTemplate[]> {
  const { data, error } = await supabase
    .from("templates")
    .select("*, template_fields(*)")
    .eq("user_id", userId)
    .order("created_at", { ascending: false })

  if (error) throw error
  return attachAuthors(data as unknown as RawTemplateRow[])
}

async function fetchTemplatesByIds(templateIds: string[]): Promise<DbTemplate[]> {
  if (templateIds.length === 0) return []

  const { data, error } = await supabase
    .from("templates")
    .select("*, template_fields(*)")
    .in("id", templateIds)

  if (error) throw error
  return attachAuthors(data as unknown as RawTemplateRow[])
}

export async function fetchLikedTemplates(userId: string): Promise<DbTemplate[]> {
  const { data, error } = await supabase
    .from("template_likes")
    .select("template_id")
    .eq("user_id", userId)

  if (error) throw error

  const templateIds = (data ?? []).map((row) => row.template_id)
  return fetchTemplatesByIds(templateIds)
}

export async function fetchDownloadedTemplates(userId: string): Promise<DbTemplate[]> {
  const { data, error } = await supabase
    .from("template_downloads")
    .select("template_id")
    .eq("user_id", userId)

  if (error) throw error

  const templateIds = (data ?? []).map((row) => row.template_id)
  return fetchTemplatesByIds(templateIds)
}

export interface TemplateJson {
  schema_version: 1
  app: "Digital Lifelines"
  type: "template"
  timelines: {
    name: string
    fields: { name: string; type: "text" | "number" }[]
    entries: never[]
  }[]
}

function appFieldType(type: FieldType): "text" | "number" {
  return type === "integer" || type === "double" ? "number" : "text"
}

export function buildTemplateJson(template: DbTemplate): TemplateJson {
  return {
    schema_version: 1,
    app: "Digital Lifelines",
    type: "template",
    timelines: [
      {
        name: template.template_name,
        fields: template.fields.map((field) => ({
          name: field.name,
          type: appFieldType(field.type),
        })),
        entries: [],
      },
    ],
  }
}

export async function isTemplateLiked(userId: string, templateId: string): Promise<boolean> {
  const { data, error } = await supabase
    .from("template_likes")
    .select("id")
    .eq("user_id", userId)
    .eq("template_id", templateId)
    .maybeSingle()

  if (error) throw error
  return Boolean(data)
}

export async function likeTemplate(userId: string, templateId: string): Promise<void> {
  const { error: insertError } = await supabase
    .from("template_likes")
    .insert({ user_id: userId, template_id: templateId })

  if (insertError) throw insertError

  const { error: rpcError } = await supabase.rpc("increment_template_likes", {
    p_template_id: templateId,
    p_delta: 1,
  })

  if (rpcError) throw rpcError
}

export async function unlikeTemplate(userId: string, templateId: string): Promise<void> {
  const { error: deleteError } = await supabase
    .from("template_likes")
    .delete()
    .eq("user_id", userId)
    .eq("template_id", templateId)

  if (deleteError) throw deleteError

  const { error: rpcError } = await supabase.rpc("increment_template_likes", {
    p_template_id: templateId,
    p_delta: -1,
  })

  if (rpcError) throw rpcError
}

// Records a download for this user (once) and bumps the counter.
// Returns false if the user already downloaded this template before,
// so the counter is never double-counted.
export async function recordDownload(userId: string, templateId: string): Promise<boolean> {
  const { data: existing, error: checkError } = await supabase
    .from("template_downloads")
    .select("id")
    .eq("user_id", userId)
    .eq("template_id", templateId)
    .maybeSingle()

  if (checkError) throw checkError
  if (existing) return false

  const { error: insertError } = await supabase
    .from("template_downloads")
    .insert({ user_id: userId, template_id: templateId })

  if (insertError) throw insertError

  const { error: rpcError } = await supabase.rpc("increment_template_downloads", {
    p_template_id: templateId,
  })

  if (rpcError) throw rpcError

  return true
}

export async function fetchProfile(userId: string): Promise<DbProfile | null> {
  const { data, error } = await supabase
    .from("users_profiles")
    .select("id, full_name, username, bio, avatar_url")
    .eq("id", userId)
    .maybeSingle()

  if (error) throw error
  return data
}

export async function updateProfile(
  userId: string,
  updates: { full_name?: string; bio?: string | null },
): Promise<void> {
  const { error } = await supabase.from("users_profiles").update(updates).eq("id", userId)
  if (error) throw error
}

// Uploads to a path scoped by the user's own id (required by the storage
// RLS policy), overwriting any previous avatar, then returns the new
// public URL. Does not touch users_profiles — call updateProfile after
// to save the returned URL.
export async function uploadAvatar(userId: string, file: File): Promise<string> {
  const ext = file.name.split(".").pop() || "jpg"
  const path = `${userId}/avatar.${ext}`

  const { error: uploadError } = await supabase.storage
    .from("avatars")
    .upload(path, file, { upsert: true, cacheControl: "3600" })

  if (uploadError) throw uploadError

  const { data } = supabase.storage.from("avatars").getPublicUrl(path)
  // cache-bust so the new image shows immediately instead of the
  // browser reusing a previously cached image at the same URL
  return `${data.publicUrl}?t=${Date.now()}`
}