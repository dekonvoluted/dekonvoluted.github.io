---
title: Good morning, Dave.
layout: post
categories: [ user guides ]
tags: [ espeak, festival, jovie, speech-dispatcher ]
comments: true
---

This post has rather little to do with HAL or 2001.
It has, however, quite a bit to do with talking computers; [Jovie](http://www.kde.org/applications/utilities/jovie/), the KDE text to speech subsystem, in particular.
Apart from its obvious use as an accessibility tool, it is just too cool to have your computer speak to you.
If you're convinced, read on.

Jovie began its life as kttsd/kttsmgr (KDE Text To Speech Daemon/Manager) in the early days of the 4.x series.
It is still officially under development, but it works pretty well.
Applications like Konqueror, Okular, Kate (Enable Jovie in Plugins), and the clock in Plasma all have built in Jovie functionality.
Jovie's system tray icon also offers a popup menu which you can use to read out your clipboard contents.

Jovie is a three-tiered subsystem.
At the top level, Jovie interfaces with the kde applications.
At the next level, Jovie uses an abstraction layer called Speech-Dispatcher to talk to text-to-speech programs.
At the lowest level, the text-to-speech program converts text into speech.
In theory, this splits up the interfacing.
All KDE programs talk to Jovie and all text-to-speech programs interface with Speech-Dispatcher.
Jovie simply needs to connect to Speech-Dispatcher.

So, this post will walk you through a quick set up of Jovie.
Let's begin.

# Text-to-Speech program

Jovie claims that it can currently work with two text-to-speech programs as its backend.
These are [espeak](http://espeak.sourceforge.net/) and [festival](http://www.cstr.ed.ac.uk/projects/festival/).
Espeak is a tiny program that is very easy to set up with Jovie.
The speech quality is not all that great.
The voice warbles a bit and sometimes, it sounds like two people are taking turns pronouncing words.
Festival, on the other hand is a much bigger program and the voice quality is more natural sounding compared to espeak.
However, the setup is more convoluted.
You only need one backend, but it won't hurt to set both up.
The choice is yours.

> As of 4.9.3, Jovie does not work with festival.
> Still, the festival setup (which ultimately ends in failure) procedure is documented here.
> If you're an intrepid adventurer from the future who got it working with Jovie, let me know and I'll update this post accordingly.

## Espeak

Find the `espeak` package and install it.
Test it by typing the following in a terminal.

    $ espeak "hello world"

It should just work™.

## Festival

Festival is a much larger program and in addition to the `festival` package, you also need to install voice packages.
For english speakers, there are two packages of interest: `festival-english which adds a British male voice and `festival-us` which adds American male and female voices.

Testing festival is also slightly more complicated.
The `festival` command spawns a shell and expects commands.
So, if you want it to speak something, you need to pass it with the `--tts` option.

    $ echo "hello world" | festival --tts

If you simply typed `festival` into a terminal and got stuck in its shell, type `(quit)` or press Ctrl+D to exit the festival shell.
 The first time you try it, you'll almost certainly get this error:

    Linux: can't open /dev/dsp

This is because you use Pulseaudio.
Don't worry, you can tell festival to use Pulseaudio by adding the following lines in your `~/.festivalrc` file (create one if it doesn't exist).
If you want this to be system-wide, you may add it to `/usr/share/festival/festival.scm.`

{% highlight text %}
(Parameter.set 'Audio_Required_Format 'aiff)
(Parameter.set 'Audio_Method 'Audio_Command)
(Parameter.set 'Audio_Command "paplay $FILE")
{% endhighlight %}

Test it.
Make sure it works.
Now, you're ready for the next step.

# Speech-Dispatcher

If you balked at the extra configuration needed to get festival to work in the previous step, I have good news for you.
This step is significantly simpler.

Install the `speech-dispatcher` package to begin.
Now, speech-dispatcher needs to be configured, but you don't have to write the config file yourself.
Instead, use the included `spd-conf` program to write it out for you.
Run it in a terminal.

## Espeak

Your session may look something like this.

    $ spd-conf
    Speech Dispatcher configuration tool

    Do you want to setup a completely new configuration? [yes] :
    >
    Do you want to create/setup a 'user' or 'system' configuration [user] :
    >
    User configuration already exists.
    Do you want to rewrite it with a new one? [no] :
    >yes
    User configuration created in /home/karthikp/.speech-dispatcher/conf
    Configuring user settings for Speech Dispatcher
    Default output module [espeak] :
    >
    Default language (two-letter iso language code like "en" or "cs") [en] :
    >
    Default audio output method [pulse] :
    >
    Default speech rate (on the scale of -100..100, 0 is default, 50 is faster, -50 is slower) [0] :
    >
    Default speech pitch (on the scale of -100..100, 0 is default, 50 is higher, -50 is lower) [0] :
    >
    Do you want to have Speech Dispatcher automatically started from ~/.config/autostart ?
    This is usually not necessary, most applications will start Speech Dispatcher automatically. [no] :
    >
    Do you want to start/restart Speech Dispatcher now and run some tests? [yes] :
    >
    Starting Speech Dispatcher in user-mode
    [Sun Nov 25 14:49:11 2012 : 360348] speechd: Speech Dispatcher 0.7.1 starting
    [Sun Nov 25 14:49:11 2012 : 360443] speechd: Speech Dispatcher already running.

    Speech Dispatcher already running.

    Can't start Speech Dispatcher. Exited with status 256
    Perhaps this is because your Speech Dispatcher is already running.
    Do you want to kill all running Speech Dispatchers and try again? [yes] :
    >
    [Sun Nov 25 14:49:18 2012 : 862875] speechd: Speech Dispatcher 0.7.1 starting
    Testing Speech Dispatcher using spd_say
    Did you hear the message about Speech Dispatcher working? [yes] :
    >
    Speech Dispatcher is installed and working!
    Speech Dispatcher works. Do you want to skip other tests? [yes] :
    >


    Diagnostics results:
    Speech Dispatcher is working
    End of diagnostics results

Notice that *most* of the time, the default answer is what you need, so you can simply press enter and continue.
If the test was successful, you should have heard a voice say "Speech-Dispatcher is working".
That's it.
If you're curious, you can read the configuration file it produced in `~/.speech-dispatcher/conf/speechd.conf`.

Speech-Dispatcher provides the `spd-say` command that uses whatever default you picked to say things.
Go ahead and play with it, if you like.
We're almost done now.

    $ spd-say "hello world"

Finally, relaunch speech-dispatcher by killing any running instance and launching it explicitly in daemon mode.

    $ killall speech-dispatcher
    $ speech-dispatcher -d

I'm not fully sure why this step is needed, but without doing so, Jovie can't seem to talk to it properly (and you have to hear a *long*, spoken error message when you ask Jovie to say anything.

## Festival

First run `spd-conf` in a terminal and configure Speech-Dispatcher.
Pay attention to the question regarding the output module.
Instead of espeak, enter festival.
The rest should be uneventful.
Don't worry if the test at the end fails.
Say yes anyway and exit.

The test fails because Speech-Dispatcher connects to the Festival program somewhat differently.
First, kill any running Speech-Dispatcher processes.

    $ killall speech-dispatcher

Next, start Festival in server mode.

    $ festival --server

Now, start Speech-Dispatcher.

    $ speech-dispatcher -d

The Speech-Dispatcher daemon will connect to the Festival server.
Now, you can test the system as before.

    $ spd-say "hello world"

Now, you're ready to go to the next step.

# Jovie

First, make sure Jovie isn't running already—look for the icon in the system tray and right-click and quit it if you find one.
Now, you can either use krunner to launch `jovie` or go to System Settings > Accessibility > Text-To-Speech.
You'll see that the control module has four tabs, General, Talkers, Filters and Jobs.
In General, enable the Jovie system.
A system tray icon should immediately appear.

Next, in the Talkers tab, Add a talker.
You should get a list of Espeak and/or Festival talkers.

Here's where the Festival set up will fail.
Jovie will always say it is an invalid voice.
Testing it will cause Speech-Dispatcher to read out a lengthy error message, "This is the dummy output module. It seems your speech-dispatcher is working, but there is no output module, except me...".

Select an Espeak voice.
Note that that you can configure the type of voice and adjust some attributes, too.
I suggest the Female 2 voice as it sounded the most natural of all the voices to my ears.
You need to name your speaker (perhaps after your hostname?) before you can add him/her as a talker.

The Filters tab lets you set up rules like replacing one word for another, or select talkers based on what it's suppose to be reading out, etc.
Not our concern right now.
Proceed to the Jobs tab.
In the Jobs tab, we'll test Jovie.
Select something you want Jovie to say like,

    Hello World! This is Jovie.

and have it copied in your clipboard.
Now, you can just click Speak Clipboard to have Jovie read it out.
If it works, you're done.

Or you're just getting started, depending on how you look at it.
I will give you one idea of what you can do with Jovie.
Yes, in addition to having your browser (konqueror), text editor (kate), panel clock and PDF reader (okular) read out things.
If you go to System Settings and look under Application and System Notifications, you'll realize that you can have Jovie say custom messages when events happen.
And you can do this for any KDE application.
Want your computer to announce desktop changes?
You can.
When a USB stick is plugged in?
You can.
How about announcing Login/Logout events, by greeting you HAL-style?
Now you're talking... almost.
Turns out that during logout, the system is in such a hurry to exit that either Jovie or Speech-Dispatcher gets killed too early.
As a result, you get the all-too-familiar error message from Speech-Dispatcher whining about missing output modules.
So, everything but logout, then.

# Closing thoughts

One last thing.
If Jovie crashes or repeats the error about missing Speech-Dispatcher modules, restart Speech-Dispatcher.

    $ killall speech-dispatcher
    $ speech-dispatcher -d

