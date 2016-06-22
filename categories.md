---
title: Categories
layout: page
permalink: /categories/
---

{% for categoryposts in site.categories %} <a href="{{ site.url }}/categories/{{ categoryposts[0] | downcase }}" style="font-size:{{ categoryposts[1] | size | times: 20 | plus: 70 }}%">{{ categoryposts[0] }}<sup>{{ categoryposts[1] | size }}</sup></a> {% endfor %}

