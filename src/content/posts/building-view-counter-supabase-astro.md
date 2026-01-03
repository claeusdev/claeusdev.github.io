---
title: "Building a View Counter for Static Sites with Supabase and Astro"
description: "How I added a simple, privacy-friendly view counter to my static Astro blog using Supabase's free tier — no backend server required."
date: 2026-01-03
author: "Nana Adjei Manu"
categories: "engineering"
image: "/view-counter-supabase.png"
tags: ["Astro", "Supabase", "Static Sites", "Tutorial"]
---

![Building a View Counter with Supabase](/view-counter-supabase.png)

I recently rebuilt this website from scratch. The old version was a Jekyll template I'd been using for years — functional, but not really _mine_. The new one is a custom Astro build, designed exactly how I want it.

One of my goals for this new year is simple: **measure everything**. I want to understand how every effort I put into something yields results. If I'm going to spend hours writing a blog post, I want to know if anyone actually reads it. If I'm going to build a side project, I want to see if it resonates.

So the first feature I added to the new site? A view counter.

Nothing fancy — just a number next to each post showing how many people have read it. But there's a problem: this is a static site. There's no server. When you visit this page, you're just downloading pre-built HTML files from GitHub Pages. There's nowhere to store a count.

## The Problem with Static Sites

When someone visits a blog post, here's what happens:

```
Browser requests page
    ↓
GitHub Pages serves static HTML
    ↓
???
```

Where do we store the view count? We can't write to a JSON file — the browser can _read_ files but can't _write_ to them. We need somewhere to persist data.

## Why Supabase?

I considered a few options:

| Option           | Pros                     | Cons                       |
| ---------------- | ------------------------ | -------------------------- |
| Google Analytics | Easy setup               | Overkill, privacy concerns |
| CountAPI         | Super simple             | Unreliable, sometimes down |
| Firebase         | Google-backed            | More complex than needed   |
| **Supabase**     | Free, simple, PostgreSQL | Have to set up a project   |

I went with Supabase because:

1. **Free tier is generous** — 500MB database, 50k monthly active users
2. **It's just PostgreSQL** — I can write real SQL
3. **REST API out of the box** — No backend code needed
4. **Row-level security** — I can lock down access properly

## The Database Schema

First, I created a simple table to track views:

```sql
CREATE TABLE page_views (
  id SERIAL PRIMARY KEY,
  slug TEXT UNIQUE NOT NULL,
  views INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

Each blog post has a `slug` (like `building-view-counter-supabase-astro`). When someone visits, we increment the `views` column.

### The Increment Function

Instead of doing a read-then-write (which has race conditions), I created a PostgreSQL function that atomically increments and returns the new count:

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

This is an **upsert** — if the slug doesn't exist, it inserts with views = 1. If it does exist, it increments. Either way, it returns the new count.

## The Astro Component

Here's the view counter component I built:

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

A few things to note:

1. **Session storage prevents inflation** — We only count once per browser session. Refreshing the page doesn't increment.
2. **Client-side execution** — This runs in the browser, so we don't need SSR.
3. **Graceful degradation** — If Supabase is down, the counter just shows `—`.

## Using the Component

In my blog post template (`[slug].astro`), I added the counter to the post meta:

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

## Environment Variables

For local development, I created a `.env` file:

```bash
PUBLIC_SUPABASE_URL=https://your-project.supabase.co
PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

The `PUBLIC_` prefix in Astro exposes these to client-side code (which is fine — the anon key is meant to be public).

## GitHub Actions Deployment

For production, I added the secrets to my GitHub Actions workflow:

```yaml
- name: Build with Astro
  run: npm run build
  env:
    PUBLIC_SUPABASE_URL: ${{ secrets.PUBLIC_SUPABASE_URL }}
    PUBLIC_SUPABASE_ANON_KEY: ${{ secrets.PUBLIC_SUPABASE_ANON_KEY }}
```

Then I added the secrets in GitHub: **Settings → Secrets and variables → Actions → New repository secret**.

## Row-Level Security (Important!)

By default, Supabase tables are private. We need to allow the anon key to:

1. Read the `page_views` table
2. Execute the `increment_views` function

In the Supabase SQL Editor:

```sql
-- Enable RLS on the table
ALTER TABLE page_views ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read view counts
CREATE POLICY "Allow public read access"
  ON page_views
  FOR SELECT
  USING (true);

-- Allow the function to insert/update
-- (Functions run with invoker rights, so we need this)
CREATE POLICY "Allow public insert"
  ON page_views
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Allow public update"
  ON page_views
  FOR UPDATE
  USING (true);
```

## The Result

Now every blog post shows a view count:

> By Nana Adjei Manu · January 3, 2026 · 5 min read · 👁 **42 views**

It's simple, privacy-friendly (no cookies, no tracking), and completely free.

## What I'd Do Differently

If I were building this again:

1. **Add a loading state** — Right now it shows `—` until the count loads
2. **Cache on the edge** — Use Supabase Edge Functions for lower latency
3. **Add unique visitor tracking** — Maybe fingerprint-based, but that gets into privacy weirdness

But for a simple blog? This is enough.

---

The full code is in [this blog's repository](https://github.com/naamanu/claeusdev.github.io). Feel free to steal it.
