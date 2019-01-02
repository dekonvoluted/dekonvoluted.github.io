---
title: Home
layout: page
---

# Latest post
---

## [{{ site.posts.first.title }}]( {{ site.posts.first.url }} )

<small>Published on [{{ site.posts.first.date | date: "%Y-%m-%d" }}]({{ site.url }}/years.html#{{ site.posts.first.date | date: "%Y"}}), under {% for category in site.posts.first.categories %} [{{ category }}]({{ site.url }}/categories.html#{{ category | slugify }}){% unless forloop.last %}, {% endunless %}{% endfor %}, and tagged {% for tag in site.posts.first.tags %} [{{ tag }}]({{ site.url }}/tags.html#{{ tag | slugify }}){% unless forloop.last %}, {% endunless %}{% endfor %}</small>

{{ site.posts.first.excerpt }}

# Recent posts
---

{% for post in site.posts limit: 5 %}

### [{{ post.previous.title }}]( {{ post.previous.url }} )

<small>Published on [{{ post.previous.date | date: "%Y-%m-%d" }}]({{ site.url }}/years.html#{{ post.previous.date | date: "%Y"}}), under {% for category in post.previous.categories %} [{{ category }}]({{ site.url }}/categories.html#{{ category | slugify }}){% unless forloop.last %}, {% endunless %}{% endfor %}, and tagged {% for tag in post.previous.tags %} [{{ tag }}]({{ site.url }}/tags.html#{{ tag | slugify }}){% unless forloop.last %}, {% endunless %}{% endfor %}</small>

{% endfor %}

