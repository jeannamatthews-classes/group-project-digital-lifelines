"use client"

import { useEffect, useRef, useState } from "react"
import { ArrowLeft, Camera, Check, Loader2 } from "lucide-react"
import { Button } from "../Components/buttons"
import { Input } from "../Components/input"
import { Textarea } from "../Components/textarea"
import { Label } from "../Components/label"
import { supabase } from "../../lib/supabase"
import {
  fetchProfile,
  updateProfile,
  uploadAvatar,
  colorForUsername,
  type DbProfile,
} from "../../lib/supabaseTemplates"
import { moderateFields, describeFlaggedFields } from "../../lib/moderation"

export default function EditProfilePage() {
  const [userId, setUserId] = useState<string | null | undefined>(undefined)
  const [profile, setProfile] = useState<DbProfile | null>(null)
  const [loadError, setLoadError] = useState<string | null>(null)

  const [fullName, setFullName] = useState("")
  const [bio, setBio] = useState("")
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null)
  const [avatarFile, setAvatarFile] = useState<File | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const [isSaving, setIsSaving] = useState(false)
  const [saveError, setSaveError] = useState<string | null>(null)
  const [saved, setSaved] = useState(false)

  useEffect(() => {
    let cancelled = false

    async function load() {
      const {
        data: { user },
      } = await supabase.auth.getUser()

      if (cancelled) return

      if (!user) {
        setUserId(null)
        return
      }
      setUserId(user.id)

      try {
        const data = await fetchProfile(user.id)
        if (cancelled) return
        setProfile(data)
        if (data) {
          setFullName(data.full_name)
          setBio(data.bio ?? "")
          setAvatarPreview(data.avatar_url)
        }
      } catch (err) {
        if (!cancelled) setLoadError(err instanceof Error ? err.message : "Failed to load profile.")
      }
    }

    load()
    return () => {
      cancelled = true
    }
  }, [])

  function handleAvatarSelect(file: File | undefined) {
    if (!file) return
    setAvatarFile(file)
    setAvatarPreview(URL.createObjectURL(file))
  }

  async function handleSave(e: React.FormEvent) {
    e.preventDefault()
    if (!userId) return
    setSaveError(null)
    setIsSaving(true)

    try {
      const moderation = await moderateFields({ "Full name": fullName, Bio: bio })
      if (moderation.flagged) {
        setSaveError(describeFlaggedFields(moderation))
        setIsSaving(false)
        return
      }

      let avatarUrl = profile?.avatar_url ?? null

      if (avatarFile) {
        avatarUrl = await uploadAvatar(userId, avatarFile)
      }

      await updateProfile(userId, { full_name: fullName, bio: bio || null })

      if (avatarFile) {
        const { error: avatarUpdateError } = await supabase
          .from("users_profiles")
          .update({ avatar_url: avatarUrl })
          .eq("id", userId)
        if (avatarUpdateError) throw avatarUpdateError
      }

      setSaved(true)
      setTimeout(() => {
        window.location.href = "/dashboard"
      }, 800)
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : "Failed to save profile.")
      setIsSaving(false)
    }
  }

  if (userId === undefined) {
    return (
      <div className="mx-auto flex max-w-xl items-center justify-center gap-2 px-4 py-24 text-muted-foreground">
        <Loader2 className="h-4 w-4 animate-spin" />
        Loading...
      </div>
    )
  }

  if (userId === null) {
    return (
      <div className="mx-auto max-w-xl px-4 py-24 text-center">
        <h1 className="font-serif text-2xl font-semibold">You're not logged in</h1>
        <Button asChild className="mt-6">
          <a href="/login">Log in</a>
        </Button>
      </div>
    )
  }

  if (loadError || !profile) {
    return (
      <div className="mx-auto max-w-xl px-4 py-24 text-center">
        <p className="text-sm text-destructive">{loadError ?? "Profile not found."}</p>
      </div>
    )
  }

  const fallbackColor = colorForUsername(profile.username)

  return (
    <div className="mx-auto max-w-xl px-4 py-10 sm:px-6 lg:px-8">
      <a
        href="/dashboard"
        className="inline-flex items-center gap-2 text-sm font-medium text-muted-foreground transition-colors hover:text-foreground"
      >
        <ArrowLeft className="h-4 w-4" />
        Back to dashboard
      </a>

      <h1 className="mt-4 font-serif text-3xl font-bold tracking-tight">Edit profile</h1>

      <form onSubmit={handleSave} className="mt-8 flex flex-col gap-6">
        {/* Avatar */}
        <div className="flex items-center gap-5">
          <button
            type="button"
            onClick={() => fileInputRef.current?.click()}
            className="group relative h-24 w-24 shrink-0 overflow-hidden rounded-2xl"
          >
            {avatarPreview ? (
              <img src={avatarPreview} alt="Avatar preview" className="h-full w-full object-cover" />
            ) : (
              <span
                className="flex h-full w-full items-center justify-center text-3xl font-bold text-white"
                style={{ backgroundColor: fallbackColor }}
              >
                {fullName.charAt(0) || "?"}
              </span>
            )}
            <span className="absolute inset-0 flex items-center justify-center bg-foreground/0 text-transparent transition-colors group-hover:bg-foreground/40 group-hover:text-white">
              <Camera className="h-6 w-6" />
            </span>
          </button>
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={(e) => handleAvatarSelect(e.target.files?.[0])}
          />
          <div>
            <Button type="button" variant="outline" size="sm" onClick={() => fileInputRef.current?.click()}>
              Change photo
            </Button>
            <p className="mt-1.5 text-xs text-muted-foreground">JPG or PNG, square works best.</p>
          </div>
        </div>

        <div>
          <Label htmlFor="fullName">Full name</Label>
          <Input
            id="fullName"
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            className="mt-1.5"
            required
          />
        </div>

        <div>
          <Label>Username</Label>
          <p className="mt-1.5 rounded-lg border border-border bg-secondary/40 px-3 py-2 text-sm text-muted-foreground">
            @{profile.username}
          </p>
        </div>

        <div>
          <Label htmlFor="bio">Bio</Label>
          <Textarea
            id="bio"
            value={bio}
            onChange={(e) => setBio(e.target.value)}
            placeholder="A short line about yourself"
            className="mt-1.5 min-h-24"
          />
        </div>

        {saveError && (
          <div className="rounded-xl border border-destructive/30 bg-destructive/10 p-4 text-sm text-destructive">
            {saveError}
          </div>
        )}

        <div className="flex gap-3">
          <Button type="submit" disabled={isSaving}>
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
              "Save changes"
            )}
          </Button>
          <Button type="button" variant="outline" asChild disabled={isSaving}>
            <a href="/dashboard">Cancel</a>
          </Button>
        </div>
      </form>
    </div>
  )
}