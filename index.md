---
title: Home
layout: page
---

# Blog posts

{% for post in site.posts %}
{% if post.subtitle %}
* {{ post.date | date: "%Y-%m-%d" }}: [{{ post.title }} - {{ post.subtitle }}]({{ post.url }})
{% else %}
* {{ post.date | date: "%Y-%m-%d" }}: [{{ post.title }}]({{ post.url }})
{% endif %}
{% endfor %}

