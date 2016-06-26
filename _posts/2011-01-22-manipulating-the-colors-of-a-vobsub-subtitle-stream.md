---
title: Manipulating the colors of a VobSub subtitle stream
layout: post
categories: [ user guides ]
tags: [ vobsub, subtitles, mplayer ]
comments: true
---

I'd like to standardize the color palette of vobsub subtitles of all video files in my collection.
Further, I'd like to have consistent colors between mplayer and vlc.

First, mplayer cannot play colored vobsub subtitles.
This immediately narrows down our color palette to white text with a black outline/shadow.

A typical vobsub file pair would consist of an index file (subtitle.idx) and the vobsub file (subtitle.sub).
The index file is a plain text file with a preamble section and a list of time stamps and matching subtitles indicating when the subtitles should be shown.
It's the preamble section we are interested in.

A typical preamble section might look like this:

{% highlight text %}
# VobSub index file, v7 (do not modify this line!)
size: 720x480
# The original palette of the DVD
palette: 000000, 828282, 828282, 828282, 828282, 828282, 828282, ffffff, 828282, bababa, 828282, 828282, 828282, 828282, 828282, 828282
# Custom colors (transp idxs and the four colors)
custom colors: OFF, tridx: 1000, colors: 000000, bababa, 828282, 000000
{% endhighlight %}

The original DVD color palette is of no use to us.
We can throw those lines out.
The way to control the color of the subtitles on-screen is through the custom colors.
Now, our preamble looks like this:

{% highlight text %}
# VobSub index file, v7 (do not modify this line!)
size: 720x480
custom colors: OFF, tridx: 1000, colors: 000000, bababa, 828282, 000000
{% endhighlight %}

First, set the custom colors to `ON` to activate this line.
There are four colors that you can prescribe for a vobsub subtitle stream.
The first is the background color of the subtitle.
The second is the color of the subtitle text.
The third and fourth represent the inner, thick outline/shadow and outer, thin outline/shadow around the subtitle font respectively.

The tridx parameter allows one to set one of more of these fields to be transparent.
Typically, the background to the subtitle font is set to be fully transparent (1).
The rest are opaque(0).
This is then followed by a set of four rgb colors for each of the aspects of the subtitle mentioned earlier.
I've chosen to go with this:

{% highlight text %}
custom colors: ON, tridx: 1000, colors: 000000, ffffff, 000000, 000000
{% endhighlight %}

In the above example, the background and outlines are set to be black (000000).
The font color is set to be white (ffffff).
The background is set to be fully transparent, but the font and its outlines are set to be opaque (tridx: 1000).
This produces clear, legible subtitles that follow the same color scheme regardless of whether the file is played in mplayer or vlc.

Now, merge this back into the matroska file or select this file as the subtitle while playing your video file.
Enjoy your nice looking subtitles!

