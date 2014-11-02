---
---

{% if page.previous %}
    <a href="{{ page.previous.url }}">Previous</a>
{% endif %}

<a href="/">Home</a>

{% if page.next %}
    <a href="{{ page.next.url }}">Next</a>
{% endif %}

{{ content }}

