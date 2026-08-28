"use client"

import { useEffect, useRef, useState } from "react"
import { Upload, Download, Heart, Settings, Pencil, TrendingUp, Loader2, LogOut } from "lucide-react"
import { Button } from "../Components/buttons"
import { TemplateCard } from "../Components/templateCard"
import { supabase } from "../../lib/supabase"
import {
  fetchTemplatesByUser,
  fetchDownloadedTemplates,
  fetchLikedTemplates,
  fetchProfile,
  colorForUsername,
  type DbTemplate,
  type DbProfile,
} from "../../lib/supabaseTemplates"
import { cn } from "../../lib/utils"

type Tab = "my uploads" | "my downloads" | "my likes"

const TABS: { key: Tab; label: string; icon: typeof Upload }[] = [
  { key: "my uploads", label: "My Uploads", icon: Upload },
  { key: "my downloads", label: "My Downloads", icon: Download },
  { key: "my likes", label: "My Likes", icon: Heart },
]

const emptyCopy: Record<Tab, { title: string; body: string }> = {
  "my uploads": {
    title: "No uploads yet",
    body: "Share your first timeline template with the community.",
  },
  "my downloads": {
    title: "Nothing downloaded yet",
    body: "Browse the gallery and download a template to get started.",
  },
  "my likes": {
    title: "No liked templates",
    body: "Tap the heart on any template to save it here.",
  },
}

