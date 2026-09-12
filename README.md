# nanamanu.com

My personal website, built with [Jekyll](https://jekyllrb.com) and
[Tailwind CSS](https://tailwindcss.com).

## Local development

Requires Ruby 3.x and Node 20+.

```sh
bundle install
npm install

npm run build:css      # compile Tailwind -> assets/css/main.css
bundle exec jekyll serve --livereload
```

Then open <http://127.0.0.1:4000>.

While iterating on styles, run `npm run watch:css` in a second terminal —
Tailwind scans the templates, so new utility classes only appear in the
compiled CSS after a rebuild.

## Layout

| Path | Purpose |
| --- | --- |
| `_posts/` | Blog posts, `YYYY-MM-DD-slug.md` |
| `_layouts/` | `default`, `home`, `page`, `post`, `tag` |
| `_includes/` | `head`, `header`, `footer`, `post-list-item` |
| `_data/` | `nav`, `projects`, `experience`, `research` — content for the non-blog pages |
| `assets/css/tailwind.css` | Tailwind source |
| `assets/css/main.css` | Compiled output (committed) |
| `assets/css/syntax.css` | Rouge github theme, via `rougify style github`, background swapped to the site's code fill |

Pages live at the repo root (`index.md`, `blog.html`, `research.html`,
`projects.html`, `cv.html`, `tags.html`, `404.html`).

## Writing a post

Add a file to `_posts/` named `YYYY-MM-DD-slug.md`:

```yaml
---
layout: post
title: "Post title"
description: "One-line summary, shown in listings and meta tags."
date: 2026-08-09
tags: ["TypeScript", "Type System"]
math: true      # only if the post contains $$...$$ — loads KaTeX
---
```

Posts are published at `/blog/:slug/`. Tag pages are generated automatically by
`jekyll-archives` at `/tags/:slug/`.

Set `math: true` only when needed — it's what pulls the KaTeX bundle onto the
page.

## Deployment

Pushing to `gh-pages` triggers `.github/workflows/deploy.yml`, which builds the
CSS, builds Jekyll, and publishes to GitHub Pages. Every other branch runs
`quality.yml` (build + internal link check).
