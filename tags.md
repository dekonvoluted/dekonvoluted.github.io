---
title: Tags
layout: page
permalink: /tags/
---

{% assign maxcount = 1 %}

{% for tagposts in site.tags %}
{% assign tagcount = tagposts[1] | size %}
{% if tagcount > maxcount %}
{% assign maxcount = tagcount %}
{% endif %}
{% endfor %}

{% assign sden = maxcount | minus: 1 %}
{% if sden == 0 %}
{% assign sden = 1 %}
{% endif %}

{% for tagposts in site.tags %}{% assign snum = tagposts[1] | size | minus: 1 %}{% assign s = 300 | times: snum | divided_by: sden | plus: 100 %} <a href="{{ site.url }}/tags/{{ tagposts[0] | downcase }}" style="font-size:{{ s }}%">{{ tagposts[0] }}<sup>{{ tagposts[1] | size }}</sup></a> {% endfor %}

