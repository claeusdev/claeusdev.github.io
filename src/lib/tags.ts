import { getCollection, type CollectionEntry } from "astro:content";

export type Post = CollectionEntry<"posts">;

/** Turn a human tag ("Programming Languages") into a URL slug ("programming-languages"). */
export function tagSlug(tag: string): string {
  return tag
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

export async function getPublishedPosts(): Promise<Post[]> {
  return (await getCollection("posts"))
    .filter((post) => !post.data.draft)
    .sort((a, b) => b.data.date.valueOf() - a.data.date.valueOf());
}

export type Tag = { name: string; slug: string; posts: Post[] };

/** Map of tag-slug → { display name, slug, posts (newest first) }. */
export async function getTagMap(): Promise<Map<string, Tag>> {
  const posts = await getPublishedPosts();
  const map = new Map<string, Tag>();
  for (const post of posts) {
    for (const tag of post.data.tags ?? []) {
      const slug = tagSlug(tag);
      if (!map.has(slug)) map.set(slug, { name: tag, slug, posts: [] });
      map.get(slug)!.posts.push(post);
    }
  }
  return map;
}
