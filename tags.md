---
title: Tags
layout: page
permalink: /tags/
---

{% for tagposts in site.tags %} <a href="{{site.url}}/tags/{{tagposts[0]}}" style="font-size:{{ tagposts[1] | size | times: 20 | plus: 70 }}%">{{tagposts[0]}}</a><sup>({{ tagposts[1] | size }})</sup> {% endfor %}

