---
title: Automatically disable touchpad while typing
layout: post
categories: [ user guides ]
tags: [ synaptics ]
comments: true
---

Here's something useful for when you have to use a laptop with an ultra-sensitive touchpad.
Specifically, for when you want to type without the touchpad triggering from your palms and placing the cursor all over the place as you're typing a long paragraph.
What you could really use is a service that would automatically detect typing and disable the touchpad and re-enable it when the typing stops.
Now, there are three options to try out.

The first is to enable palm detection by the synaptics driver itself.
Whenever you want to change something here, the best practice is to call `synclient` first, make a note of the initial value of a variable you want to change, change that variable by calling `synclient variable=new_value` and if it works, make it permanent by adding a configuration file in `/etc/X11/xorg.conf.d`.
In this case, the variables to play with are `PalmDetect`, `PalmMinWidth` and `PalmMinZ`.
On my EEEPC, enabling `PalmDetect` did nothing and I didn't want to spend time tweaking `PalmMinWidth` and `PalmMinZ`.

The next option is to use the control module for the touchpad.
The `kcm-touchpad` packages gets the touchpad control module and it exposes all the options from synclient.
Unfortunately, the "Enable/Disable touchpad" tab was grayed out for me.

Enter `syndaemon` from the `synaptics` package.
Despite what its name suggests, `syndaemon` runs in the foreground by default and will need to be called with the `-d` option to run in the background.
It polls the keyboard every 200 ms (changeable using `-m`) and detects typing when any key is pressed.
You can ignore the times you press modifier keys like `Alt`, `Shift`, etc. when you pass the `-k` option.
You can further ignore the times you press key combinations involving those modifier keys if you pass the `-K` option.
On the touchpad side, it can either be completely disabled, or can be restricted to only moving the mouse (but tapping and gestures like scrolling will still stay disabled) if you use the `-t` option.
Finally, you can decide how long you want to wait after the typing has ceased before re-enabling the touchpad.
The default wait is 2 seconds, but can be changed with the `-i` parameter.
I recommend using it with the options, `-tdk`.

{% highlight console %}
$ syndaemon -tdk
{% endhighlight %}

Now, the next thing to do is to automatically have it launched for you when you log in.
Putting it in `~/.bashrc` is a bad idea as this file is sourced even when you connect over `ssh`.
Putting it in `~/.xinitrc` would work if you use `startx` to start your X session.
If you use `kdm`, instead, the best place to put this is in `~/.xprofile` which is sourced by `kdm`.
So, create the file if it doesn't exist and add this line there and you're all set.

