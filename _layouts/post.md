---
layout: default
---

<h1>{{ page.title }}</h1>

<small><i>Categories</i>: {{ page.categories | array_to_sentence_string }}, <i>Tags</i>: {{ page.tags | array_to_sentence_string }}, <i>Published on</i> {{ page.date | date: "%Y-%m-%d" }}</small>

<hr>

{{ content }}

<hr>

