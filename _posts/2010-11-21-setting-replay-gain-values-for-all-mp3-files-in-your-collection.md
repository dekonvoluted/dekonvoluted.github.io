---
title: Setting replay gain values for all mp3 files in your collection
layout: post
categories: [ user guides ]
tags: [ mp3gain, replay gain ]
comments: true
---

I have all my files stored in my music directory in this structure:

    Artist/Album/Song.mp3

I need them to be normalized by embedding replay gain values into their ID3 tags.
The replay gain values tell the music player to increase or decrease the loudness of a song.
The net effect is that all the songs in the collection sound about the same volume.
So, I don't need to fiddle with my system volume setting when a loud song comes up next.

# Solution

I can locate all the mp3 files using the find command.
To apply normalization, I'll use the `mp3gain` package.

# find

First, I switch to the Music directory to limit my searches to my music collection only.
I'll use find to give me a list of the album directories.
I'll use this list in a script later.

    cd Music/
    find . -mindepth 2 -type d -execdir /path/to/applyreplaygain.sh {} \;

`-mindepth 2` looks two levels deep into the directory structure.
`-type d` finds directories.
`-execdir` executes the following command from the directory containing the album directory (instead of from the top level directory).
`{}` is a stand in for the name of the album directory.

At first, I tried using the following command:

    find . -mindepth 2 -type d -execdir mp3gain -p -a -k -s i -o {}/*.mp3 \;

But, it didn't work because it wouldn't let me use the `*` wild card to match all mp3 files in that directory.
Further, it would cause havoc every time it encountered a directory name with spaces in it.
So, I decided to wrap the `mp3gain` command in a script.

# mp3gain

Using `mp3gain is relatively simple.
The command, with the options I want is as follows:

    mp3gain -p -a -k -s i -o *.mp3

`-p` preserves the original time stamp of the file.
`-a` applies album gain so that all songs in an album sound relatively the same with respect to each other.
The album on average sounds the same as the rest of the collection.
`-k` prevents clipping by lowering the gain value.
`-s i` writes the tags to the file in the form of ID3v2 tags.
`-o` shows the output in a tab delimited list.

Wrapping this in a simple script, called applyreplaygain.sh, I get

{% highlight bash lineanchors %}
#!/bin/bash
mp3gain -p -a -k -s i -o "$1"/*.mp3
{% endhighlight %}

The quotes around the first argument ($1) protect spaces in the name of the directory.

# Results

Now, to put it all together,

    cd Music/
    find . -mindepth 2 -type d -execdir /path/to/applyreplaygain.sh {} \;

This will trawl through each album directory and normalize all the mp3 files found within.
Each album is treated as a separate unit and the replay gain values will keep the relative loudness of the album intact.
The procedure will take several hours to complete (depending on the size of your collection).

Almost all music players respect replay gain and therefore, this will be instantaneously noticeable once the tags are written---I've noticed the loudness change in mid-play if the song is being played on any of the phonon-based music players in KDE (Dragon Player, Amarok, etc).

Since no changes have been made to the music file itself, it's technically possible to undo all this.
`mp3gain` provides the `-s d` option to delete the embedded normalization tags.
I've not seen it work too well, though.
So, I would suggesting using kid3 to manually delete the volume normalization tags from the mp3 files.
It's not an automated solution and will take time to delete the tags manually from every file in your collection.
However, I don't see why you would want to undo this in the first place!

