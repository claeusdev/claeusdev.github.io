---
layout: post
title: "Building a View Counter for Static Sites with Supabase and Astro"
description: "How I added a simple, privacy-friendly view counter to my static Astro blog using Supabase's free tier — no backend server required."
date: 2026-01-03
author: "Nana Adjei Manu"
category: "engineering"
tags: ["Astro", "Supabase", "Static Sites", "Tutorial"]
image: "/view-counter-supabase.webp"
---

![Building a View Counter with Supabase](/view-counter-supabase.webp)

Static sites can't count views. That's the whole point — they're static.

When you visit this page, you're downloading a pre-built HTML file from GitHub Pages. There's no server running Node.js or Python. There's no database. It's just HTML, CSS, and JavaScript sitting in a CDN, served instantly to anyone who asks.

But I wanted to know if anyone actually reads what I write. I wanted a simple number next to each post: **42 views**, **128 views**, whatever. A view counter.

The problem? Counters need to remember things. Static sites can't remember anything.

So how do you add dynamic behavior to something that's fundamentally static? That's the interesting challenge.

## The Challenge

Here's what happens when someone visits a blog post on a static site:

```
Browser requests /posts/some-article
    ↓
CDN/GitHub Pages serves static HTML
    ↓
Browser renders the page
    ↓
Done. No server involved.
```

Where would we store the view count? A few options I considered:

**Write to a JSON file?** Browsers can read files, but they can't write back to the server. No file access.

**LocalStorage/cookies?** These are client-side only. They track what _you've_ seen, not what _everyone's_ seen. If I store "42 views" in your browser, that number is meaningless — it's not the real count.

**Embed it at build time?** The site builds once and deploys. Until the next build, the count is frozen. Not useful.

**Use a third-party API?** Now we're talking. We need something that can:

- Accept requests from browsers
- Persist data across visits
- Increment a counter atomically (no race conditions)
- Ideally be free

This is where Supabase comes in.

## The Solution: Architecture Overview

Here's the flow I built:

```
User visits blog post
    ↓
Browser runs client-side JavaScript
    ↓
JavaScript calls Supabase REST API
    ↓
Supabase increments counter in PostgreSQL
    ↓
Returns new count to browser
    ↓
Browser displays: "42 views"
```

The key insight: **Supabase gives you a PostgreSQL database with a REST API**. You don't need to write backend code. You just call their API directly from the browser, and it handles the database operations.

### Why Supabase?

I looked at a few options:

| Option           | Pros                     | Cons                       |
| ---------------- | ------------------------ | -------------------------- |
| Google Analytics | Easy setup               | Overkill, privacy concerns |
| CountAPI         | Super simple             | Unreliable, sometimes down |
| Firebase         | Google-backed            | More complex than needed   |
| **Supabase**     | Free, simple, PostgreSQL | Have to set up a project   |

Supabase won because:

1. **Free tier is generous**: 500MB database, 50k monthly active users
2. **It's just PostgreSQL**: I can write real SQL, use transactions, create functions
3. **REST API out of the box**: No backend code needed
4. **Row-level security**: Proper access control built-in

## Building It: Three Parts

### Part 1: The Database Layer

First, I needed a table to track views. Simple enough:

```sql
CREATE TABLE page_views (
  id SERIAL PRIMARY KEY,
  slug TEXT UNIQUE NOT NULL,
  views INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

Each blog post has a unique `slug` (like `building-view-counter-supabase-astro`). When someone visits, we increment the `views` column for that slug.

But here's the problem: if we do a normal read-then-write, we have a race condition:

```
User A reads: views = 42
User B reads: views = 42
User A writes: views = 43
User B writes: views = 43  ← Should be 44!
```

We need an **atomic operation**, one that reads and increments in a single, uninterruptible step.

PostgreSQL has a solution: **functions**. I wrote a function that does an "upsert" (insert or update):

```sql
CREATE OR REPLACE FUNCTION increment_views(page_slug TEXT)
RETURNS INTEGER AS $$
DECLARE
  current_views INTEGER;
BEGIN
  INSERT INTO page_views (slug, views)
  VALUES (page_slug, 1)
  ON CONFLICT (slug)
  DO UPDATE SET views = page_views.views + 1, updated_at = NOW()
  RETURNING views INTO current_views;

  RETURN current_views;
END;
$$ LANGUAGE plpgsql;
```

What this does:

- If the slug doesn't exist → insert with `views = 1`
- If the slug exists → increment `views` by 1
- Either way → return the new count

This is atomic. No race conditions. The database handles concurrency for us.

### Part 2: The Client Component

Now I needed an Astro component that calls this function from the browser. Here's what I built:

```astro
---
// src/components/ViewCounter.astro
interface Props {
  slug: string;
}

const { slug } = Astro.props;
---

<span class="view-counter" data-slug={slug}>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    width="14"
    height="14"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="2"
  >
    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
    <circle cx="12" cy="12" r="3"></circle>
  </svg>
  <span class="view-count">—</span>
  <span class="view-label">views</span>
</span>

