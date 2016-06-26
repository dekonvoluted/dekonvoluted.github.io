---
title: Categories
layout: page
permalink: /categories/
---

{% for categoryposts in site.categories %}
# <a href="{{ site.url }}/categories/{{ categoryposts[0] | downcase }}">{{ categoryposts[0] }}</a>
{% assign postcount = categoryposts[1] | size %}
{% if postcount == 1 %}
{{ postcount }} post
{% else %}
{{ postcount }} posts
{% endif %}
{% endfor %}

