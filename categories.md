---
title: Categories
layout: page
permalink: /categories/
---

{% assign totalposts = site.posts | size %}
{% for categoryposts in site.categories %}{% assign categorycount = categoryposts[1] | size %}{% assign x = categorycount | times: 500 | times: categorycount | divided_by: totalposts | divided_by: totalposts %}{% if x == 0 %}{% assign x = 1 %}{% endif %}{% assign fd = x | plus: 4 %}{% assign fn = x | times: 500 %}{% assign f = fn | divided_by: fd %} <a href="{{ site.url }}/categories/{{ categoryposts[0] | downcase }}" style="font-size:{{ f }}%">{{ categoryposts[0] }}<sup>{{ categoryposts[1] | size }}</sup></a> {% endfor %}

