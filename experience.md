---
layout: default
title: Experience
---

# Experience

{% for job in site.data.experience %}
### {{ job.role }} @ {{ job.company }}
<span class="meta">{{ job.duration }} | {{ job.location }}</span>

{% for detail in job.details %}
* {{ detail }}
{% endfor %}

{% endfor %}

## Skills

* **Languages**: TypeScript, Go, Ruby, Python, C/C++, Rust, OCaml, SQL, Haskell
* **Frameworks & Tools**: React/Redux, Rails, Tailwind CSS, FastAPI, Sidekiq
* **Infrastructure**: PostgreSQL, Redis, Docker, AWS, GCP, Heroku, DigitalOcean

## Education

**University of Leicester** — Leicester, UK  
*Master of Science in Advanced Computer Science; Distinction*
