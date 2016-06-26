---
title: Implementing a proportional tag cloud in Jekyll
layout: post
categories: [ user guides ]
tags: [ jekyll, liquid, tags ]
comments: true
---

<script type="text/javascript" async
    src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-MML-AM_CHTML">
</script>

This blog, like many others on GitHub, is created using Jekyll.
Unlike most of those blogs, however, this one's rather simple looking---in front and behind the scenes.
The style sheet is pretty basic and the pages are nearly beginner-level HTML.
It is also lacking several nice features, such as a built-in search for example.
That's mostly because I wrote every source file in this blog from scratch while teaching myself how each piece works.

There are, in my opinion, two nifty bits that I should document sometime.
The first is a crafty bit of CSS that allows a reader to select code, but not the line numbers alongside the code.
This was a copy-paste from a forgotten source and I'll document it when I understand the underlying code better.
The second nifty bit, and what this post is about, is how the tag cloud is implemented.

Generally, tag clouds provide an overview of the sort of topics touched upon by posts in a blog at a glance.
Frequently visited topics are generally highlighted compared to other less frequent ones.
So, the goal here is to implement a tag cloud listing the tags mentioned in the headers of the posts in this blog.
Let's take this one step at a time.

An initial implementation could simply list all tags used in the site one after another.
In the code blocks that follow, I've broken up the liquid code using newlines and faux-indentation to make it easier to follow.

{% highlight liquid %}
{% raw %}
{% for tagposts in site.tags %}
    {{ tagposts[0] }}
{% endfor %}
{% endraw %}
{% endhighlight %}

The property `site.tags` returns a hash with the keys being the tags and the values being an array of posts featuring those tags.
The keys are ordered chronologically from the oldest to the newest.
If we like, we could list them alphabetically.
Sorting the keys of a hash is a bit hackish in jekyll as a `sort` filter is unavailable.
However, we can capture the tags into a comma-separated string, split the string and sort the resulting array.
Of course, if we plan to use commas as the delimiter, we need to be sure none ever appears as part of any tags.

{% highlight liquid %}
{% raw %}
{% capture tagarray %}
    {% for tagposts in site.tags %}
        {{ tagposts[0] }}
        {% unless forloop.last %}
            ,
        {% endunless %}
    {% endfor %}
{% endcapture %}

{% assign sortedTags = tagarray | split: "," | sort %}

{% for tag in sortedTags %}
    {{ tag }}
{% endfor %}
{% endraw %}
{% endhighlight %}

This sorting isn't perfect and will sort tags beginning with an uppercase letter (e.g. C++) before tags beginning with a lowercase letter (e.g. blog).
We could work around it by sorting the tags in downcase and printing out tags matching the next sorted tag, but it's too much trouble.
I prefered the chronological order over the alphabetical order anyway, so that's what I implemented.
I also wanted to show the number of posts next to the tag, so I added the post count as a superscript.

{% highlight liquid %}
{% raw %}
{% for tagposts in site.tags %}
    {{ tagposts[0] }}<sup>{{ tagposts[1] | size }}</sup>
{% endfor %}
{% endraw  %}
{% endhighlight %}

This forms the backbone of the tag cloud.
The next step is to figure out how to highlight each tag in a way that correlates with its frequency of use.

# Linear #1

A straightforward implementation is to simply make the font size, \\(s\\), a linear function of the number of posts with that tag, \\(n\\).

\\[
    s = mn + c
\\]

\\(n\\) is bounded on the lower end at 1, but unbounded at the high end.
When \\(n=1\\), \\(s=100\\), so \\(c=100-m\\).
The choice of \\(m\\) simply comes down to what we want \\(s_{n+1}-s_{n}\\) to be.
For an initial test, let's say each time a tag is referenced in a new post, its size increases by 10%.

\\[
    s = 10\%n + 90\%
\\]

The corresponding liquid code would look like as follows.
To avoid the code getting too cluttered, I'll leave out the superscript as it's not essential to the implementation.
For the same reason, I've also used paragraph tags here instead of anchor tags linking the tag to its individual tag page.

{% highlight liquid %}
{% raw %}
{% for tagposts in site.tags %}
    {% assign frequency = tagposts[1] | size %}

    <p style="font-size: {{ frequency | times: 10 | plus: 90 }}%">
        {{ tagposts[0] }}
    </p>
{% endfor %}
{% endraw %}
{% endhighlight %}

The primary issue with this approach is that the font size of a frequently used tag will grow ever larger as more new posts referencing it are published.

# Linear #2

We could try using a normalized frequency instead of the raw count by dividing the frequency of each tag by the total number of posts published.

\\[
    f = \frac{n}{\sum{n}}
\\]

Now, \\(f\\) is bounded between 0.0 and 1.0 and we have a new problem.
Liquid's math filters don't do floating point calculations.
All operations strictly produce integers.
We can get around this by using a scaled normalized frequency so a desired level of precision, say down to 0.01, is preserved.

\\[
    f = \frac{100n}{\sum{n}}
\\]

Now, \\(f\\) is bounded between 0 and 100.
Next, we need to pick the maximum font size we want to see in the tag cloud.
A value like 500% seems reasonable.
Our equation for the font size looks like this,

