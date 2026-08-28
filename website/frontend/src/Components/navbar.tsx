"use client"

import { Link, useLocation } from "react-router-dom"
import { useEffect, useState } from "react"
import { cn } from "../../lib/utils"
import { Button } from "./buttons"
import { Menu, X, Activity, Search, Upload,User } from "lucide-react"
import { supabase } from "../../lib/supabase"
import type { User as SupabaseUser } from "@supabase/supabase-js"

const NAV_LINKS = [
  { href: "/explore", label: "Explore" },
  { href: "/upload", label: "Upload" },
  { href: "/dashboard", label: "Dashboard" },
]

export function NavBar() {

    const location = useLocation()
    const pathname = location.pathname
    const [open, setOpen] = useState(false)

    const [user, setUser] = useState<SupabaseUser | null>(null)

    useEffect(() => {
    const getUser = async () => {
      const {
        data: { user },
      } = await supabase.auth.getUser()

      setUser(user)
    }

    getUser()

    // Listen for login/logout
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null)
    })

    return () => {
      subscription.unsubscribe()
    }
  }, [])

  const isLoggedIn = () => user !== null

    return (
      <header className="sticky top-0 z-50 border-b border-border bg-background/80 backdrop-blur-md">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between gap-4 px-4 sm:px-6 lg:px-8">
        <Link to="/" className="flex items-center gap-2.5" onClick={() => setOpen(false)}>
          <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary">
            <Activity className="h-5 w-5 text-primary-foreground" />
          </div>
          <span className="text-lg font-semibold tracking-tight">Digital Lifelines Web</span>
        </Link>

        <nav className="hidden items-center gap-1 md:flex">
          {NAV_LINKS.map((link) => (
            <Link
              key={link.href}
              to={link.href}
              className={cn(
                "rounded-lg px-3 py-2 text-sm font-medium transition-colors",
                pathname === link.href || pathname.startsWith(link.href + "/")
                  ? "bg-secondary text-foreground font-semibold"
                  : "text-muted-foreground hover:bg-secondary hover:text-foreground",
              )}
            >
              {link.label}
            </Link>
          ))}
        </nav>

        <div className="hidden items-center gap-2 md:flex">
          <Button asChild variant="ghost" size="icon" aria-label="Search">
            <Link to="/explore">
              <Search className="h-5 w-5" />
            </Link>
          </Button>
          <Button asChild>
            {isLoggedIn() ? (
              <Link to="/upload">
                <Upload className="h-4 w-4" />
                Share a template
              </Link>
            ) : (
              <Link to="/auth">
                <User className="h-4 w-4" />
                Login/Signup
              </Link>
            )}
          </Button>
          <Link to="/contact">
              Contact Us
            </Link>
        </div>

        <button
          className="inline-flex items-center justify-center rounded-lg p-2 text-foreground md:hidden"
          onClick={() => setOpen((v) => !v)}
          aria-label="Toggle menu"
        >
          {open ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
        </button>
      </div>

      {open && (
        <div className="border-t border-border bg-background md:hidden">
          <nav className="mx-auto flex max-w-7xl flex-col gap-1 px-4 py-3">
            {NAV_LINKS.map((link) => (
              <Link
                key={link.href}
                to={link.href}
                onClick={() => setOpen(false)}
                className={cn(
                  "rounded-lg px-3 py-2.5 text-sm font-medium transition-colors",
                  pathname === link.href
                    ? "bg-secondary text-foreground"
                    : "text-muted-foreground hover:bg-secondary",
                )}
              >
                {link.label}
              </Link>
            ))}
            <Link
              to="/contact"
              onClick={() => setOpen(false)}
              className={cn(
                "rounded-lg px-3 py-2.5 text-sm font-medium transition-colors",
                pathname === "/contact"
                  ? "bg-secondary text-foreground"
                  : "text-muted-foreground hover:bg-secondary",
              )}
            >
              Contact Us
            </Link>
            <Button asChild className="mt-2">
              {isLoggedIn() ? (
                <Link to="/upload" onClick={() => setOpen(false)}>
                  <Upload className="h-4 w-4" />
                  Share a template
                </Link>
              ) : (
                <Link to="/auth" onClick={() => setOpen(false)}>
                  <User className="h-4 w-4" />
                  Login/Signup
                </Link>
              )}
            </Button>
          </nav>
        </div>
      )}
    </header>
    )
}