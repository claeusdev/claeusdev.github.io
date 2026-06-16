import rss from "@astrojs/rss";
import { getCollection } from "astro:content";
import { SITE_TITLE, SITE_DESCRIPTION } from "../consts";
import MarkdownIt from "markdown-it";
import sanitizeHtml from "sanitize-html";

const parser = new MarkdownIt({ html: true, linkify: true, typographer: true });

export async function GET(context) {
  const site = context.site.toString().replace(/\/$/, "");

  const render = (markdown) => {
    const html = parser.render(markdown || "");
    const clean = sanitizeHtml(html, {
      allowedTags: sanitizeHtml.defaults.allowedTags.concat([
        "img",
        "h1",
        "h2",
      ]),
      allowedAttributes: {
        ...sanitizeHtml.defaults.allowedAttributes,
        img: ["src", "alt"],
      },
    });
    // Make root-relative URLs absolute so feed readers resolve them.
    return clean.replace(/(src|href)="\/(?!\/)/g, `$1="${site}/`);
  };

  const [posts, essays, research] = await Promise.all([
    getCollection("posts"),
    getCollection("essays"),
    getCollection("research"),
  ]);

  const items = [
    ...posts.map((e) => ({ e, prefix: "posts" })),
    ...essays.map((e) => ({ e, prefix: "essays" })),
    ...research.map((e) => ({ e, prefix: "research" })),
  ]
    .filter(({ e }) => !e.data.draft)
    .map(({ e, prefix }) => ({
      title: e.data.title,
      pubDate: e.data.date,
      description: e.data.abstract || e.data.description || "",
      link: `/${prefix}/${e.slug}/`,
      content: render(e.body),
    }))
    .sort((a, b) => b.pubDate.valueOf() - a.pubDate.valueOf());

  return rss({
    title: SITE_TITLE,
    description: SITE_DESCRIPTION,
    site: context.site,
    items,
  });
}
