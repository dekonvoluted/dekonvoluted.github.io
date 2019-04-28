---
title: Redshift your desktop
layout: post
categories: [ user guides ]
tags: [ redshift ]
---

Several years ago, I came across [f.lux](https://justgetflux.com/) which is a tool to change the color temperature of your desktop depending on the local time.
It takes into account your latitude and longitude and transitions the color temperature of your desktop from its default during the day time to a more reddish hue at night.
This is easier on your eyes and doesn't blind you if you work in the dark.

While f.lux is available for Linux, it's not open source.
[Redshift](http://jonls.dk/redshift/) is an open source implementation of this idea and comes as both a command line utility and as a gtk GUI program.

Recently, I decided to start using this tool again on my EEEPC.
First, I install the `redshift` package.
Next, I need my latitude and longitude to start the tool.
You can get this from any number of sources, Marble on your desktop, the Wikipedia article of a nearby city, Google maps, etc.
It doesn't have to be super-accurate and rounding it to the nearest five degrees ought to be good enough.
So, I'll use 45° N, 125° W, is approximately where Portland, OR is.
Testing it out on the console with,

    $ redshift -l 45:-125

reddened my desktop satisfactorily.

The next step is to have this start automatically when I log in.
One could use the gtk GUI that comes with Redshift which places an icon in the system tray or even the [plasma widget](http://kde-apps.org/content/show.php/Redshift+Plasmoid?content=148737) that will integrate better into the KDE plasma desktop.
Or one could simply use the command line tool.
This is what I'll do.
As we saw in an [earlier post]({% post_url 2014-12-29-automatically-disable-touchpad-while-typing %}), the best place to put such services is in `~/.xprofile` which is sourced by the KDM scripts.
However, if you do this, you'll soon discover that the KDE plasma desktop will no longer launch.
You type in your password and ...nothing happens; not even the KDE splash screen shows.
You will be left staring at the background of your login screen with a mouse and little else.
After realizing that my google-fu was entirely incapable of uncovering the reason for this, I opened up `~/.xsession-errors` and found a single line, "Using method `randr'".
This is how I found out that redshift was responsible for the issue.

Redshift does not automatically go into the background and as a result, putting it in `~/.xprofile` causes all other programs, such as the KDE plasma desktop, to wait in line for it to exit before they can start.
So, the fix is simple.

{% highlight console %}
redshift -l 45:-125 &
{% endhighlight %}

The trailing ampersand puts the command in the background and the login proceeds without a hitch.
Now, the desktop will redden at sunset and get back to normal at sunrise.

Incidentally, for android devices, a similar functionality is provided by a closed-source tool called [Twilight](https://play.google.com/store/apps/details?id=com.urbandroid.lux).


