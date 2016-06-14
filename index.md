---
title: Home
layout: page
---

# Latest post

---

## [{{ site.posts.first.title }}]( {{ site.posts.first.url }} )

Published on {{ site.posts.first.date | date: "%Y-%m-%d" }}, tagged {% for tag in site.posts.first.tags %} [ {{ tag }} ]( tags/{{ tag | downcase }} ) {% unless forloop.last %} , {% endunless %} {% endfor %}

# Recent posts

---

{% for post in site.posts limit: 5 %}

### [{{ post.previous.title }}]( {{ post.previous.url }} )

Published on {{ post.previous.date | date: "%Y-%m-%d" }}, tagged {% for tag in post.previous.tags %} [ {{ tag }} ]( tags/{{ tag | downcase }} ) {% unless forloop.last %} , {% endunless %} {% endfor %}

{% endfor %}

