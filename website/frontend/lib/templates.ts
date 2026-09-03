export type FieldType =
  | "text"
  | "integer"
  | "double"
  | "boolean"
  | "date"
  | "select"
  | "photo"

export interface TemplateField {
  name: string
  type: FieldType
  unit?: string
  options?: string[]
}

export interface TeamTemplate {
  id: string
  name: string
  tagline: string
  description: string
  category: Category
  tags: string[]
  author: {
    name: string
    handle: string
    avatarColor: string
  }
  downloads: number
  likes: number
  fields: TemplateField[]
  featured?: boolean
  updatedAt: string
  version: string
}

export type Category =
  | "Health & Fitness"
  | "Entertainment"
  | "Family & Kids"
  | "Travel"
  | "Personal Growth"
  // | "Finance"
  | "Food & Drink"
  | "Hobbies"

export const CATEGORIES: {
  name: Category
  icon: string
  color: string
  subtleColor: string
  mutedColor: string
}[] = [
  {
    name: "Health & Fitness",
    icon: "Activity",
    color: "var(--chart-1)",
    subtleColor: "var(--chart-1-subtle)",
    mutedColor: "var(--chart-1-muted)",
  },
  {
    name: "Entertainment",
    icon: "Clapperboard",
    color: "var(--chart-2)",
    subtleColor: "var(--chart-2-subtle)",
    mutedColor: "var(--chart-2-muted)",
  },
  {
    name: "Family & Kids",
    icon: "Baby",
    color: "var(--chart-3)",
    subtleColor: "var(--chart-3-subtle)",
    mutedColor: "var(--chart-3-muted)",
  },
  {
    name: "Travel",
    icon: "Plane",
    color: "var(--chart-4)",
    subtleColor: "var(--chart-4-subtle)",
    mutedColor: "var(--chart-4-muted)",
  },
  {
    name: "Personal Growth",
    icon: "Sprout",
    color: "var(--chart-5)",
    subtleColor: "var(--chart-5-subtle)",
    mutedColor: "var(--chart-5-muted)",
  },
  // {
  //   name: "Finance",
  //   icon: "Wallet",
  //   color: "var(--chart-6)",
  //   subtleColor: "var(--chart-6-subtle)",
  //   mutedColor: "var(--chart-6-muted)",
  // },
  {
    name: "Food & Drink",
    icon: "UtensilsCrossed",
    color: "var(--chart-7)",
    subtleColor: "var(--chart-7-subtle)",
    mutedColor: "var(--chart-7-muted)",
  },
  {
    name: "Hobbies",
    icon: "Palette",
    color: "var(--chart-8)",
    subtleColor: "var(--chart-8-subtle)",
    mutedColor: "var(--chart-8-muted)",
  },
]

export function getCategoryMeta(category: Category) {
  return CATEGORIES.find((c) => c.name === category)!
}

