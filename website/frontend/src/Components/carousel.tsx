"use client"

import { useState, useEffect } from "react"
import { Button } from "./buttons"
import { Search, Upload, ChevronLeft, ChevronRight } from "lucide-react"
import { TEMPLATES, CATEGORIES } from "../../lib/templates"

interface CarouselSlide {
  id: number
  type: "content" | "image" | "video"
  src?: string
  alt?: string
}

const CAROUSEL_SLIDES: CarouselSlide[] = [
  {
    id: 1,
    type: "content"
  },
  {
    id: 2,
    type: "image",
    src: "",
    alt: "Timeline creation interface"
  },
  {
    id: 3,
    type: "image",
    src: "",
    alt: "Template sharing"
  },
  {
    id: 4,
    type: "image",
    src: "",
    alt: "Template gallery"
  }
]

export default function Carousel() {
  const [currentSlide, setCurrentSlide] = useState(0)
  const [isHovering, setIsHovering] = useState(false)
  const [autoPlay, setAutoPlay] = useState(false)
  const [slideDirection, setSlideDirection] = useState<"left" | "right">("right")

  const totalDownloads = TEMPLATES.reduce((sum, t) => sum + t.downloads, 0)
//   const slide = CAROUSEL_SLIDES[currentSlide]

  const nextSlide = () => {
    setSlideDirection("right")
    setCurrentSlide((prev) => (prev + 1) % CAROUSEL_SLIDES.length)
    setAutoPlay(false)
  }

  const prevSlide = () => {
    setSlideDirection("left")
    setCurrentSlide((prev) => (prev - 1 + CAROUSEL_SLIDES.length) % CAROUSEL_SLIDES.length)
    setAutoPlay(false)
  }

  // Auto-play carousel
  useEffect(() => {
    if (!autoPlay) return
    const interval = setInterval(() => {
      setCurrentSlide((prev) => (prev + 1) % CAROUSEL_SLIDES.length)
    }, 5000)
    return () => clearInterval(interval)
  }, [autoPlay])

  return (
    <section className="relative overflow-hidden border-y border-border">
      <div 
        className="relative"
        onMouseEnter={() => setIsHovering(true)}
        onMouseLeave={() => setIsHovering(false)}
      >
        {/* Carousel Slides */}
        <div className="relative w-full overflow-hidden">
          {CAROUSEL_SLIDES.map((s, index) => (
            <div
              key={s.id}
              className={`transition-all duration-700 ease-in-out ${
                index === currentSlide 
                  ? "opacity-100 translate-x-0" 
                  : slideDirection === "right"
                  ? "opacity-0 translate-x-full absolute inset-0"
                  : "opacity-0 -translate-x-full absolute inset-0"
              }`}
            >
              {s.type === "content" && (
                <div className="mx-auto max-w-7xl px-4 py-20 sm:px-6 lg:px-8 lg:py-28">
                  <div className="mx-auto max-w-3xl text-center">
                    <h1 className="mt-6 text-balance font-serif text-5xl font-bold leading-[1.05] tracking-tight sm:text-6xl lg:text-7xl">
                      Digital Lifelines  
                    </h1>
                    <p className="mx-auto mt-6 max-w-2xl text-pretty text-lg leading-relaxed text-muted-foreground">
                      Discover and share custom timeline templates for Digital Lifelines. Download a ready-made
                      JSON, import it into the app, and start recording your moments.
                    </p>
                    <div className="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
                      <Button asChild size="lg">
                        <a href="/explore">
                          <Search className="h-4 w-4" />
                          Explore templates
                        </a>
                      </Button>
                      <Button asChild size="lg" variant="outline">
                        <a href="/upload">
                          <Upload className="h-4 w-4" />
                          Share your own
                        </a>
                      </Button>
                    </div>
                    <dl className="mx-auto mt-14 grid max-w-lg grid-cols-3 gap-6">
                      <div>
                        <dt className="text-sm text-muted-foreground">Templates</dt>
                        <dd className="mt-1 text-2xl font-semibold">{TEMPLATES.length}+</dd>
                      </div>
                      <div>
                        <dt className="text-sm text-muted-foreground">Downloads</dt>
                        <dd className="mt-1 text-2xl font-semibold">{Math.round(totalDownloads / 1000)}k+</dd>
                      </div>
                      <div>
                        <dt className="text-sm text-muted-foreground">Categories</dt>
                        <dd className="mt-1 text-2xl font-semibold">{CATEGORIES.length}</dd>
                      </div>
                    </dl>
                  </div>
                </div>
              )}

              {s.type === "image" && (
                <div className="w-full h-auto bg-muted flex items-center justify-center overflow-hidden">
                  <img
                    src={s.src}
                    alt={s.alt}
                    className="w-full h-fill object-contain"
                  />
                </div>
              )}

              {s.type === "video" && (
                <div className="w-full h-auto bg-muted flex items-center justify-center overflow-hidden">
                  <video
                    src={s.src}
                    className="w-full h-fill object-contain"
                    autoPlay
                    loop
                    muted
                  />
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Navigation Buttons - Appear on Hover */}
        <button
            onClick={prevSlide}
            className={`absolute left-0 top-1/2 -translate-y-1/2 z-10
                flex h-24 w-24 items-center justify-center
                bg-linear-to-r from-gray-500/50 via-gray-400/20 to-transparent
                text-white transition-all duration-300
                hover:from-gray-500/70 hover:via-gray-400/30
                ${isHovering ? "opacity-100" : "opacity-0"}`}
            aria-label="Previous slide"
            >
            <ChevronLeft className="h-8 w-8" />
        </button>

        <button
            onClick={nextSlide}
            className={`absolute right-0 top-1/2 -translate-y-1/2 z-10
                flex h-24 w-24 items-center justify-center
                bg-linear-to-l from-gray-500/50 via-gray-400/20 to-transparent
                text-white transition-all duration-300
                hover:from-gray-500/70 hover:via-gray-400/30
                ${isHovering ? "opacity-100" : "opacity-0"}`}
            aria-label="Previous slide"
            >
            <ChevronRight className="h-8 w-8" />
        </button>

        {/* Slide Indicators */}
        <div className="absolute bottom-4 left-1/2 -translate-x-1/2 z-10 flex gap-2">
          {CAROUSEL_SLIDES.map((_, index) => (
            <button
              key={index}
              onClick={() => {
                setCurrentSlide(index)
                setAutoPlay(false)
              }}
              className={`h-2 rounded-full transition-all ${
                index === currentSlide
                  ? "w-8 bg-white"
                  : "w-2 bg-white/50 hover:bg-white/75"
              }`}
              aria-label={`Go to slide ${index + 1}`}
            />
          ))}
        </div>
      </div>
    </section>
  )
}