\\[
    s = mf + c
\\]

When \\(f=0\\), \\(s=100\\) and when \\(f=100\\), \\(s=500\\).
Solving for \\(m\\) and \\(c\\), we get,

\\[
    s = 4f + 100%
\\]

Implemented in liquid, this produces the following code block.

{% highlight liquid %}
{% raw %}
{% assign totalposts = site.posts | size %}

{% for tagposts in site.tags %}
    {% assign frequency = tagposts[1] | size | times: 100 | divided_by: totalposts %}

    <p style="font-size: {{ frequency | times: 4 | plus: 100 }}%">
        {{ tagposts[0] }}
    </p>
{% endfor %}
{% endraw %}
{% endhighlight %}

This form does have some nice properties.
As the total number of posts continues to grow, the least frequently used tags will remain at 100% font size, while a tag that is used for every single post will be scaled to 500% the default font size.
Of course, the actual size on screen will depend on other details like the default font size and the availability of glyphs of the font type at the requested scaling.

Sadly, we can't be more precise than 0.01 for the frequency.
If we attempt it, the multiplier drops below 1 and that's zero according to liquid math.
Also, in practice, this linear fit won't look too good for most tag clouds.
I'd be willing to bet that a typical blog would have a lot of infrequent tags and very few, if any, that appear in more than half the posts.
So, as the number of posts climbs higher and higher, we'd be left with a tag cloud that's almost all close to 100% with barely discernible differences between tags.

# Nonlinear #3

So, we actually need a functional form like \\(\sqrt{x}\\) that rises fast, but plateaus for high frequencies.
That way, tags with low counts will stand apart from each other, but high frequency tags will mostly look the same.
Sadly, liquid's math filters don't support taking square roots, so I played around and came up with this functional form,

\\[
    s = \\frac{af^2}{f^2+b}
\\]

You'll notice that the value of \\(s\\) is bounded for any value of \\(f\\).
Also, when graphed, this produces a fast rise and slow plateau shape we wanted.
Since the value is bounded for any \\(f\\),we could use either the raw count of the tags or the normalized frequency with a high precision multiplier.
Heck, we could go with a million, but let's start off with something like a thousand for the precision multiplier.
Since in the limit of \\(f\\) being arbitrarily high, \\(s \to a\\), \\(a\approx500\%\\).
At the low end, \\(f\\) hits zero and causes \\(s\\) to vanish.
To prevent that, we'll force the lower end to be unity, instead of zero---if \\(f<1\times1000\\), \\(f=1\times1000\\).
Now that \\(f\\) has a non-zero lower bound, \\(b\approx(\frac{500\%}{100\%}-1)\times 1000\times1000=4000000\\).
Notice how all of this can be recalculated if the precision multiplier is different from 1000.

Let's look at the liquid implementation.

{% highlight liquid %}
{% raw %}
{% assign totalposts = site.posts | size %}

{% for tagposts in site.tags %}
    {% assign tagcount = tagposts[1] | size %}

    {% assign f = tagcount | times: 1000 | divided_by: totalposts %}
    {% assign fsq = f | times: f %}

    {% assign snum = 500 | times: fsq %}
    {% assign sden = 4000000 | plus: fsq %}

    {% assign s = snum | divided_by: sden %}

    <p style="font-size: {{ s }}%">
        {{ tagposts[0] }}
    </p>
{% endfor %}
{% endraw %}
{% endhighlight %}

This works great.
The lower end of the tag cloud resolves clearly by frequency, while the most frequent tags tend to start looking about the same size.
At a glance, it's very easy to tell which tags are used more than others.
Still, there are shortcomings.
In the case where the most frequent tag appears a constant \\(n_{max}\\) times, but the total number of posts increases unboundedly, the font size of this most frequent tag keeps on diminishing with every additional post that doesn't use it.
Also, the maximum font size we chose, 500%, doesn't directly show up in the tag cloud unless some tag appears in every single post.

# Linear #4

This is the solution I eventually went with.
Instead of normalizing the frequency with the total number of posts, I used the minimum and maximum values of the frequencies instead.
The minimum count for any tag is always 1.
If the maximum count is also one, it's artificially bumped to 2 so that the denominator \\(n_{max} - 1\)) is non-zero.
Now, I can apply a simple linear transformation to go from 100% to 500%.

\\[
    s = 100\% + 400\% \times \frac{ n - 1 }{ n_{max} - 1 }
\\]

There's no need for precision preserving multipliers anymore.
All numerators and denominators are integers.

Here's the liquid implementation.

{% highlight liquid %}
{% raw %}
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
    {% assign s = 400 | times: snum | divided_by: sden | plus: 100 %}

    <p style="font-size: {{ s }}%">
        {{ tagposts[0] }}
    </p>
{% endfor %}
{% endraw %}
{% endhighlight %}

Now, the tag cloud adapts to the relative frequency of tags used in the blog and not to the total number of posts (which has, and should have no effect).
The most frequent tag will always be at max size (unless it's only used once) and the least frequent tag will always be at the minimum size.

