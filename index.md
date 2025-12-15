---
layout: default
title: Home
---

<h1>Bio</h1>
  <p>
  I’m a Computer Programmer, Software Engineer and Researcher. My experience involves building distributed web systems and related tooling. I am currently researching operational semantics functional programming.
  </p>
  <p>
  My interests include but not limited to programming language theory, distributed systems, computational finance and data systems.
  </p>
  <p>
  I've worked at <a href="https://rhino.com">Rhino</a>, <a href="https://leafly.com">Leafly</a>, <a href="https://andela.com">Andela</a>, <a href="https://expresspaygh.com">Expresspay</a>, <a href="https://housinganywhere.com">HousingAnywhere</a> & <a href="https://petraonline.com">PetraTrust</a>.
  </p>

<div id="home">
  <h1>Blog Posts</h1>
  <ul class="posts">
    {% for post in site.posts %}
      <li><span>{{ post.date | date_to_string }}</span> &raquo; <a href="{{ post.url }}">{{ post.title }}</a></li>
    {% endfor %}
  </ul>

  <h1>Open Source Projects</h1>
  <ul class="posts">
    {% for project in site.data.projects %}
      <li><a href="{{ project.url }}">{{ project.name }}</a> — {{ project.description }}</li>
    {% endfor %}
  </ul>
</div>
