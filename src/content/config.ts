import { defineCollection, z } from "astro:content";

const blog = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    date: z.coerce.date(),
    categories: z.string().optional(),
    description: z.string().optional(),
    draft: z.boolean().optional().default(false),
    // Author info
    author: z.string().optional(),
    // SEO fields
    image: z.string().optional(),
    tags: z.array(z.string()).optional(),
  }),
});

export const collections = { blog };
