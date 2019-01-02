---
title: Tags
layout: archive
---

# Tag cloud
---

<div class="cloud">
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

    {% for tagposts in site.tags %}
        {% assign snum = tagposts[1] | size | minus: 1 %}
        {% assign s = 300 | times: snum | divided_by: sden | plus: 100 %}
        &nbsp;
        <a href="#{{ tagposts[0] | slugify }}" style="vertical-align: middle; font-size: {{ s }}%;">{{ tagposts[0] }}</a>
        &nbsp;
    {% endfor %}
</div>

{% assign sorted_sitetags = site.tags | sort %}
{% for tagposts in sorted_sitetags %}
<a id="{{ tagposts[0] | slugify }}">
# Posts tagged {{ tagposts[0] }} <small>[(see tag cloud)](#top)</small>
---

{% for post in tagposts[1] %}
{% if post.subtitle %}
* [{{ post.date | date: "%Y-%m-%d" }}]({{ site.url }}/years.html#{{ page.date | date: "%Y"}}): [{{ post.title }} - {{ post.subtitle }}]({{ post.url }})
{% else %}
* [{{ post.date | date: "%Y-%m-%d" }}]({{ site.url }}/years.html#{{ page.date | date: "%Y"}}): [{{ post.title }}]({{ post.url }})
{% endif %}
{% endfor %}
{% endfor %}

