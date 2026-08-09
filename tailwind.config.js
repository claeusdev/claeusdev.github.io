/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./_layouts/**/*.html",
    "./_includes/**/*.html",
    "./_posts/**/*.md",
    "./*.html",
    "./*.md",
  ],
  theme: {
    extend: {
      // Everything is monospace, so `prose` has to inherit it too — the
      // typography plugin otherwise forces its own serif/sans stack.
      typography: ({ theme }) => ({
        DEFAULT: {
          css: {
            fontFamily: theme("fontFamily.mono").join(", "),
            maxWidth: "none",
            // Monospace runs visually wider than a proportional face at the
            // same size, so the whole scale sits a notch below Tailwind's.
            fontSize: "0.9375rem",
            lineHeight: "1.7",
            color: theme("colors.gray.800"),
            a: {
              color: theme("colors.blue.600"),
              textDecoration: "underline",
              "&:hover": { color: theme("colors.blue.800") },
            },
            "h1, h2, h3, h4": {
              fontFamily: theme("fontFamily.mono").join(", "),
              fontWeight: "600",
            },
            code: {
              fontWeight: "400",
              backgroundColor: theme("colors.stone.200"),
              padding: "0.15em 0.35em",
              borderRadius: "3px",
            },
            "code::before": { content: '""' },
            "code::after": { content: '""' },
            // Rouge's monokai theme (assets/css/syntax.css) paints highlighted
            // blocks itself; this only covers plain, unlabelled fences.
            pre: {
              backgroundColor: "#49483e",
              color: "#f8f8f2",
            },
            "pre code": { backgroundColor: "transparent", padding: "0" },
            blockquote: {
              fontStyle: "normal",
              borderLeftColor: theme("colors.stone.300"),
            },
          },
        },
      }),
    },
  },
  plugins: [require("@tailwindcss/typography")],
};
