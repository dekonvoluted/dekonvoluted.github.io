---
title: Tags
layout: page
permalink: /tags/
---

{% assign totalposts = site.posts | size %}
{% for tagposts in site.tags %}{% assign tagcount = tagposts[1] | size %}{% assign x = tagcount | times: 500 | times: tagcount | divided_by: totalposts | divided_by: totalposts %}{% if x == 0 %}{% assign x = 1 %}{% endif %}{% assign fd = x | plus: 4 %}{% assign fn = x | times: 500 %}{% assign f = fn | divided_by: fd %} <a href="{{ site.url }}/tags/{{ tagposts[0] | downcase }}" style="font-size:{{ f }}%">{{ tagposts[0] }}<sup>{{ tagposts[1] | size }}</sup></a> {% endfor %}

