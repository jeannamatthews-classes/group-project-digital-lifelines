import { supabase } from "./supabase"

export interface ModerationResult {
  flagged: boolean
  results: Record<string, { flagged: boolean; categories: string[] }>
}

/**
 * Local profanity filter.
 * OpenAI moderation handles context (harassment, threats, hate, etc.),
 * while this catches explicit profanity.
 */
const bannedWords = [
  // Common profanity
  "fuck",
  "fucks",
  "fucked",
  "fucking",
  "fucker",
  "fuckers",

  "shit",
  "shits",
  "shitty",

  "bitch",
  "bitches",
  "bitchy",

  "asshole",
  "assholes",

  "dick",
  "dicks",

  "cock",
  "cocks",

  "pussy",

  "cunt",

  "bastard",
  "bastards",

  "slut",
  "sluts",

  "whore",
  "whores",

  "douche",
  "douchebag",

  "jackass",

  "crap",

  "damn",
  "dammit",

  "hell",

  // Common insults
  "idiot",
  "moron",
  "stupid",
  "dumbass",

]


function normalizeText(text: string): string {
  return text
    .toLowerCase()
    .replace(/[@4]/g, "a")
    .replace(/3/g, "e")
    .replace(/[1!]/g, "i")
    .replace(/0/g, "o")
    .replace(/\$/g, "s")
    .replace(/\*/g, "")
    .replace(/[^a-z\s]/g, " ")
}


function containsProfanity(text: string): boolean {
  const normalized = normalizeText(text)

  return bannedWords.some((word) => {
    const regex = new RegExp(`\\b${word}\\b`, "i")
    return regex.test(normalized)
  })
}


/**
 * Sends fields to OpenAI moderation after local profanity check.
 */
export async function moderateFields(
  fields: Record<string, string>
): Promise<ModerationResult> {

  const localResults: Record<
    string,
    { flagged: boolean; categories: string[] }
  > = {}

  let locallyFlagged = false


  // First run local profanity filter
  for (const [fieldName, value] of Object.entries(fields)) {

    if (!value || value.trim().length === 0) {
      continue
    }

    if (containsProfanity(value)) {
      localResults[fieldName] = {
        flagged: true,
        categories: ["profanity"],
      }

      locallyFlagged = true
    }
  }


  // If profanity is found, block immediately
  if (locallyFlagged) {
    return {
      flagged: true,
      results: localResults,
    }
  }


  // Otherwise use OpenAI moderation
  const { data, error } =
    await supabase.functions.invoke("moderate-content", {
      body: { fields },
    })


  if (error) {
    console.error("Moderation function error:", error)

    throw new Error(
      "Unable to verify content right now. Please try again."
    )
  }


  if (data?.error) {
    throw new Error(data.error)
  }


  return data as ModerationResult
}


/**
 * Builds a friendly message naming flagged fields.
 */
export function describeFlaggedFields(
  result: ModerationResult
): string {

  const flaggedFieldNames = Object.entries(result.results)
    .filter(([, r]) => r.flagged)
    .map(([name]) => name)


  if (flaggedFieldNames.length === 0) {
    return "Content violates community guidelines."
  }


  return `Please revise: ${flaggedFieldNames.join(", ")}`
}