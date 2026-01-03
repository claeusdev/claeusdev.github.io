export const SITE_TITLE = "Nana Adjei Manu";
export const SITE_DESCRIPTION = "Computer Programmer and Researcher";
export const AUTHOR = "Nana Adjei Manu";
export const EMAIL = "n.k.a.manu06@gmail.com";
export const GITHUB_USERNAME = "naamanu";
export const TWITTER_USERNAME = "nmanu__";

export const PROJECTS = [
  {
    name: "L-Language",
    description:
      "Minimal functional programming language implemented in Haskell and React for visualizing evaluation and semantics.",
    url: "https://github.com/claeusdev/l-lang",
    tags: ["Haskell", "React", "PLT"],
  },
  {
    name: "Rtpl",
    description:
      "Real-time low-latency market data processing system achieving sub-5ms message latency for trading applications.",
    url: "https://github.com/claeusdev/rtpipe",
    tags: ["Systems", "Trading", "Low Latency"],
  },
  {
    name: "Sqll",
    description:
      "Open-source SQL client library for Python using SQLite for embedded workflows.",
    url: "https://github.com/claeusdev/sqll",
    tags: ["Python", "SQL", "Library"],
  },
  {
    name: "Pricc",
    description:
      "C project generator written in Rust to simplify boilerplate systems development.",
    url: "https://github.com/claeusdev/pricc",
    tags: ["Rust", "C", "Tooling"],
  },
  {
    name: "rcv",
    description:
      "A simple resume generator written in Rust that converts declarative .rcv files into beautiful PDFs.",
    url: "https://github.com/naamanu/rcv",
    tags: ["Rust", "PDF", "CLI"],
  },
  {
    name: "cathtml",
    description:
      "A type-safe, composable DSL for building HTML pages in OCaml.",
    url: "https://github.com/naamanu/cathtml",
    tags: ["OCaml", "DSL", "HTML"],
  },
  {
    name: "gurl",
    description:
      "A simple, colorful CLI wrapper around curl for easier terminal usage.",
    url: "https://github.com/naamanu/gurl",
    tags: ["Rust", "CLI", "Tooling"],
  },
  {
    name: "raptur",
    description: "Simple express inspired router",
    url: "https://github.com/naamanu/raptur",
    tags: ["TypeScript", "Router", "Backend"],
  },
  {
    name: "cashapp",
    description: "Peer-to-peer payments service",
    url: "https://github.com/naamanu/cashapp",
    tags: ["Go", "Payments", "System"],
  },
];

export const EXPERIENCE = [
  {
    company: "Ravka Consult",
    role: "Senior Product Engineer",
    location: "Rotterdam, NL",
    duration: "Jan 2024 -- Jul 2025",
    details: [
      "Pioneered **BearSignals**, an intelligent observability platform inspired by the academic STEAM paper. Designed a cohesive architecture with a Go ingestion engine, Python analytics layer, and React frontend for seamless stateful monitoring.",
      "Delivered a commercial-grade, high-throughput data pipeline with automated root cause analysis, reducing system debugging time and improving developer insight.",
      "Mentored junior engineers in data pipeline design and API integration best practices.",
    ],
  },
  {
    company: "HousingAnywhere",
    role: "Senior Frontend Engineer",
    location: "Rotterdam, Netherlands",
    duration: "Apr 2022 -- Jan 2024",
    details: [
      "Led a complete overhaul of the front-end search infrastructure using React and TypeScript, resulting in a **35% increase** in search-to-booking conversion.",
      "Improved UI search performance by **40%** through incremental prefetching and caching, reducing load time for millions of users.",
      "Architected and implemented a full-stack feature flagging console (React, TypeScript, Go), cutting experiment turnaround from days to minutes.",
    ],
  },
  {
    company: "Andela",
    role: "Senior Software Engineer (Contract)",
    location: "Remote / New York, US",
    duration: "May 2021 -- Dec 2023",
    details: [
      "Provided senior-level engineering for global clients, focusing on full-stack development, platform modernization, and scalable system design.",
      "**SayRhino:** Built an event-driven system using Sidekiq and Redis to scale post-fulfillment operations; modularized a React codebase with Tailwind CSS, reducing maintenance by 25%. Designed CI/CD pipelines with GitHub Actions to enhance reliability.",
      "**Leafly Inc:** Directed Ruby on Rails upgrade (2.5→3.0) improving performance and security. Built GraphQL APIs and optimized search logic, reducing backend query times by 30%. Integrated Datadog monitoring for observability.",
    ],
  },
  {
    company: "Petra Trust",
    role: "Software Engineer",
    location: "Accra, Ghana",
    duration: "Dec 2019 -- Jan 2021",
    details: [
      "Architected and developed **Phoenix**, a unified CRM system with a GraphQL API (Ruby, PostgreSQL) and responsive React UI, reducing user task completion time by 25%.",
    ],
  },
  {
    company: "VendyAds",
    role: "Frontend Engineer",
    location: "Accra, Ghana",
    duration: "Jan 2018 -- Jun 2019",
    details: [
      "Developed interactive campaign management dashboards with React and Redux, improving analytics responsiveness and client satisfaction.",
    ],
  },
];

export const PUBLICATIONS = [
  {
    title: "Operational Semantics for Distributed Functional Programming",
    authors: "Nana Adjei Manu, A. Researcher",
    venue: "ICFP 2025 (Under Review)",
    year: 2025,
    url: "#",
    code: "#",
    abstract:
      "We present a new operational semantics for distributed functional programming languages that simplifies reasoning about concurrency and failure.",
  },
  {
    title: "Type-Safe Distributed Actors",
    authors: "Nana Adjei Manu",
    venue: "PLDI 2024 Student Research Competition",
    year: 2024,
    url: "#",
    code: "#",
  },
];