<script>
  const SUPABASE_URL = import.meta.env.PUBLIC_SUPABASE_URL;
  const SUPABASE_KEY = import.meta.env.PUBLIC_SUPABASE_ANON_KEY;

  document.querySelectorAll('.view-counter').forEach(async (counter) => {
    const slug = counter.getAttribute('data-slug');
    const countElement = counter.querySelector('.view-count');

    // Only count once per session
    const sessionKey = `viewed_${slug}`;
    let views = 0;

    if (!sessionStorage.getItem(sessionKey)) {
      // First visit this session — increment
      const response = await fetch(
        `${SUPABASE_URL}/rest/v1/rpc/increment_views`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_KEY,
            'Authorization': `Bearer ${SUPABASE_KEY}`,
          },
          body: JSON.stringify({ page_slug: slug }),
        }
      );
      views = await response.json();
      sessionStorage.setItem(sessionKey, 'true');
    } else {
      // Already counted this session — just fetch
      const response = await fetch(
        `${SUPABASE_URL}/rest/v1/page_views?slug=eq.${slug}&select=views`,
        {
          headers: {
            'apikey': SUPABASE_KEY,
            'Authorization': `Bearer ${SUPABASE_KEY}`,
          },
        }
      );
      const data = await response.json();
      views = data[0]?.views || 0;
    }

    if (views > 0) {
      countElement.textContent = views.toLocaleString();
    }
  });
</script>
```

A few things worth noting:

**Session storage prevents inflation.** I use `sessionStorage` to track whether you've already viewed this post in the current browser session. If you have, we just fetch the count without incrementing. This prevents you from inflating the number by refreshing the page repeatedly.

**Client-side execution.** This entire script runs in the browser. Astro builds the HTML with `<span class="view-count">—</span>`, and then JavaScript fills in the real number after the page loads. This means:

- The page loads fast (no waiting for database)
- It works with static site generation
- If Supabase is down, you just see "—" instead of breaking

**Direct API calls.** Notice we're calling Supabase directly from the browser. The `/rest/v1/rpc/increment_views` endpoint executes our PostgreSQL function. The `/rest/v1/page_views?slug=eq.${slug}` endpoint queries the table. No backend server required.

### Part 3: Making It Production-Ready

For this to work in production, I needed three things:

#### 1. Environment Variables

In local development, I created a `.env` file:

```bash
PUBLIC_SUPABASE_URL=https://your-project.supabase.co
PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

The `PUBLIC_` prefix in Astro exposes these to client-side code. This is fine — the "anon key" is meant to be public. It's like an API key that anyone can see, but row-level security (next step) controls what it can do.

#### 2. GitHub Actions Deployment

Since I deploy via GitHub Actions, I added the environment variables to the build step:

```yaml
- name: Build with Astro
  run: npm run build
  env:
    PUBLIC_SUPABASE_URL: ${{ secrets.PUBLIC_SUPABASE_URL }}
    PUBLIC_SUPABASE_ANON_KEY: ${{ secrets.PUBLIC_SUPABASE_ANON_KEY }}
```

Then I added the secrets in GitHub: **Settings → Secrets and variables → Actions → New repository secret**.

#### 3. Row-Level Security (Critical!)

By default, Supabase tables are completely locked down. The anon key can't do anything. We need to explicitly allow:

- Reading view counts
- Incrementing view counts

Here's the security policy I created:

```sql
-- Enable row-level security on the table
ALTER TABLE page_views ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read view counts
CREATE POLICY "Allow public read access"
  ON page_views
  FOR SELECT
  USING (true);

-- Allow anyone to insert new rows (for new slugs)
CREATE POLICY "Allow public insert"
  ON page_views
  FOR INSERT
  WITH CHECK (true);

-- Allow anyone to update existing rows (for incrementing)
CREATE POLICY "Allow public update"
  ON page_views
  FOR UPDATE
  USING (true);
```

This says: "Anyone with the anon key can read, insert, and update the `page_views` table." That sounds permissive, but remember:

- The only operation exposed is `increment_views()`
- We're not exposing user data — just public view counts
- There's no way to decrement or delete counts (we didn't create those policies)

If I were tracking private data, I'd lock this down further. But for a public view counter? This is fine.

## The Result

Now every blog post shows a live view count. In my post template (`[slug].astro`), I added:

```astro
<p class="post-meta">
  <span>By {author}</span>
  <span> · </span>
  <time datetime={post.data.date.toISOString()}>
    {formatDate(post.data.date)}
  </time>
  <span> · </span>
  <span>{readingTime} min read</span>
  <span> · </span>
  <ViewCounter slug={post.slug} />
</p>
```

And it renders like this:

> By Nana Adjei Manu · January 3, 2026 · 5 min read · 👁 **42 views**

It's simple, privacy-friendly (no cookies, no third-party tracking), and completely free on Supabase's tier.

More importantly, I now have data. I can see which posts resonate, which don't, and whether the effort I put into writing is actually reaching people. That's the goal: **measure everything**.

## Reflections: What I'd Do Differently

If I were building this again, here's what I'd change:

1. **Add a loading state**: Right now it shows `—` until the count loads. A subtle skeleton loader would be better UX.

2. **Cache on the edge**: Use Supabase Edge Functions to cache counts at the CDN level for lower latency. Right now every page view hits the database.

3. **Add unique visitor tracking**: This counts sessions, not unique people. I could fingerprint browsers, but that gets into privacy concerns. Maybe a hash of IP + User-Agent? Still feels invasive.

4. **Debounce the increment** — If someone navigates away quickly (< 5 seconds), should that count as a view? Probably not. A small delay would filter out accidental clicks.

But honestly? For a simple blog, this is enough. It does exactly what I need, costs nothing, and took about an hour to build.

---

The full code is in [this blog's repository](https://github.com/naamanu/claeusdev.github.io). Feel free to steal it.
