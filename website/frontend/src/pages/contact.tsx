import { useEffect, useState } from "react"
import { CheckCircle2, ClipboardList, Mail, Users } from "lucide-react"
import { Button } from "../Components/buttons"
import { supabase } from "../../lib/supabase"

const GOOGLE_FORM_RESPONSE_URL = "https://docs.google.com/forms/d/e/1FAIpQLSd1Tj954soWtnbwl_dfrdpYpDbxlDOd5noldTsPRbjDbObcfg/formResponse"

const TEAM = [
  {
    id: "7a27fa10-2407-4a2a-8010-c72a5a09775f",
    name: "Jeanna",
    role: "Team member",
    email: "jeanna.matthews@gmail.com",
    accent: "bg-chart-4-subtle text-chart-4",
  },
  {
    id: "5785f73d-1696-44ae-ab55-fc68d1bd205a",
    name: "Ashik",
    role: "Team member",
    email: "ahameda@clarkson.edu",
    accent: "bg-chart-6-subtle text-chart-6",
  },
  {
    id: "469fb748-1ecf-4260-a7df-298697899531",
    name: "Esu",
    role: "Team member",
    email: "beredaed@clarkson.edu",
    accent: "bg-chart-4-subtle text-chart-4",
  },
  {
    id: "886ad16b-e3b3-4bab-bb3d-c6e59a326a73",
    name: "Max",
    role: "Team member",
    email: "mawang@clarkson.edu",
    accent: "bg-chart-1-subtle text-chart-1",
  },
  {
    id: "",
    name: "Bhawana",
    role: "Team member",
    email: "khatrib@clarkson.edu",
    accent: "bg-chart-1-subtle text-chart-1",
  },
]

type TeamProfile = {
  full_name: string
  avatar_url: string | null
}

