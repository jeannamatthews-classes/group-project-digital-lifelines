import { Activity } from "lucide-react"

const FOOTER_LINKS = [
  {
    title: "Discover",
    links: [
      { label: "Explore templates", href: "/explore" },
      { label: "Featured", href: "/explore" },
      { label: "Categories", href: "/explore" },
      { label: "Most downloaded", href: "/explore" },
    ],
  },
  {
    title: "Create",
    links: [
      { label: "Share a template", href: "/upload" },
      { label: "Your dashboard", href: "/dashboard" },
      { label: "JSON format guide", href: "/upload" },
      { label: "Get the app", href: "/" },
    ],
  },
  {
    title: "Community",
    links: [
      { label: "About", href: "/" },
      { label: "Guidelines", href: "/" },
      { label: "Support", href: "/" },
      { label: "Changelog", href: "/" },
    ],
  },
]

export function Footer() {
  return (
    <footer className="border-t border-border bg-card">
      <div className="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8">
        <div className="grid gap-10 md:grid-cols-2 lg:grid-cols-5">
          <div className="lg:col-span-2">
            <a href="/" className="flex items-center gap-2.5">
              <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary">
                <Activity className="h-5 w-5 text-primary-foreground" />
              </div>
              <span className="text-lg font-semibold tracking-tight">Digital Lifeline Web</span>
            </a>
            <p className="mt-4 max-w-sm text-pretty text-sm leading-relaxed text-muted-foreground">
              The community library of timeline templates for Digital Lifelines, Building better digital connections.
            </p>
          </div>
          {FOOTER_LINKS.map((col) => (
            <div key={col.title}>
              <h3 className="text-sm font-semibold">{col.title}</h3>
              <ul className="mt-4 flex flex-col gap-3">
                {col.links.map((link) => (
                  <li key={link.label}>
                    <a
                      href={link.href}
                      className="text-sm text-muted-foreground transition-colors hover:text-foreground"
                    >
                      {link.label}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
        <div className="mt-12 flex flex-col items-start justify-between gap-4 border-t border-border pt-8 sm:flex-row sm:items-center">
          <p className="text-sm text-muted-foreground">
            &copy; {new Date().getFullYear()} Digital Lifelines Web. A companion to Digital Lifelines App.
          </p>
          <div className="flex gap-6 text-sm text-muted-foreground">
            {/* <a href="/" className="transition-colors hover:text-foreground">
              Privacy
            </a>
            <a href="/" className="transition-colors hover:text-foreground">
              Terms
            </a> */}
          </div>
        </div>
      </div>
    </footer>
  )
}