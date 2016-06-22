---
title: Categories
layout: page
permalink: /categories/
---

{% assign totalposts = site.posts | size %}

{% for categoryposts in site.categories %} <a href="{{ site.url }}/categories/{{ categoryposts[0] | downcase }}" style="font-size:{{ categoryposts[1] | size | times: 800 | divided_by: totalposts | plus: 75 }}%">{{ categoryposts[0] }}<sup>{{ categoryposts[1] | size }}</sup></a> {% endfor %}

