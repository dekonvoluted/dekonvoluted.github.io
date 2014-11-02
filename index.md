---
title: deKonvoluted
---

# deKonvoluted

This is a collection of posts that run the gamut from tips/user guides/how-to\'s that are universally useful to everyone, to documentation and progress reports that are only really meaningful to me.
The entries are sorted by the date originally published.

The site looks very bare now because my current know-how only extends to basic html and some css.
As I learn more things, I imagine the site would start looking spiffier.

## Blog posts

<ul>
    {% for post in site.posts %}
        <li>
            {{ post.date | date_to_string }}: <a href="{{ post.url }}">{{ post.title }}</a>
        </li>
    {% endfor %}
</ul>


© Karthik Periagaram

