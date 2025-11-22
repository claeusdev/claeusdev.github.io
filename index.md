---
layout: default
title: Home
---

I’m a Computer Programmer, Software Engineer and Researcher. My experience involves building distributed web systems and related tooling. I am currently researching operational semantics functional programming.

My interests include but not limited to programming language theory, distributed systems, computational finance and data systems.

I've worked at <span class="company-name">[Rhino](https://rhino.com)</span>, <span class="company-name">[Leafly](https://leafly.com)</span>, <span class="company-name">[Andela](https://andela.com)</span>, <span class="company-name">[Expresspay](https://expresspaygh.com)</span>, <span class="company-name">[HousingAnywhere](https://housinganywhere.com)</span> & <span class="company-name">[PetraTrust](https://petraonline.com)</span>.

I’m available online: [Twitter](https://twitter.com/nmanu) • [Linkedin](https://linkedin.com/in/nanaadjeimanu) • [Github](https://github.com/claeusdev)

# Open Source Projects

{% for project in site.data.projects %}
* <span class="project-name">[{{ project.name }}]({{ project.url }})</span> — {{ project.description }}
{% endfor %}

# Blog

{% for post in site.posts %}
* <span class="post-date">{{ post.date | date: "%Y-%m-%d" }}</span> — [{{ post.title }}]({{ post.url }})
{% endfor %}
