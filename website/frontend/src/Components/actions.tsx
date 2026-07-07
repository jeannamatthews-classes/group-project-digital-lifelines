"use client"

import { useState } from "react"
import { Download, Heart, Check, Copy, Share2 } from "lucide-react"
import { Button } from "./buttons"
import { buildTemplateJson, type TeamTemplate } from "../../lib/templates"

export function TemplateActions({ template }: { template: TeamTemplate }) {
  const [liked, setLiked] = useState(false)
  const [downloaded, setDownloaded] = useState(false)
  const [copied, setCopied] = useState(false)

  const json = JSON.stringify(buildTemplateJson(template), null, 2)

  function handleDownload() {
    const blob = new Blob([json], { type: "application/json" })
    const url = URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = `${template.id}.json`
    a.click()
    URL.revokeObjectURL(url)
    setDownloaded(true)
    setTimeout(() => setDownloaded(false), 2000)
  }

  function handleCopy() {
    navigator.clipboard.writeText(json)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  function handleShare() {
    if (navigator.share) {
      navigator.share({ title: template.name, text: template.tagline }).catch(() => {})
    } else {
      navigator.clipboard.writeText(typeof window !== "undefined" ? window.location.href : "")
    }
  }

  return (
    <div className="flex flex-col gap-3">
      <Button size="lg" onClick={handleDownload} className="w-full">
        {downloaded ? <Check className="h-4 w-4" /> : <Download className="h-4 w-4" />}
        {downloaded ? "Downloaded!" : "Download JSON"}
      </Button>
      <div className="grid grid-cols-3 gap-2">
        <Button variant="outline" onClick={() => setLiked((v) => !v)} aria-pressed={liked}>
          <Heart className={liked ? "h-4 w-4 fill-destructive text-destructive" : "h-4 w-4"} />
          {liked ? "Liked" : "Like"}
        </Button>
        <Button variant="outline" onClick={handleCopy}>
          {copied ? <Check className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
          {copied ? "Copied" : "Copy"}
        </Button>
        <Button variant="outline" onClick={handleShare}>
          <Share2 className="h-4 w-4" />
          Share
        </Button>
      </div>
    </div>
  )
}

export function JsonPreview({ template }: { template: TeamTemplate }) {
  const [copied, setCopied] = useState(false)
  const json = JSON.stringify(buildTemplateJson(template), null, 2)

  function handleCopy() {
    navigator.clipboard.writeText(json)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className="overflow-hidden rounded-xl border border-border bg-[#1a1d2e]">
      <div className="flex items-center justify-between border-b border-white/10 px-4 py-2.5">
        <div className="flex items-center gap-1.5">
          <span className="h-3 w-3 rounded-full bg-[#ff5f57]" />
          <span className="h-3 w-3 rounded-full bg-[#febc2e]" />
          <span className="h-3 w-3 rounded-full bg-[#28c840]" />
          <span className="ml-2 font-mono text-xs text-white/50">{template.id}.json</span>
        </div>
        <button
          onClick={handleCopy}
          className="inline-flex items-center gap-1.5 rounded-md px-2 py-1 text-xs text-white/70 transition-colors hover:bg-white/10 hover:text-white"
        >
          {copied ? <Check className="h-3.5 w-3.5" /> : <Copy className="h-3.5 w-3.5" />}
          {copied ? "Copied" : "Copy"}
        </button>
      </div>
      <pre className="overflow-x-auto p-4 font-mono text-xs leading-relaxed text-[#c8d3f5]">
        <code>{json}</code>
      </pre>
    </div>
  )
}
