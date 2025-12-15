---
layout: default
title: Home
---

<h1>Bio</h1>
  <p>
  I’m a Software Engineer and Researcher. I hope to help build better software for people to bring their ideas to life, and to help improve the experience of our interactions with the BOTS (AI).
  </p>
  <p>
  I am a generalist and care deeply about systems, that form the basis of our applications; and how we use and live with computers that are all around us. More than anything, I love to build things.
  </p>
  <p>
  Previously, worked at <a href="https://rhino.com">Rhino</a>, <a href="https://leafly.com">Leafly</a>, <a href="https://andela.com">Andela</a>, <a href="https://expresspaygh.com">Expresspay</a>, <a href="https://housinganywhere.com">HousingAnywhere</a> & <a href="https://petraonline.com">PetraTrust</a>.
  </p>

  <p>
  My other interests include: Theoretical Computer Science, Programming Languages, reading and all kinds of sports.
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
