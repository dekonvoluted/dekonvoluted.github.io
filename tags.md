---
title: Tags
layout: page
permalink: /tags/
---

{% assign totalposts = site.posts | size %}

{% for tagposts in site.tags %} <a href="{{ site.url }}/tags/{{ tagposts[0] | downcase }}" style="font-size:{{ tagposts[1] | size | times: 800 | divided_by: totalposts | plus: 75 }}%">{{ tagposts[0] }}<sup>{{ tagposts[1] | size }}</sup></a> {% endfor %}

