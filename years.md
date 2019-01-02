---
title: Years
layout: archive
---

# Year cloud
---

<div class="cloud">
    {% assign siteyears = site.posts | group_by_exp:"post", "post.date | date: '%Y'" %}
    {% assign maxcount = 1 %}

    {% for yearposts in siteyears %}
        {% assign yearcount = yearposts.items | size %}
        {% if yearcount > maxcount %}
            {% assign maxcount = yearcount %}
        {% endif %}
    {% endfor %}

    {% assign sden = maxcount | minus: 1 %}
    {% if sden == 0 %}
        {% assign sden = 1 %}
    {% endif %}

    {% for yearposts in siteyears reversed %}
        {% assign snum = yearposts.items | size | minus: 1 %}
        {% assign s = 300 | times: snum | divided_by: sden | plus: 100 %}
        &nbsp;
        <a href="#{{ yearposts.name | slugify }}" style="vertical-align: middle; font-size: {{ s }}%;">{{ yearposts.name }}</a>
        &nbsp;
    {% endfor %}
</div>

{% for yearposts in siteyears %}
<a id="{{ yearposts.name | slugify }}">
# Posts published in {{ yearposts.name }} <small>[(see year cloud)](#top)</small>
---

{% for post in yearposts.items %}
{% if post.subtitle %}
* [{{ post.date | date: "%Y-%m-%d" }}]({{ site.url }}/years.html#{{ page.date | date: "%Y"}}): [{{ post.title }} - {{ post.subtitle }}]({{ post.url }})
{% else %}
* [{{ post.date | date: "%Y-%m-%d" }}]({{ site.url }}/years.html#{{ page.date | date: "%Y"}}): [{{ post.title }}]({{ post.url }})
{% endif %}
{% endfor %}
{% endfor %}

