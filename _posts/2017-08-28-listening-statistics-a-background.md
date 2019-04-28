---
title: Listening Statistics - A background
layout: post
series: music-player
categories: [ project KDE ]
tags: [ music, amarok, kde ]
---

# A brief history of Amarok

[Amarok](https://amarok.kde.org/) was (and is) a music player for linux.
It was wildly popular in the early 2000s, holding a lion's share of the linux desktop by dint of its feature-richness and quality user experience.
It was part of the KDE project and was released on an independent release cycle as part of the KDE extragear module.
Amarok's tagline was "Rediscover your music", which it helped the user do by providing a wealth of contextual information when it played a song in the user's collection.
This information was a mix of locally crunched stats (playcounts, ratings, a computed score, etc.), combined with information retrieved from the internet (lyrics, wikipedia articles, last.fm tags, etc.).
In addition to this, you could write scripts to execute at the end of each song, opening the door to vast amounts of customization.

In the later years of the decade, when the parent KDE project decided to modernize their codebase in transitioning from Qt 3.x to Qt 4.x, the Amarok project also followed suit.
This meant abandoning the very mature, but dead-ended code for its 1.4.x series and starting fresh on a 2.x series.
While [KDE's core desktop](https://www.kde.org/plasma-desktop) survived and benefited from the tumultuous multi-year transition and subsequent stabilization, Amarok unfortunately came out the worse for wear.
Built to integrate closely to its parent desktop, the Amarok project found itself trying to stabilize on top of a desktop that was doing quite a bit of *rediscovering* of its own.
The userbase left in droves, frustrated by the project's inability to reach the heights of functionality and stability that the 1.x series ended with.
Amarok 2.x soldiered on for several incremental releases, more or less coming to and end with a whimper in its relatively stable 2.8.x release series.
The project isn't technically dead, but it would be a stretch to call it thriving at this point.

Any history of Amarok would be incomplete without mention of [Clementine](https://www.clementine-player.org/), a project started to continue development on the 1.x series.
A premise like that tends to constrain UI changes, but the project has done admirably well since.
Notable feature additions include a vastly expanded set of web-based services, built-in transcoding, built-in moodbar support and a host of charming new features like background sounds.
The ability to run user-scripts has however, been removed.
Statistics in Clementine are mostly relegated to smart playlists.

# I like statistics and I cannot lie

I've been using Amarok as my music manager since 2006 and I have a different story to tell.
Right from the start, I was attracted to the locally crunched statistics that Amarok provided.
My first contribution was [an Amarok/ruby script]({% post_url 2007-09-02-karperscore-is-born %}) I wrote to calculate the score of a song in a different way.
A couple of years ago, I booted up a Kubuntu 8.04 liveCD and took these screenshots showing some of that functionality.
Since the last.fm integration is broken (probably due to API updates since 2008), we can't see tags or a list of songs (ranked by your rating or the score) by similar artists according to last.fm.
I hope this gives you a good idea of what drew me to Amarok.

![Nothing playing](/images/amarok-statistics-1.png) ![Something playing](/images/amarok-statistics-2.png)

As an aside, Amarok actually used to have a separate statistics viewer which displayed some more information, perhaps less elegantly.

![More statistics](/images/amarok-statistics-3.png)

It wasn't all a bed of roses back then.
The vaunted context view was basically a hard-coded html page and offered no customizability and no way to explore other interesting statistics.
Requests for major changes were (understandably) postponed as the 2.x version entered heavy development.
To be fair, Amarok 2 did deliver on this, filling the context view with customizable widgets, but the lack of powerful widgets, either built-in or community-created renders it a moot point.

And all that background brings me to today.
For the past ten years and counting, I have listening data archived on [last.fm](http://www.last.fm/user/karper1/library).
I have a significant portion of my music library rated on a five-star scale in Amarok.
I continue to generate and save music listening statistics and would love to have my music player show that information in interesting ways.
But right now, I have no way to do that... unless I write my own.

# Quo vadis?

In the following series, I'll document my way through building a music player that does things I want it to do.
I'll try to use the Amarok and other music players' code bases as study material.
I'll start at the very bottom with basic know-how of C++ and Qt and attempt to build my way through various components of a music player.
I hope that this will culminate in something good.
And if I fail, well that's good learning too.

In the next post, I'll outline the features I want to implement in the as-yet-unnamed music player.

