import rss from "@astrojs/rss";
import { getCollection } from "astro:content";
import { SITE_TITLE, SITE_DESCRIPTION } from "../consts";

export async function GET(context) {
  const [posts, essays, research] = await Promise.all([
    getCollection("posts"),
    getCollection("essays"),
    getCollection("research"),
  ]);

  const items = [
    ...posts.map((entry) => ({
      title: entry.data.title,
      pubDate: entry.data.date,
      description: entry.data.description || "",
      link: `/posts/${entry.slug}/`,
      draft: entry.data.draft,
    })),
    ...essays.map((entry) => ({
      title: entry.data.title,
      pubDate: entry.data.date,
      description: entry.data.description || "",
      link: `/essays/${entry.slug}/`,
      draft: entry.data.draft,
    })),
    ...research.map((entry) => ({
      title: entry.data.title,
      pubDate: entry.data.date,
      description: entry.data.abstract || entry.data.description || "",
      link: `/research/${entry.slug}/`,
      draft: entry.data.draft,
    })),
  ];

  return rss({
    title: SITE_TITLE,
    description: SITE_DESCRIPTION,
    site: context.site,
    items: items
      .filter((item) => !item.draft)
      .sort((a, b) => b.pubDate.valueOf() - a.pubDate.valueOf())
      .map(({ draft, ...item }) => item),
  });
}
