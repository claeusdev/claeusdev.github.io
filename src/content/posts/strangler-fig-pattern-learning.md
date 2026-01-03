---
title: "Learning with the Strangler Fig Pattern: Replace Your Skills Gradually"
description: "Discover how to apply the Strangler Fig Pattern from software architecture to career transitions and skill development. Learn to modernize yourself gradually without the risk of a 'Big Bang' change."
date: 2025-12-28
author: "Nana Adjei Manu"
categories: "growth"
image: "/strangler-fig-learning.png"
tags: ["Career Development", "Learning", "Personal Growth"]
---

![Strangler Fig Pattern Learning Header](/strangler-fig-learning.png)

We often treat learning a new skill or changing careers like a "Big Bang rewrite". You remove the entire existing system and try to build a shiny new one from scratch. It almost always fails. It takes too long, costs too much, and it's incredibly risky.

We tell ourselves: _"I hate my job as an accountant. I'm going to quit, go to a coding bootcamp for six months, and become a developer!"_. I've seen this happen time and time again, heck, this year, I've seen it happen to my friends. I've seen it happen to myself.

This is high-risk, expensive, and stressful. It's the equivalent of leaving a long-term relationship and attempting to start a new one from scratch with someone you're yet to meet or not even sure you're compatible with.

There is a better way. Just like software architects use the **Strangler Fig Pattern** to modernize legacy systems, you can use it to modernize _yourself_.

## My Own Strangler Fig Story

I didn't quit my day job to become a programming languages researcher overnight. That would have been insane.

Instead, I started planting seeds while my "legacy system" (Typescript, React, Go) kept paying the bills.

It started with a YouTube video. I stumbled on a talk by Yaron Minsky about compilers and how Jane Street uses OCaml. Something clicked. I didn't just want to _use_ tools—I wanted to understand how they were built. I wanted to work at a place like Jane Street someday.

The problem? I was a product engineer—comfortable with React, Ruby, Go, distributed systems—but I had zero formal CS background in compilers or type theory. That world felt impossibly far away.

So I did something unconventional: I enrolled in a master's program (a lot more on this later) and chose programming language theory as my thesis topic. Not because I was already an expert—but because I wanted to become one. The thesis became my forcing function.

That curiosity became the first seed.

## Step 1: Identify the "Microservice"

Don't try to learn _everything_ at once. When I wanted to explore programming language theory, I didn't immediately try to implement a full compiler with type inference and optimizations.

I picked one tiny, isolated component: **build a simple Lisp interpreter**.

Why Lisp? Because the syntax is trivial—you can focus purely on evaluation semantics. I called it Swirl, and it started as just 200 lines of Rust that could evaluate `(+ 1 2)`.

That was my first microservice.

## Step 2: Route the Traffic (The Magic Step)

In software, we use a "router" to send specific requests to the new system while the old system handles the rest.

In your life, **you** are the router.

I was still doing "boring" product engineering work full-time, but I started routing small tasks through my new skills:

- When I needed a CLI tool at work, instead of reaching for Node.js, I built [gurl](https://github.com/naamanu/gurl) in Rust—a colorful `curl` wrapper.
- When I wanted to generate my resume, I didn't use a template. I built [rcv](https://github.com/naamanu/rcv), a Rust DSL that compiles `.rcv` files to PDFs.
- When I needed to prototype HTML layouts, I wrote [cathtml](https://github.com/naamanu/cathtml)—a type-safe HTML DSL in OCaml.

Each project was _real work_ that I would have done anyway. I just routed it through the skills I wanted to develop.

I was technically a "systems programmer" for an hour a day. The rest of the day, my product engineering skills kept the system running.

## Step 3: Expand the Root System

Once that first tiny skill is stable, pick another.

After the Lisp interpreter worked, I added:

- **A REPL** that runs in the terminal
- **A web playground** compiled to WebAssembly
- **Proper error messages** with source locations

But the real expansion came from my thesis. I built [L-Language](https://github.com/naamanu/l-lang)—a minimal functional language in Haskell with a React visualizer for understanding evaluation semantics. To support it, I wrote blog posts on [operational semantics](/posts/operational-semantics-1-formal-intro) to teach myself by teaching others.

The thesis forced me to go deeper than hobby projects ever would. I explored formal methods, type systems, and the theory behind distributed systems. Now I was a programming languages person for about 4-5 hours a day. Right after I shut down my work laptop, I'd get to the gym for about an hour (really important part), then get home and just read papers, watch videos, and write code.

## Step 4: Strangle the Old Ways

Over time, you keep building new "microservices" (skills) and routing more work to them.

My GitHub started looking less like a product engineer's and more like a PLT researcher's. I was drafting proposals for ICFP (none that I actually had the confidence to submit—might be a good idea to do that this year). I was reading Plotkin and Pierce. I was building type systems.

Eventually, the new "system" became more valuable than the old one. The "legacy" product engineering career served its purpose—it supported me while the new me grew strong enough to stand on its own.

## The Practical Playbook

Here's exactly what I did, distilled:

| Week  | Action                                              |
| ----- | --------------------------------------------------- |
| 1-4   | Read one PL paper per week on the train             |
| 5-8   | Build a tiny Lisp interpreter (just `eval`)         |
| 9-12  | Rebuild a work tool in the new language (Rust CLI)  |
| 13-20 | Write about what you're learning (forces clarity)   |
| 21+   | Start contributing to open source in the new domain |

The key is that **at no point did I quit my job**. I just kept routing more traffic to the new skills until the switchover was natural.

## Why This Beats the "Big Bang"

1. **Lower Risk:** You don't lose your income while you learn. When my first Rust CLI tool was buggy, it didn't matter—I still had my day job salary.

2. **Real Feedback:** You aren't learning in a vacuum. I wasn't doing toy exercises; I was building [actual tools](https://github.com/naamanu) I used daily.

3. **Compound Growth:** Each project builds on the last. The Lisp interpreter taught me evaluation. That made the operational semantics posts easy. Those posts led to the research proposal.

4. **Less Burnout:** You aren't trying to change your entire identity overnight. Some days I wrote React. Some days I wrote Haskell. The variety kept me energized.

## Your Turn

What's the seed you want to plant?

Maybe you're a backend developer curious about machine learning. Don't enroll in a 6-month bootcamp. Just:

1. Automate one data task with a simple Python script
2. Add a basic prediction to an existing feature
3. Write about what you learned
4. Repeat, routing more tasks to the new skill

Don't chop down the tree. Plant a seed, let it grow, and let the transformation happen naturally.

The strangler fig doesn't kill its host overnight. It takes years. But when it's done, it's the only thing standing.