export default function DashboardPage() {
  const [tab, setTab] = useState<Tab>("my uploads")
  const [profile, setProfile] = useState<DbProfile | null>(null)
  const [joinedAt, setJoinedAt] = useState<string | null>(null)
  const [uploads, setUploads] = useState<DbTemplate[]>([])
  const [downloaded, setDownloaded] = useState<DbTemplate[]>([])
  const [liked, setLiked] = useState<DbTemplate[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [notLoggedIn, setNotLoggedIn] = useState(false)
  const [settingsOpen, setSettingsOpen] = useState(false)
  const [loggingOut, setLoggingOut] = useState(false)
  const settingsRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!settingsOpen) return

    function handleClickOutside(e: MouseEvent) {
      if (settingsRef.current && !settingsRef.current.contains(e.target as Node)) {
        setSettingsOpen(false)
      }
    }

    document.addEventListener("mousedown", handleClickOutside)
    return () => document.removeEventListener("mousedown", handleClickOutside)
  }, [settingsOpen])

  async function handleLogout() {
    setLoggingOut(true)
    const { error: signOutError } = await supabase.auth.signOut()
    if (signOutError) {
      alert(signOutError.message)
      setLoggingOut(false)
      return
    }
    window.location.href = "/auth"
  }

  useEffect(() => {
    let cancelled = false

    async function load() {
      setLoading(true)
      setError(null)

      const {
        data: { user },
      } = await supabase.auth.getUser()

      if (!user) {
        if (!cancelled) {
          setNotLoggedIn(true)
          setLoading(false)
        }
        return
      }

      try {
        const [profileData, uploadsData, downloadedData, likedData] = await Promise.all([
          fetchProfile(user.id),
          fetchTemplatesByUser(user.id),
          fetchDownloadedTemplates(user.id),
          fetchLikedTemplates(user.id),
        ])

        if (!cancelled) {
          setProfile(profileData)
          setJoinedAt(user.created_at)
          setUploads(uploadsData)
          setDownloaded(downloadedData)
          setLiked(likedData)
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "Failed to load your dashboard.")
        }
      } finally {
        if (!cancelled) setLoading(false)
      }
    }

    load()
    return () => {
      cancelled = true
    }
  }, [])

  if (loading) {
    return (
      <div className="mx-auto flex max-w-7xl items-center justify-center gap-2 px-4 py-24 text-muted-foreground sm:px-6 lg:px-8">
        <Loader2 className="h-4 w-4 animate-spin" />
        Loading your dashboard...
      </div>
    )
  }

  if (notLoggedIn) {
    return (
      <div className="mx-auto flex max-w-xl flex-col items-center px-4 py-24 text-center">
        <h1 className="font-serif text-3xl font-bold">You're not logged in</h1>
        <p className="mt-3 text-pretty text-muted-foreground">
          Log in to see your uploads, downloads, and liked templates.
        </p>
        <Button asChild className="mt-6">
          <a href="/auth">Log in</a>
        </Button>
      </div>
    )
  }

  if (error || !profile) {
    return (
      <div className="mx-auto max-w-xl px-4 py-24 text-center">
        <p className="text-sm text-destructive">{error ?? "Profile not found."}</p>
      </div>
    )
  }

  const totalDownloads = uploads.reduce((sum, t) => sum + (t.downloads ?? 0), 0)
  const totalLikes = uploads.reduce((sum, t) => sum + (t.likes ?? 0), 0)
  const avatarColor = colorForUsername(profile.username)

  const current = tab === "my uploads" ? uploads : tab === "my downloads" ? downloaded : liked

  return (
    <div className="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
      {/* Profile header */}
      <div className="flex flex-col gap-6 rounded-2xl border border-border bg-card p-6 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-center gap-5">
          {profile.avatar_url ? (
            <img
              src={profile.avatar_url}
              alt={profile.full_name}
              className="h-20 w-20 shrink-0 rounded-2xl object-cover"
            />
          ) : (
            <span
              className="flex h-20 w-20 shrink-0 items-center justify-center rounded-2xl text-3xl font-bold text-white"
              style={{ backgroundColor: avatarColor }}
            >
              {profile.full_name.charAt(0)}
            </span>
          )}
          <div>
            <h1 className="font-serif text-3xl font-bold tracking-tight">{profile.full_name}</h1>
            <p className="text-muted-foreground">@{profile.username}</p>
            {profile.bio && (
              <p className="mt-2 max-w-md text-pretty text-sm text-muted-foreground">{profile.bio}</p>
            )}
          </div>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" asChild>
            <a href="/dashboard/edit">
              <Pencil className="h-4 w-4" />
              Edit profile
            </a>
          </Button>
          <div className="relative" ref={settingsRef}>
            <Button
              variant="outline"
              size="icon"
              aria-label="Settings"
              aria-expanded={settingsOpen}
              onClick={() => setSettingsOpen((open) => !open)}
            >
              <Settings className="h-4 w-4" />
            </Button>
            {settingsOpen && (
              <div className="absolute right-0 z-10 mt-2 min-w-40 overflow-hidden rounded-xl border border-border bg-card py-1 shadow-md">
                <button
                  type="button"
                  onClick={handleLogout}
                  disabled={loggingOut}
                  className="flex w-full items-center gap-2 px-3 py-2.5 text-left text-sm text-destructive transition-colors hover:bg-secondary disabled:opacity-60"
                >
                  {loggingOut ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <LogOut className="h-4 w-4" />
                  )}
                  {loggingOut ? "Logging out..." : "Log out"}
                </button>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Stats */}
      <div className="mt-6 grid grid-cols-2 gap-4 sm:grid-cols-4">
        {[
          { label: "Templates Shared", value: uploads.length, icon: Upload },
          { label: "Total Downloads", value: totalDownloads.toLocaleString(), icon: Download },
          { label: "Total Likes", value: totalLikes.toLocaleString(), icon: Heart },
          {
            label: "Member Since",
            value: joinedAt
              ? new Date(joinedAt).toLocaleDateString("en-US", { month: "short", year: "numeric" })
              : "—",
            icon: TrendingUp,
          },
        ].map((stat) => (
          <div key={stat.label} className="rounded-2xl border border-border bg-card p-5">
            <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-primary/10 text-primary">
              <stat.icon className="h-4 w-4" />
            </div>
            <p className="mt-3 text-2xl font-semibold">{stat.value}</p>
            <p className="text-sm text-muted-foreground">{stat.label}</p>
          </div>
        ))}
      </div>

      {/* Tabs */}
      <div className="mt-10 flex items-center justify-between border-b border-border">
        <div className="flex gap-1">
          {TABS.map((t) => {
            const count =
              t.key === "my uploads"
                ? uploads.length
                : t.key === "my downloads"
                  ? downloaded.length
                  : liked.length
            return (
              <button
                key={t.key}
                onClick={() => setTab(t.key)}
                className={cn(
                  "flex items-center gap-2 border-b-2 px-4 py-3 text-sm font-medium transition-colors cursor-pointer",
                  tab === t.key
                    ? "border-primary text-foreground"
                    : "border-transparent text-muted-foreground hover:text-foreground",
                )}
              >
                <t.icon className="h-4 w-4" />
                {t.label}
                <span className="rounded-full bg-secondary px-1.5 text-xs text-muted-foreground">
                  {count}
                </span>
              </button>
            )
          })}
        </div>
        {tab === "my uploads" && (
          <Button asChild size="sm" className="hidden sm:inline-flex">
            <a href="/upload">
              <Upload className="h-4 w-4" />
              New upload
            </a>
          </Button>
        )}
      </div>

      {/* Content */}
      <div className="mt-8">
        {current.length > 0 ? (
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {current.map((template) => (
              <TemplateCard key={template.id} template={template} />
            ))}
          </div>
        ) : (
          <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-border py-20 text-center">
            <h3 className="text-lg font-semibold">{emptyCopy[tab].title}</h3>
            <p className="mt-1 max-w-sm text-sm text-muted-foreground">{emptyCopy[tab].body}</p>
            <Button asChild className="mt-5">
              <a href={tab === "my uploads" ? "/upload" : "/explore"}>
                {tab === "my uploads" ? "Share a template" : "Explore templates"}
              </a>
            </Button>
          </div>
        )}
      </div>
    </div>
  )
}