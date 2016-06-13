---
title: Home
layout: page
---

# Latest post

---

## [{{ site.posts.first.title }}]( {{ site.posts.first.url }} )

Published on {{ site.posts.first.date | date: "%Y-%m-%d" }}, tagged as {{ site.posts.first.tags | join: ', ' }}

# Recent posts

---

{% for post in site.posts limit: 5 %}

### [{{ post.previous.title }}]( {{ post.previous.url }} )

Published on {{ post.previous.date | date: "%Y-%m-%d" }}, tagged as {{ post.previous.tags | join: ', ' }}

{% endfor %}