export default function Contact() {
  const [activeTab, setActiveTab] = useState<"contact" | "team">("contact")
  const [submissionStatus, setSubmissionStatus] = useState<"idle" | "sending" | "sent" | "failed">("idle")
  const [teamProfiles, setTeamProfiles] = useState<Record<string, TeamProfile>>({})

  useEffect(() => {
    let cancelled = false
    const ids = TEAM.flatMap((member) => member.id ? [member.id] : [])

    async function loadTeamProfiles() {
      const { data } = await supabase
        .from("users_profiles")
        .select("id, full_name, avatar_url")
        .in("id", ids)

      if (!cancelled) {
        setTeamProfiles(Object.fromEntries((data ?? []).map((profile) => [profile.id, profile])))
      }
    }

    loadTeamProfiles()
    return () => {
      cancelled = true
    }
  }, [])

  return (
    <div className="relative isolate overflow-hidden">
      <div className="pointer-events-none absolute inset-x-0 top-0 -z-10 h-96 bg-[radial-gradient(circle_at_top_right,var(--color-chart-4-subtle),transparent_55%),radial-gradient(circle_at_top_left,var(--color-chart-6-subtle),transparent_45%)] opacity-70" />
      <div className="mx-auto max-w-7xl px-4 py-12 sm:px-6 sm:py-16 lg:px-8">
        <div className="max-w-3xl">
          <p className="text-md font-semibold uppercase tracking-[0.18em] text-primary">Stay connected with us</p>
          <p className="mt-4 max-w-2xl text-pretty text-lg leading-relaxed text-muted-foreground">
            Have a question, suggestion for improvement, or something you would like to share? Reach out to the people behind Digital Lifelines.
          </p>
        </div>

        <div className="mt-10 border-b border-border">
          <div className="flex gap-6" role="tablist" aria-label="Contact options">
            <button
              type="button"
              role="tab"
              aria-selected={activeTab === "contact"}
              onClick={() => setActiveTab("contact")}
              className={`flex items-center gap-2 border-b-2 px-1 pb-3 text-sm font-semibold transition-colors ${
                activeTab === "contact" ? "border-primary text-foreground" : "border-transparent text-muted-foreground hover:text-foreground"
              }`}
            >
              <ClipboardList className="h-4 w-4" />
              Contact us
            </button>
            <button
              type="button"
              role="tab"
              aria-selected={activeTab === "team"}
              onClick={() => setActiveTab("team")}
              className={`flex items-center gap-2 border-b-2 px-1 pb-3 text-sm font-semibold transition-colors ${
                activeTab === "team" ? "border-primary text-foreground" : "border-transparent text-muted-foreground hover:text-foreground"
              }`}
            >
              <Users className="h-4 w-4" />
              Meet the team
            </button>
          </div>
        </div>

        {activeTab === "contact" ? (
          <section className="mt-8 grid gap-8 lg:grid-cols-[1fr_0.72fr]" role="tabpanel">
            <div className="rounded-2xl border border-border bg-card p-6 shadow-sm sm:p-8">
              <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-primary text-primary-foreground">
                <Mail className="h-5 w-5" />
              </div>
              <h2 className="mt-6 text-2xl font-semibold tracking-tight">Tell us what is on your mind</h2>
              {submissionStatus === "sent" ? (
                <section className="mt-8 rounded-xl border border-chart-1/30 bg-chart-1-subtle p-6" aria-live="polite">
                  <div className="flex h-12 w-12 items-center justify-center rounded-full bg-chart-1 text-white">
                    <CheckCircle2 className="h-6 w-6" />
                  </div>
                  <h3 className="mt-5 text-2xl font-semibold tracking-tight">Message sent successfully</h3>
                  <p className="mt-2 max-w-lg leading-relaxed text-muted-foreground">
                    Thanks for reaching out. Your response has been recorded and will be reviewed by the Digital Lifelines team.
                  </p>
                  <Button type="button" variant="outline" className="mt-6" onClick={() => setSubmissionStatus("idle")}>
                    Send another message
                  </Button>
                </section>
              ) : (
                <form
                  action={GOOGLE_FORM_RESPONSE_URL}
                  method="POST"
                  target="google-form-submit"
                  onSubmit={() => {
                    setSubmissionStatus("sending")
                    window.setTimeout(() => setSubmissionStatus((status) => status === "sending" ? "failed" : status), 10000)
                  }}
                  className="mt-7 space-y-5"
                >
                  <div>
                    <label htmlFor="contact-name" className="text-sm font-semibold">Name</label>
                    <input
                      id="contact-name"
                      name="entry.1299078003"
                      type="text"
                      required
                      className="mt-2 h-11 w-full rounded-lg border border-input bg-background px-3 text-sm outline-none transition focus-visible:ring-2 focus-visible:ring-ring"
                      placeholder="Your name"
                    />
                  </div>
                  <div>
                    <label htmlFor="contact-email" className="text-sm font-semibold">Email</label>
                    <input
                      id="contact-email"
                      name="entry.140782506"
                      type="email"
                      required
                      className="mt-2 h-11 w-full rounded-lg border border-input bg-background px-3 text-sm outline-none transition focus-visible:ring-2 focus-visible:ring-ring"
                      placeholder="you@example.com"
                    />
                  </div>
                  <div>
                    <label htmlFor="contact-message" className="text-sm font-semibold">Message</label>
                    <textarea
                      id="contact-message"
                      name="entry.1220585684"
                      required
                      rows={5}
                      className="mt-2 w-full resize-y rounded-lg border border-input bg-background px-3 py-3 text-sm outline-none transition focus-visible:ring-2 focus-visible:ring-ring"
                      placeholder="How can we help?"
                    />
                  </div>
                  <input type="hidden" name="fvv" value="1" />
                  <input type="hidden" name="pageHistory" value="0" />
                  {submissionStatus === "failed" && (
                    <p className="rounded-lg border border-destructive/30 bg-destructive/10 p-3 text-sm font-medium text-destructive" role="alert">
                      We could not confirm the submission. Please try again.
                    </p>
                  )}
                  <Button type="submit" disabled={submissionStatus === "sending"}>
                    {submissionStatus === "sending" ? "Sending..." : "Send message"}
                  </Button>
                </form>
              )}
              <iframe
                name="google-form-submit"
                title="Google Forms submission status"
                onLoad={() => setSubmissionStatus((status) => status === "sending" ? "sent" : status)}
                className="hidden"
                aria-hidden="true"
              />
            </div>

            <aside className="rounded-2xl border border-border bg-secondary/60 p-6 sm:p-8 h-fit">
              <p className="text-sm font-semibold uppercase tracking-[0.16em] text-primary">Before you write</p>
              <h2 className="mt-4 font-serif text-2xl font-bold">A little context helps.</h2>
              <ul className="mt-5 space-y-4 text-sm leading-relaxed text-muted-foreground">
                <li><span className="font-semibold text-foreground">For support:</span> include the page or template where you ran into trouble.</li>
                <li><span className="font-semibold text-foreground">For ideas:</span> tell us what you were trying to do and what would make it easier.</li>
                <li><span className="font-semibold text-foreground">For Experience:</span> let us know something you learned new about someone or how this app helped you connect with someone.</li>

              </ul>
            </aside>
          </section>
        ) : (
          <section className="mt-8" role="tabpanel">
            <div className="max-w-2xl">
              <h2 className="font-serif text-3xl font-bold tracking-tight">The people behind the project</h2>
              <p className="mt-2 leading-relaxed text-muted-foreground">
                Reach out directly, or use the contact form for a message to the whole team.
              </p>
            </div>
            <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {TEAM.map((member) => {
                const profile = member.id ? teamProfiles[member.id] : undefined
                const name = profile?.full_name || member.name

                return (
                  <article key={member.name} className="rounded-2xl border border-border bg-card p-6 shadow-sm">
                    {profile?.avatar_url ? (
                      <img src={profile.avatar_url} alt={name} className="h-14 w-14 rounded-2xl object-cover" />
                    ) : (
                      <div className={`flex h-14 w-14 items-center justify-center rounded-2xl text-xl font-bold ${member.accent}`}>
                        {name.charAt(0)}
                      </div>
                    )}
                    <h3 className="mt-6 text-xl font-semibold">{name}</h3>
                    <p className="mt-1 text-sm text-muted-foreground">{member.role}</p>
                    <a
                      href={`mailto:${member.email}`}
                      className="mt-6 flex items-center gap-2 text-sm font-medium text-primary hover:underline"
                    >
                      <Mail className="h-4 w-4" />
                      {member.email}
                    </a>
                  </article>
                )
              })}
            </div>
          </section>
        )}
      </div>
    </div>
  )
}
