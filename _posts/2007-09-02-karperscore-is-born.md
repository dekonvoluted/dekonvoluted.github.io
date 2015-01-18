---
title: KarperScore is born!
layout: post
series: karperscore
categories: [ project KDE ]
tags: [ amarok, ruby ]
comments: true
---

> This article refers to deprecated software and methods.
> It is presented here for archival purposes only.

# Problem Background

[Amarok](http://amarok.kde.org/) is the music player of choice for the millions (?) of music loving people who use Linux.
As one of the flagship KDE apps, it has a legion of followers who believe that there could be no better music player, except of course, for the [next release](http://dot.kde.org/1173761811/).

Using Amarok, it is possible to let the computer automatically rate your music and assign a "score" in addition to the rating you provide.
You, the user, rate a particular song by assigning it 0 to 5 stars, in steps of ½ stars.
Using parameters like playcount, current score, percentage of song played etc, the computer calculates what the score the song should get.

The default scoring script does this (from [Amarok Wiki FAQ](http://amarok.kde.org/wiki/FAQ#How_are_track_scores_determined.3F)):

{% highlight ruby %}
if( playcount <= 0 ) # not supposed to be less, but what the hell.
  newscore = ( prevscore + percentage ) / 2
else
  newscore = ( ( prevscore * playcount ) + percentage ) / ( playcount + 1 )
end
{% endhighlight %}

Now, this is a perfectly nice script and works fine.
However, I feel that the point of running a score script is to allow the computer to judge how much you like the song.
The `percentage` variable is a pain in the ass.
For one, I'm scared to browse through a bunch of songs by listening to a bit of each.
Because the score depends on how much of the song I listen to, if I skip too early, it drastically reduces the score of even my favorite songs, just because I didn't listen to it completely.
Also, I don't want to shoo people away from my comp if they want to listen to just a bit of some song.
The only workable solution to this is to use the seek bar and click near the end of the current song.
That would make the player think I've listened to the entire song.

# Solution

So, I decided to write up a new script that addresses my issue.
I feel that the score should tend towards my rating if I provide one.
If I didn't it merely goes by how many times I've listened to the song.
The only way the score would decrease is if I rated the song lower than the current score.
Even then, over subsequent plays, it should tend to my (new) rating.

I needed to set up an infinite series that tends towards the `rating` variable.
Simple.
Keep taking the average of the rating and the score.
Here's my algorithm:

{% highlight ruby %}
if( rating < 1 )
  rating = 10
end
if( playcount <= 0 )
  prevscore = 0
end
newscore = ( 5 * rating ) + ( prevscore / 2 )
{% endhighlight %}

First, the code checks if you have a rating (using `dcop`).
If you haven't rated the song, the `rating` is 0 and it targets 10.
If you did rate the song, it'll target your rating.
The rating stored by Amarok is twice the number of stars.
Thus, a song rated, say 3½ stars will result in a rating of 7.
To scale it to 100, I need to multiply it by 10 and take an average with the `prevscore`.
That's why it's multiplied by 5.
The `prevscore` is the current score of the song.
If it's being played for the first time, I've explicitly made it equal 0.
I wasn't sure if the default score was 0 or 50.
Half of this counts towards the new score.

Some friendly, if [cryptic instructions](http://amarok.kde.org/wiki/Script-Writing_HowTo_1.4) from the Amarok website got me started.
Since this was my first script (and in [Ruby](http://www.ruby-lang.org/en/), too!), I used the default scoring script itself as a template in order to make sure I got the syntax right.
The default script is stored at `/usr/share/apps/amarok/scripts`, just like my installed scripts will land up in `~/.kde/share/apps/amarok/scripts`.
Anyway, I prepped the tar ball just like [the Amarok webpage](http://amarok.kde.org/wiki/Script-Writing_HowTo_1.4#Packaging) instructed and launched it on [kde-apps.org](http://www.kde-apps.org/content/show.php?content=65466).

Hope some of you will try it out.
Let me know what you think!

## Update

Because of where I was issuing a `dcop`, the script was using the *next* song's rating instead of the current song's.
How painful!
The code has been fixed and updated to v1.1.
Now it works as nicely as it should :)

