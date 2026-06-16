import { OGImageRoute } from "astro-og-canvas";
import { getCollection } from "astro:content";
import { AUTHOR } from "../../consts";

// Build OG cards for every published post/essay/research entry.
// Routes resolve to /og/<collection>/<slug>.png
const [posts, essays, research] = await Promise.all([
  getCollection("posts"),
  getCollection("essays"),
  getCollection("research"),
]);

const pages: Record<string, { title: string }> = {};
for (const entry of posts) {
  if (!entry.data.draft) pages[`posts/${entry.slug}`] = entry.data;
}
for (const entry of essays) {
  if (!entry.data.draft) pages[`essays/${entry.slug}`] = entry.data;
}
for (const entry of research) {
  if (!entry.data.draft) pages[`research/${entry.slug}`] = entry.data;
}

const route = await OGImageRoute({
  param: "route",
  pages,
  getImageOptions: (_path: string, page: { title: string }) => ({
    title: page.title,
    description: AUTHOR,
    bgGradient: [
      [15, 17, 21],
      [24, 27, 33],
    ],
    border: { color: [37, 99, 235], width: 18, side: "inline-start" },
    padding: 80,
    font: {
      title: {
        color: [255, 255, 255],
        size: 64,
        weight: "Bold",
        lineHeight: 1.2,
      },
      description: {
        color: [148, 163, 250],
        size: 30,
        weight: "Normal",
      },
    },
  }),
});

export const getStaticPaths = route.getStaticPaths;
export const GET = route.GET;
