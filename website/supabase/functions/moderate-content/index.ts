// Supabase Edge Function: moderate-content
//
// Deploy with:
//   supabase functions deploy moderate-content
//   supabase secrets set OPENAI_API_KEY=sk-...
//
// Called by the client before any insert/update that includes
// user-authored text (template name, tagline, description, tags,
// field names, bio). Never trust the client alone — this function
// is the actual enforcement point.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface ModerationRequest {
  // Accepts either a single string or a labeled record of fields,
  // so the client can send everything in one call and get back
  // which specific field(s) tripped the filter.
  fields: Record<string, string>;
}

interface FieldResult {
  flagged: boolean;
  categories: string[];
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (!OPENAI_API_KEY) {
    return new Response(
      JSON.stringify({ error: "Moderation service not configured." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  try {
    const { fields }: ModerationRequest = await req.json();

    const entries = Object.entries(fields).filter(([, value]) => value && value.trim().length > 0);

    if (entries.length === 0) {
      return new Response(JSON.stringify({ flagged: false, results: {} }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const openaiRes = await fetch("https://api.openai.com/v1/moderations", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "omni-moderation-latest",
        input: entries.map(([, value]) => value),
      }),
    });

    if (!openaiRes.ok) {
      const errText = await openaiRes.text();
      console.error("OpenAI moderation error:", errText);
      return new Response(
        JSON.stringify({ error: "Moderation check failed. Please try again." }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const openaiData = await openaiRes.json();
    const results: Record<string, FieldResult> = {};
    let anyFlagged = false;

    entries.forEach(([fieldName], i) => {
      const result = openaiData.results[i];
      const flaggedCategories = Object.entries(result.categories)
        .filter(([, isFlagged]) => isFlagged)
        .map(([category]) => category);

      results[fieldName] = { flagged: result.flagged, categories: flaggedCategories };
      if (result.flagged) anyFlagged = true;
    });

    return new Response(JSON.stringify({ flagged: anyFlagged, results }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("moderate-content error:", err);
    return new Response(JSON.stringify({ error: "Unexpected error during moderation." }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});