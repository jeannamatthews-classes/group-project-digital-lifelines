"use client"

import { useState } from "react"
import { Link } from "react-router-dom"
import { Activity, LogIn, UserPlus, Mail, Lock, User, ArrowRight } from "lucide-react"
import { Button } from "../Components/buttons"
import { Input } from "../Components/input"
import { Label } from "../Components/label"
import { cn } from "../../lib/utils"
import { supabase } from "../../lib/supabase";

type AuthMode = "login" | "signup"

export default function SignupPage() {
  const [mode, setMode] = useState<AuthMode>("login")
  const [name, setName] = useState("")
  const [email, setEmail] = useState("")
  const [username, setUsername] = useState("")
  const [password, setPassword] = useState("")
  const [confirmPassword, setConfirmPassword] = useState("")

  async function SignUp() {
    if (password !== confirmPassword) {
      alert("Passwords do not match.");
      return;
    }

    const { data, error } = await supabase.auth.signUp({
      email,
      password,
    });

    if (error) {
      alert(error.message);
      return;
    }

    if (!data.user) {
      alert("Failed to create user.");
      return;
    }

    // Profile row is created on first login (see Login()),
    // since signUp() may not return an active session if
    // email confirmation is required.
    alert("Account created! Please check your email to confirm, then log in.");
  }

  async function Login() {
    const { error: loginError } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (loginError) {
      alert(loginError.message);
      return;
    }

    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) return;

    // Check if the profile already exists
    const { data: profile, error: profileError } = await supabase
      .from("users_profiles")
      .select("*")
      .eq("id", user.id);

    if (profileError) {
      alert(profileError.message);
      return;
    }

    // If no profile exists yet, create one
    if (profile.length === 0) {
      const { error: insertError } = await supabase
        .from("users_profiles")
        .insert({
          id: user.id,
          username: username || user.email?.split("@")[0],
          full_name: name,
        });

      if (insertError) {
        alert(insertError.message);
        return;
      }
    }

    window.location.href = "/explore";
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();

    if (mode === "signup") {
      await SignUp();
    } else {
      await Login();
    }
  }

  return (
    <div className="mx-auto flex min-h-[calc(100dvh-2rem)] max-w-7xl items-center px-4 py-12 sm:px-6 lg:px-8">
      <div className="grid w-full overflow-hidden rounded-3xl border border-border bg-card shadow-sm lg:grid-cols-2">
        {/* Brand panel */}
        <div className="relative hidden flex-col justify-between bg-primary p-10 text-primary-foreground lg:flex">
          <div>
            <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-primary-foreground/15">
              <Activity className="h-6 w-6" />
            </div>
            <h2 className="mt-8 font-serif text-3xl font-bold leading-tight">
              Join the Digital Lifelines community
            </h2>
            <p className="mt-4 max-w-sm text-pretty leading-relaxed opacity-90">
              Save templates, track your uploads, and connect with lifeloggers who share how they document their lives.
            </p>
          </div>
          <ul className="flex flex-col gap-4 text-sm opacity-90">
            {[
              "Bookmark and like community templates",
              "Upload and manage your own timelines",
              "Sync activity across the web and app",
            ].map((item) => (
              <li key={item} className="flex items-start gap-3">
                <span className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-primary-foreground/70" />
                {item}
              </li>
            ))}
          </ul>
        </div>

        {/* Form panel */}
        <div className="flex flex-col justify-center p-8 sm:p-10 lg:p-12">
          <div className="mx-auto w-full max-w-sm">
            <div className="flex items-center gap-2.5 lg:hidden">
              <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary">
                <Activity className="h-5 w-5 text-primary-foreground" />
              </div>
              <span className="text-lg font-semibold tracking-tight">Digital Lifelines Web</span>
            </div>

            <h1 className="mt-6 font-serif text-3xl font-bold tracking-tight lg:mt-0">
              {mode === "login" ? "Welcome back" : "Create an account"}
            </h1>
            <p className="mt-2 text-sm text-muted-foreground">
              {mode === "login"
                ? "Sign in to access your dashboard and saved templates."
                : "Get started in seconds"}
            </p>

            {/* Mode toggle */}
            <div className="mt-8 flex rounded-xl border border-border bg-secondary/50 p-1">
              <button
                type="button"
                onClick={() => setMode("login")}
                className={cn(
                  "flex flex-1 items-center justify-center gap-2 rounded-lg px-3 py-2.5 text-sm font-medium transition-all",
                  mode === "login"
                    ? "bg-background text-foreground shadow-sm"
                    : "text-muted-foreground hover:text-foreground",
                )}
              >
                <LogIn className="h-4 w-4" />
                Log in
              </button>
              <button
                type="button"
                onClick={() => setMode("signup")}
                className={cn(
                  "flex flex-1 items-center justify-center gap-2 rounded-lg px-3 py-2.5 text-sm font-medium transition-all",
                  mode === "signup"
                    ? "bg-background text-foreground shadow-sm"
                    : "text-muted-foreground hover:text-foreground",
                )}
              >
                <UserPlus className="h-4 w-4" />
                Sign up
              </button>
            </div>

            <form onSubmit={handleSubmit} className="mt-8 flex flex-col gap-5">
              {mode === "signup" && (
                <div>
                  <Label htmlFor="name">Full name</Label>
                  <div className="relative mt-1.5">
                    <User className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                    <Input
                      id="name"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      placeholder="Jane Doe"
                      className="pl-9"
                      required
                      autoComplete="name"
                    />
                  </div>
                </div>
              )}

              <div>
                <Label htmlFor="email">Email</Label>
                <div className="relative mt-1.5">
                  <Mail className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <Input
                    id="email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="you@example.com"
                    className="pl-9"
                    required
                    autoComplete="email"
                  />
                </div>
              </div>

              <div>
                <Label htmlFor="username">Username</Label>
                <div className="relative mt-1.5">
                  <Mail className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <Input
                    id="username"
                    type="text"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    placeholder="@username"
                    className="pl-9"
                    required
                    autoComplete="username"
                  />
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between">
                  <Label htmlFor="password">Password</Label>
                  {mode === "login" && (
                    <button
                      type="button"
                      className="text-xs font-medium text-primary hover:underline"
                    >
                      Forgot password?
                    </button>
                  )}
                </div>
                <div className="relative mt-1.5">
                  <Lock className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <Input
                    id="password"
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder={mode === "signup" ? "At least 8 characters" : "••••••••"}
                    className="pl-9"
                    required
                    minLength={mode === "signup" ? 8 : undefined}
                    autoComplete={mode === "login" ? "current-password" : "new-password"}
                  />
                </div>
              </div>

              {mode === "signup" && (
                <div>
                  <Label htmlFor="confirm-password">Confirm password</Label>
                  <div className="relative mt-1.5">
                    <Lock className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                    <Input
                      id="confirm-password"
                      type="password"
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      placeholder="••••••••"
                      className="pl-9"
                      required
                      minLength={8}
                      autoComplete="new-password"
                    />
                  </div>
                </div>
              )}

              <Button type="submit" size="lg" className="mt-1 w-full">
                {mode === "login" ? (
                  <>
                    Log in
                    <ArrowRight className="h-4 w-4" />
                  </>
                ) : (
                  <>
                    Create account
                    <UserPlus className="h-4 w-4" />
                  </>
                )}
              </Button>
            </form>

            <p className="mt-6 text-center text-sm text-muted-foreground">
              {mode === "login" ? (
                <>
                  Don't have an account?{" "}
                  <button
                    type="button"
                    onClick={() => setMode("signup")}
                    className="font-medium text-primary hover:underline"
                  >
                    Sign up
                  </button>
                </>
              ) : (
                <>
                  Already have an account?{" "}
                  <button
                    type="button"
                    onClick={() => setMode("login")}
                    className="font-medium text-primary hover:underline"
                  >
                    Log in
                  </button>
                </>
              )}
            </p>

            <p className="mt-8 text-center text-xs leading-relaxed text-muted-foreground">
              By continuing, you agree to our community guidelines.{" "}
              <Link to="/explore" className="text-primary hover:underline">
                Browse templates
              </Link>{" "}
              without an account anytime.
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}