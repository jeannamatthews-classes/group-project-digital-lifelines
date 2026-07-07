"use client"

import { useState } from "react"
import { Upload, Download, Heart, Settings, Pencil, TrendingUp } from "lucide-react"
import { Button } from "../Components/buttons"
import { TemplateCard } from "../Components/template-card"
import { TEMPLATES, CURRENT_USER } from "../../lib/templates"
import { cn } from "../../lib/utils"

type Tab = "uploads" | "downloaded" | "liked"

const TABS: { key: Tab; label: string; icon: typeof Upload }[] = [
  { key: "uploads", label: "My uploads", icon: Upload },
  { key: "downloaded", label: "Downloaded", icon: Download },
  { key: "liked", label: "Liked", icon: Heart },
]

export default function DashboardPage() {
  const [tab, setTab] = useState<Tab>("uploads")

  const uploads = TEMPLATES.filter((t) => CURRENT_USER.uploads.includes(t.id))
  const downloaded = TEMPLATES.filter((t) => CURRENT_USER.downloaded.includes(t.id))
  const liked = TEMPLATES.filter((t) => CURRENT_USER.liked.includes(t.id))

  const totalDownloads = uploads.reduce((sum, t) => sum + t.downloads, 0)
  const totalLikes = uploads.reduce((sum, t) => sum + t.likes, 0)

  const current = tab === "uploads" ? uploads : tab === "downloaded" ? downloaded : liked

  const emptyCopy: Record<Tab, { title: string; body: string }> = {
    uploads: {
      title: "No uploads yet",
      body: "Share your first timeline template with the community.",
    },
    downloaded: {
      title: "Nothing downloaded yet",
      body: "Browse the gallery and download a template to get started.",
    },
    liked: {
      title: "No liked templates",
      body: "Tap the heart on any template to save it here.",
    },
  }

  return (
    <div className="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
      {/* Profile header */}
      <div className="flex flex-col gap-6 rounded-2xl border border-border bg-card p-6 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-center gap-5">
          <span
            className="flex h-20 w-20 shrink-0 items-center justify-center rounded-2xl text-3xl font-bold text-white"
            style={{ backgroundColor: CURRENT_USER.avatarColor }}
          >
            {CURRENT_USER.name.charAt(0)}
          </span>
          <div>
            <h1 className="font-serif text-3xl font-bold tracking-tight">{CURRENT_USER.name}</h1>
            <p className="text-muted-foreground">@{CURRENT_USER.handle}</p>
            <p className="mt-2 max-w-md text-pretty text-sm text-muted-foreground">
              {CURRENT_USER.bio}
            </p>
          </div>
        </div>
        <div className="flex gap-2">
          <Button variant="outline">
            <Pencil className="h-4 w-4" />
            Edit profile
          </Button>
          <Button variant="outline" size="icon" aria-label="Settings">
            <Settings className="h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Stats */}
      <div className="mt-6 grid grid-cols-2 gap-4 sm:grid-cols-4">
        {[
          { label: "Templates shared", value: uploads.length, icon: Upload },
          { label: "Total downloads", value: totalDownloads.toLocaleString(), icon: Download },
          { label: "Total likes", value: totalLikes.toLocaleString(), icon: Heart },
          {
            label: "Member since",
            value: new Date(CURRENT_USER.joinedAt).toLocaleDateString("en-US", {
              month: "short",
              year: "numeric",
            }),
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
              t.key === "uploads"
                ? uploads.length
                : t.key === "downloaded"
                  ? downloaded.length
                  : liked.length
            return (
              <button
                key={t.key}
                onClick={() => setTab(t.key)}
                className={cn(
                  "flex items-center gap-2 border-b-2 px-4 py-3 text-sm font-medium transition-colors",
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
        {tab === "uploads" && (
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
              <a href={tab === "uploads" ? "/upload" : "/explore"}>
                {tab === "uploads" ? "Share a template" : "Explore templates"}
              </a>
            </Button>
          </div>
        )}
      </div>
    </div>
  )
}