export const TEMPLATES: TeamTemplate[] = [
  {
    id: "blood-pressure-tracker",
    name: "Blood Pressure Tracker",
    tagline: "Log readings morning and night",
    description:
      "A clinical-grade timeline for tracking your blood pressure over time. Captures systolic, diastolic, pulse, and an optional note for context. Perfect for sharing trends with your doctor.",
    category: "Health & Fitness",
    tags: ["health", "medical", "daily", "vitals"],
    author: { name: "Dr. Maya Chen", handle: "mayachen", avatarColor: "var(--chart-2)" },
    downloads: 4821,
    likes: 932,
    featured: true,
    updatedAt: "2026-05-28",
    version: "2.1.0",
    fields: [
      { name: "Systolic", type: "integer", unit: "mmHg" },
      { name: "Diastolic", type: "integer", unit: "mmHg" },
      { name: "Pulse", type: "integer", unit: "bpm" },
      { name: "Time of Day", type: "select", options: ["Morning", "Afternoon", "Evening", "Night"] },
      { name: "Note", type: "text" },
    ],
  },
  {
    id: "movie-night",
    name: "Movie Night Log",
    tagline: "Every film, rated and remembered",
    description:
      "Keep a beautiful record of every movie you watch. Rate it, note who you watched with, and capture a one-line review. Includes a poster photo field.",
    category: "Entertainment",
    tags: ["movies", "reviews", "rating", "fun"],
    author: { name: "Leo Park", handle: "leowatches", avatarColor: "var(--chart-3)" },
    downloads: 7204,
    likes: 1503,
    featured: true,
    updatedAt: "2026-06-02",
    version: "3.0.1",
    fields: [
      { name: "Title", type: "text" },
      { name: "Rating", type: "select", options: ["1", "2", "3", "4", "5"] },
      { name: "Watched With", type: "text" },
      { name: "Genre", type: "select", options: ["Action", "Drama", "Comedy", "Horror", "Sci-Fi", "Documentary"] },
      { name: "Review", type: "text" },
      { name: "Poster", type: "photo" },
    ],
  },
  {
    id: "baby-firsts",
    name: "Baby's Firsts",
    tagline: "Capture every precious milestone",
    description:
      "Never forget a single milestone. From first smile to first steps, record the moments that matter with date, a note, and a photo. A keepsake you'll treasure forever.",
    category: "Family & Kids",
    tags: ["baby", "milestones", "family", "memories"],
    author: { name: "Sofia Reyes", handle: "sofiamom", avatarColor: "var(--chart-4)" },
    downloads: 9870,
    likes: 2841,
    featured: true,
    updatedAt: "2026-06-10",
    version: "1.4.0",
    fields: [
      { name: "Milestone", type: "text" },
      { name: "Age", type: "text" },
      { name: "Location", type: "text" },
      { name: "Note", type: "text" },
      { name: "Photo", type: "photo" },
    ],
  },
  {
    id: "travel-journal",
    name: "Travel Journal",
    tagline: "Document every adventure",
    description:
      "A rich travel timeline to log every trip. Record destination, dates, companions, highlights, and a rating. Includes a cover photo to remember the view.",
    category: "Travel",
    tags: ["travel", "adventure", "places", "memories"],
    author: { name: "Kai Nakamura", handle: "kaiwanders", avatarColor: "var(--chart-1)" },
    downloads: 5612,
    likes: 1209,
    updatedAt: "2026-05-19",
    version: "2.3.0",
    fields: [
      { name: "Destination", type: "text" },
      { name: "Country", type: "text" },
      { name: "Companions", type: "text" },
      { name: "Highlight", type: "text" },
      { name: "Rating", type: "select", options: ["1", "2", "3", "4", "5"] },
      { name: "Cover Photo", type: "photo" },
    ],
  },
  {
    id: "reading-list",
    name: "Reading List",
    tagline: "Track every book you finish",
    description:
      "For the avid reader. Log title, author, pages, your rating, and favorite quotes. Watch your reading habit grow over the year.",
    category: "Personal Growth",
    tags: ["books", "reading", "learning"],
    author: { name: "Amara Okafor", handle: "amarareads", avatarColor: "var(--chart-2)" },
    downloads: 6340,
    likes: 1788,
    updatedAt: "2026-06-05",
    version: "1.9.2",
    fields: [
      { name: "Title", type: "text" },
      { name: "Author", type: "text" },
      { name: "Pages", type: "integer", unit: "pages" },
      { name: "Rating", type: "select", options: ["1", "2", "3", "4", "5"] },
      { name: "Favorite Quote", type: "text" },
      { name: "Finished", type: "boolean" },
    ],
  },
  {
    id: "daily-mood",
    name: "Daily Mood",
    tagline: "Understand your emotional patterns",
    description:
      "A gentle daily check-in. Rate your mood, energy, and sleep, then jot down what influenced your day. Spot patterns over weeks and months.",
    category: "Personal Growth",
    tags: ["mood", "mental health", "daily", "wellness"],
    author: { name: "Jordan Bell", handle: "jbwellness", avatarColor: "var(--chart-4)" },
    downloads: 8120,
    likes: 2210,
    featured: true,
    updatedAt: "2026-06-12",
    version: "2.0.0",
    fields: [
      { name: "Mood", type: "select", options: ["Great", "Good", "Okay", "Low", "Rough"] },
      { name: "Energy", type: "integer", unit: "/10" },
      { name: "Sleep", type: "double", unit: "hrs" },
      { name: "What influenced today", type: "text" },
    ],
  },
  {
    id: "workout-log",
    name: "Workout Log",
    tagline: "Every rep, every run, recorded",
    description:
      "Track your training sessions with exercise type, duration, intensity, and how you felt. Built for consistency and progress.",
    category: "Health & Fitness",
    tags: ["fitness", "gym", "running", "strength"],
    author: { name: "Marcus Lee", handle: "marcusfit", avatarColor: "var(--chart-2)" },
    downloads: 7890,
    likes: 1654,
    updatedAt: "2026-06-08",
    version: "3.1.0",
    fields: [
      { name: "Exercise", type: "select", options: ["Run", "Strength", "Cycling", "Swim", "Yoga", "Other"] },
      { name: "Duration", type: "integer", unit: "min" },
      { name: "Intensity", type: "select", options: ["Light", "Moderate", "Hard", "Max"] },
      { name: "Calories", type: "integer", unit: "kcal" },
      { name: "How I felt", type: "text" },
    ],
  },
  {
    id: "coffee-diary",
    name: "Coffee Diary",
    tagline: "For the discerning caffeine lover",
    description:
      "Log every brew. Record the roaster, origin, brew method, and tasting notes. Rate each cup and find your perfect roast.",
    category: "Food & Drink",
    tags: ["coffee", "tasting", "hobby"],
    author: { name: "Nina Brewer", handle: "ninabrews", avatarColor: "var(--chart-3)" },
    downloads: 3210,
    likes: 876,
    updatedAt: "2026-05-30",
    version: "1.2.0",
    fields: [
      { name: "Roaster", type: "text" },
      { name: "Origin", type: "text" },
      { name: "Brew Method", type: "select", options: ["Espresso", "Pour Over", "French Press", "Aeropress", "Cold Brew"] },
      { name: "Tasting Notes", type: "text" },
      { name: "Rating", type: "select", options: ["1", "2", "3", "4", "5"] },
    ],
  },
  // {
  //   id: "savings-goals",
  //   name: "Savings Tracker",
  //   tagline: "Watch your goals grow",
  //   description:
  //     "Stay on top of your finances. Log deposits toward a goal, track the running balance, and note your motivation each time.",
  //   category: "Finance",
  //   tags: ["money", "savings", "goals"],
  //   color: "var(--chart-5)",
  //   icon: "Wallet",
  //   author: { name: "Priya Shah", handle: "priyasaves", avatarColor: "var(--chart-5)" },
  //   downloads: 2980,
  //   likes: 654,
  //   updatedAt: "2026-05-22",
  //   version: "1.0.3",
  //   fields: [
  //     { name: "Goal", type: "text" },
  //     { name: "Amount", type: "double", unit: "$" },
  //     { name: "Running Balance", type: "double", unit: "$" },
  //     { name: "Note", type: "text" },
  //   ],
  // },
  {
    id: "garden-log",
    name: "Garden Log",
    tagline: "Grow with the seasons",
    description:
      "Track your plants from seed to harvest. Record what you planted, watering, growth notes, and photos as your garden flourishes.",
    category: "Hobbies",
    tags: ["gardening", "plants", "seasons"],
    author: { name: "Tom Garcia", handle: "tomgrows", avatarColor: "var(--chart-2)" },
    downloads: 1840,
    likes: 521,
    updatedAt: "2026-05-15",
    version: "1.1.0",
    fields: [
      { name: "Plant", type: "text" },
      { name: "Action", type: "select", options: ["Planted", "Watered", "Fertilized", "Harvested", "Pruned"] },
      { name: "Notes", type: "text" },
      { name: "Photo", type: "photo" },
    ],
  },
]

export function getTemplate(id: string) {
  return TEMPLATES.find((t) => t.id === id)
}

export function getFeatured() {
  return TEMPLATES.filter((t) => t.featured)
}

export function buildTemplateJson(t: TeamTemplate) {
  return {
    name: t.name,
    version: t.version,
    category: t.category,
    tags: t.tags,
    author: t.author.handle,
    fields: t.fields.map((f) => ({
      name: f.name,
      type: f.type,
      ...(f.unit ? { unit: f.unit } : {}),
      ...(f.options ? { options: f.options } : {}),
    })),
  }
}

export const CURRENT_USER = {
  name: "Esuyawkal Bereda",
  handle: "esuyawkal",
  bio: "Lifelogging enthusiast. Building timelines for a more intentional life.",
  avatarColor: "var(--chart-1)",
  joinedAt: "2025-11-02",
  uploads: ["movie-night", "coffee-diary"],
  downloaded: ["blood-pressure-tracker", "baby-firsts", "reading-list"],
  liked: ["daily-mood", "travel-journal"],
}