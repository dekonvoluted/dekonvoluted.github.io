---
title: Goodbye CDparanoia, hello Icedax!
layout: post
categories: [ user guides ]
tags: [ cdparanoia, icedax ]
comments: true
---

I had a simple task to complete today.
I had to digitize a few CDs into flac files.
I had been putting this off for so long that I wanted to get this over with.

Fortunately, KDE provides the `audiocd:/` kioslave for this very purpose.
What this does is actually pretty cool.
Instead of showing the actual cdda files on a CD, it shows a bunch of virtual files and folders.
It performs a CDDB lookup, gets the track names and other metadata and tries to make encoding invisible.
The virtual files are WAV files, which you can drag and drop as if they were real.
The copying process instead ends up ripping the CD.
Each of the folders represents one of the encoders you have available, all configurable in system settings.
You could just drag drop an entire folder, or individual songs from the folder and the song will be transcoded magically for you.
It all looks something like this:

![audiocd](/images/audiocd.png)

In theory, this should make for a very pleasant experience.
However, in practice, I encountered several bugs.
First, the audio CD kioslave needed the package cdparanoia to be installed.
Since this wasn't automatically handled by the package manager, I filed a [bug report](https://bugs.archlinux.org/task/33170) and installed it manually.

Next, for some odd reason, the tenth track of every CD would issue an error saying the flac file wasn't found.
I couldn't figure out why this was happening.
So, since the kioslave was not working perfectly, I decided to do this from the cli.
Here is a simple script to rip flacs from a CD.

{% highlight bash lineanchors %}
#!/bin/bash

TEMP=`mktemp -d`
cd $TEMP

cdparanoia -B -s
for file in *.cdda.wav
do
  flac "$file" --delete-input-file --output-name="${file%.cdda.wav}.flac"
done

rm -f track00.flac

mv $TEMP $HOME/Desktop/kcdrip$$

exit 0
{% endhighlight %}

This simple script copies over the CD contents as wav files to a temporary location, uses the flac encoder to produce the final flac files and drops the folder in my Desktop directory.
I do need to delete the track00.flac file that it creates for no reason whatsoever, but it works.
Great.

This worked pretty well, until I hit my <i>Wednesday Night, 3 AM</i> album.
Now, `cdparanoia` simply refused to read from the CD, giving an output as shown below.

    cdparanoia III release 10.2 (September 11, 2008)

    Ripping from sector       0 (track  1 [0:00.00])
            to sector  182759 (track 15 [2:46.57])

    outputting to track01.cdda.wav

     (== PROGRESS == [                  +++VV| 012679 00 ] == :^D * ==)

The progress bar shows several errors towards the end of the first track.
Normally, this shouldn't be cause for too much undue concern, but for the following reasons.

- First, my CD is in pristine condition.
    There's not a single scratch on the surface.
    The source of these errors is mystifying.
- Second, it took about two hours to copy the first track alone.
    Yes, really.
- Finally, vlc had no trouble playing the first track.

The same issue repeated for the second track, too, with even more errors detected by cdparanoia.
I spent the better part of an afternoon and barely had anything to show for it!
Falling back to the kioslave fared no better.
I still didn't have my flacs.
Digging up the source code on the [project website](https://projects.kde.org/projects/kde/kdemultimedia/audiocd-kio) projects.kde.org revealed that the kdemultimedia-audiocd-kio was using cdparanoia, too.
In hindsight, this is rather obvious.
I just filed a bug about this!

So, as long as the cdparanoia package isn't fixed, my chances of digitizing this CD weren't looking too good.
A bit of googling led to an alternate solution.
The command `icedax` (or its symlink, `cdda2wav`) is provided by the `cdrkit` package.
I tried it and it worked much better than cdparanoia.
It reported zero errors for this CD and in fact, even worked faster than cdparanoia.
The modified version of my simple script is as follows.

{% highlight bash %}
#!/bin/bash

TEMP=`mktemp -d`
cd $TEMP

icedax -D /dev/sr0 -B -s
for file in *.wav
do
  flac "$file" --delete-input-file --output-name="${file%.wav}.flac"
done

rm -f *.inf

mv $TEMP $HOME/Desktop/kcdrip$$

exit 0
{% endhighlight %}

Fixing KDE's audio CD kioslave to use icedax instead of cdparanoia is somewhat beyond my skill level at the moment.
I'm not sure if I should report this as a bug...

