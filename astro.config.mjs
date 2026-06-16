// @ts-check
import { defineConfig } from "astro/config";
import sitemap from "@astrojs/sitemap";
import pagefind from "astro-pagefind";
import remarkMath from "remark-math";
import rehypeKatex from "rehype-katex";

/**
 * Lazy-load and async-decode all images rendered from markdown content.
 * Astro's image optimizer doesn't touch `public/` assets referenced via
 * markdown `![]()`, so we add the loading hints ourselves.
 */
function rehypeLazyImages() {
  /** @param {any} node */
  const visit = (node) => {
    if (node.type === "element" && node.tagName === "img") {
      node.properties = node.properties || {};
      if (node.properties.loading === undefined) {
        node.properties.loading = "lazy";
      }
      if (node.properties.decoding === undefined) {
        node.properties.decoding = "async";
      }
    }
    if (Array.isArray(node.children)) {
      node.children.forEach(visit);
    }
  };
  /** @param {any} tree */
  return (tree) => visit(tree);
}

// https://astro.build/config
export default defineConfig({
  site: "https://nanamanu.com",
  integrations: [sitemap(), pagefind()],
  markdown: {
    shikiConfig: {
      themes: { light: "github-light", dark: "github-dark" },
      defaultColor: false,
      wrap: true,
    },
    remarkPlugins: [remarkMath],
    rehypePlugins: [rehypeLazyImages, rehypeKatex],
  },
});
