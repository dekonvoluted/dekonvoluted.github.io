---
title: Categories
layout: archive
---

# Category cloud
---

<div class="cloud">
    {% assign maxcount = 1 %}

    {% for catposts in site.categories %}
        {% assign catcount = catposts[1] | size %}
        {% if catcount > maxcount %}
            {% assign maxcount = catcount %}
        {% endif %}
    {% endfor %}

    {% assign sden = maxcount | minus: 1 %}
    {% if sden == 0 %}
        {% assign sden = 1 %}
    {% endif %}

    {% for catposts in site.categories %}
        {% assign snum = catposts[1] | size | minus: 1 %}
        {% assign s = 300 | times: snum | divided_by: sden | plus: 100 %}
        &nbsp;
        <a href="#{{ catposts[0] | slugify }}" style="vertical-align: middle; font-size: {{ s }}%;">{{ catposts[ 0 ] }}</a>
        &nbsp;
    {% endfor %}
</div>

{% assign sorted_sitecats = site.categories | sort %}
{% for catposts in sorted_sitecats %}
<a id="{{ catposts[0] | slugify }}">
# Posts categorized as {{ catposts[0] }} <small>[(see category cloud)](#top)</small>
---

{% for post in catposts[1] %}
{% if post.subtitle %}
* [{{ post.date | date: "%Y-%m-%d" }}]({{ site.url }}/years.html#{{ page.date | date: "%Y"}}): [{{ post.title }} - {{ post.subtitle }}]({{ post.url }})
{% else %}
* [{{ post.date | date: "%Y-%m-%d" }}]({{ site.url }}/years.html#{{ page.date | date: "%Y"}}): [{{ post.title }}]({{ post.url }})
{% endif %}
{% endfor %}
{% endfor %}

