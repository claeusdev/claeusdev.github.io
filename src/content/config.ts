import { defineCollection, z } from "astro:content";

const posts = defineCollection({
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

const essays = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    date: z.coerce.date(),
    description: z.string().optional(),
    draft: z.boolean().optional().default(false),
    author: z.string().optional(),
    image: z.string().optional(),
    tags: z.array(z.string()).optional(),
    // Essay-specific fields
    subtitle: z.string().optional(),
    wordCount: z.number().optional(),
  }),
});

const research = defineCollection({
  type: "content",
  schema: z.object({
    title: z.string(),
    date: z.coerce.date(),
    description: z.string().optional(),
    draft: z.boolean().optional().default(false),
    author: z.string().optional(),
    image: z.string().optional(),
    tags: z.array(z.string()).optional(),
    // Research-specific fields
    abstract: z.string().optional(),
    institution: z.string().optional(),
    coAuthors: z.array(z.string()).optional(),
    publicationStatus: z
      .enum(["draft", "preprint", "published", "in-review"])
      .optional(),
    pdfUrl: z.string().optional(),
    arxivUrl: z.string().optional(),
    venue: z.string().optional(), // Conference or journal name
  }),
});

export const collections = { posts, essays, research };
