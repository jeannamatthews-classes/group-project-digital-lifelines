import { ArrowRight, Download, Search, Upload, Users, Disc2 } from "lucide-react"
import { Button } from "../Components/buttons"
import { TEMPLATES, getFeatured, CATEGORIES } from "../../lib/templates"
import { DynamicIcon } from "../Components/icons"
import { TemplateCard } from "../Components/template-card"
import  Carousel  from "../Components/carousel"

export default function Landing(){
    const featured = getFeatured()
    const trending = [...TEMPLATES].sort((a, b) => b.downloads - a.downloads).slice(0, 8)

    return(
        <>
        {/* digital lifelines */}

        <Carousel />

      {/* categories */}

        <section className="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
        <div className="flex items-end justify-between">
          <div>
            <h2 className="text-2xl font-semibold tracking-tight">Browse by category</h2>
            <p className="mt-1 text-muted-foreground">Find a template for every part of your life.</p>
          </div>
        </div>
        <div className="mt-8 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
          {CATEGORIES.map((cat) => (
            <a
              key={cat.name}
              href="/explore"
              className="group flex items-center gap-3 rounded-xl border border-border bg-card p-4 transition-all hover:border-primary/40 hover:shadow-sm"
            >
              <div
                className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg"
                style={{ backgroundColor: `color-mix(in oklch, ${cat.color} 18%, transparent)` }}
              >
                <DynamicIcon name={cat.icon} className="h-5 w-5" />
              </div>
              <span className="text-sm font-medium leading-tight">{cat.name}</span>
            </a>
          ))}
        </div>
      </section>

      {/* how it works */}

      <section className="mx-auto max-w-7xl px-4 py-20 sm:px-6 lg:px-8 border-y border-border">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-balance text-3xl font-semibold tracking-tight">How it works</h2>
          <p className="mt-3 text-muted-foreground">
            From browsing to recording in 3 simple steps
          </p>
        </div>
        <div className="mt-12 grid gap-8 md:grid-cols-3">
          {[
            {
              icon: Search,
              title: "Find a template",
              body: "Browse the website by category, tags, or popularity to find a timeline that fits how you want to track your life.",
            },
            {
              icon: Download,
              title: "Download the JSON",
              body: "Grab the template file with one click. Each template is a small, human-readable JSON file you can inspect.",
            },
            {
              icon: Disc2,
              title: "Import & record",
              body: "Open Digital Lifelines App, import the JSON, and your custom timeline is ready. Start recording instantly.",
            },
          ].map((step, i) => (
            <div key={step.title} className="relative rounded-2xl border border-border bg-card p-6">
              <span className="absolute right-5 top-5 font-serif text-4xl font-bold text-muted-foreground/30">
                {i + 1}
              </span>
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary/10 text-primary">
                <step.icon className="h-6 w-6" />
              </div>
              <h3 className="mt-5 text-lg font-semibold">{step.title}</h3>
              <p className="mt-2 text-pretty text-sm leading-relaxed text-muted-foreground">{step.body}</p>
            </div>
          ))}
        </div>
      </section>

        {/* featured */}

      <section className="bg-card/50">
        <div className="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
          <div className="flex items-end justify-between">
            <div>
              <h2 className="text-2xl font-semibold tracking-tight">Featured templates</h2>
              <p className="mt-1 text-muted-foreground">Hand-picked by the team.</p>
            </div>
            <Button asChild variant="outline" className="hidden sm:inline-flex">
              <a href="/explore">
                View all
                <ArrowRight className="h-4 w-4" />
              </a>
            </Button>
          </div>
          <div className="mt-8 grid gap-5 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {featured.map((template) => (
              <TemplateCard key={template.id} template={template} />
            ))}
          </div>
        </div>
      </section>

      {/* trending */}

      <section className="bg-card/50">
        <div className="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
          <div className="flex items-end justify-between">
            <div>
              <h2 className="text-2xl font-semibold tracking-tight">Trending templates</h2>
              <p className="mt-1 text-muted-foreground">What's popular right now within the community.</p>
            </div>
            <Button asChild variant="outline" className="hidden sm:inline-flex">
              <a href="/explore">
                View all
                <ArrowRight className="h-4 w-4" />
              </a>
            </Button>
          </div>
          <div className="mt-8 grid gap-5 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {trending.map((template) => (
              <TemplateCard key={template.id} template={template} />
            ))}
          </div>
        </div>
      </section>
      
      {/* CTA */}
      <section className="mx-auto max-w-7xl px-4 py-20 sm:px-6 lg:px-8 border-y border-border bg-background/50">
        <div className="overflow-hidden rounded-3xl bg-primary px-6 py-16 text-center text-primary-foreground sm:px-16">
          <Users className="mx-auto h-10 w-10 opacity-90" />
          <h2 className="mx-auto mt-6 max-w-2xl text-balance font-serif text-3xl font-bold sm:text-4xl">
            Built a timeline you love? Share it with the world.
          </h2>
          <p className="mx-auto mt-4 max-w-xl text-pretty leading-relaxed opacity-90">
            Become one of our lifeloggers sharing the templates that help them stay intentional. It only
            takes a second to upload.
          </p>
          <Button asChild size="lg" variant="secondary" className="mt-8">
            <a href="/upload">
              <Upload className="h-4 w-4" />
              Share a template
            </a>
          </Button>
        </div>
      </section>
        </>
    )
}