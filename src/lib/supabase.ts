// Supabase client for view counting
// Replace these with your actual Supabase credentials

const SUPABASE_URL = import.meta.env.PUBLIC_SUPABASE_URL || "";
const SUPABASE_ANON_KEY = import.meta.env.PUBLIC_SUPABASE_ANON_KEY || "";

interface ViewResponse {
  views: number;
  error?: string;
}

/**
 * Increment the view count for a given slug and return the new count
 */
export async function incrementViews(slug: string): Promise<ViewResponse> {
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    console.warn("Supabase credentials not configured");
    return { views: 0, error: "Not configured" };
  }

  try {
    const response = await fetch(
      `${SUPABASE_URL}/rest/v1/rpc/increment_views`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          apikey: SUPABASE_ANON_KEY,
          Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        },
        body: JSON.stringify({ page_slug: slug }),
      }
    );

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const views = await response.json();
    return { views: typeof views === "number" ? views : 0 };
  } catch (error) {
    console.error("Error incrementing views:", error);
    return { views: 0, error: String(error) };
  }
}

/**
 * Get the current view count for a given slug without incrementing
 */
export async function getViews(slug: string): Promise<ViewResponse> {
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    return { views: 0, error: "Not configured" };
  }

  try {
    const response = await fetch(
      `${SUPABASE_URL}/rest/v1/page_views?slug=eq.${encodeURIComponent(slug)}&select=views`,
      {
        headers: {
          apikey: SUPABASE_ANON_KEY,
          Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        },
      }
    );

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();
    return { views: data[0]?.views || 0 };
  } catch (error) {
    console.error("Error getting views:", error);
    return { views: 0, error: String(error) };
  }
}
