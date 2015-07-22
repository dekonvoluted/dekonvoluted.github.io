---
title: Manipulating subtitles
layout: post
categories: [user guides]
tags: [dvd, bluray, srt, encoding, utf8, iconv, dos2unix, srttool, mkvtoolnix]
comments: true
---

Subtitles for movies come in a variety of formats.
On DVDs, they are stored in the VobSub (idx/sub) format, while on blurays, they are stored in the PGS format.
Both of these are basically just images of text that are displayed on top of the video stream at specified times.
A far more portable and readily modifiable format to store subtitles is the SubRip (srt) format.
This is basically text with optional html-style markup, making it very easy to store, use and update in case you find a mistake.
Most media players, including `mplayer` and `vlc` will automatically display subtitles if they are in the same directory as a video file and have the same base name.

This post is about manipulating subtitles you already have.
You can always get SRT files for your language, of varying but generally good quality, directly from sites like [Subscene](http://www.subscene.com) or [Open Subtitles](http://www.opensubtitles.org/en/search).
The usual disclaimer about doing this only with media you own applies.

# The format of an SRT file

A sample entry in this format looks like this,

{% highlight text %}
23
00:01:23,234 -> 00:01:26,758
Your mother was a hamster
and your father smelt of elderberries!
{% endhighlight %}

The first line is the index of the subtitle, marking this as the 23rd block.
The second line specifies the start time and the end time for this dialog to be shown on the screen.
This dialog will be shown a little after a minute and will appear for about three seconds.
The format for each time entry is hours, minutes, seconds followed by milliseconds.
Following these two lines, one or more lines of text is shown.
An empty line separates one block from another.

# Things that can go wrong

Since you're probably going to get this SRT file off the internet, there are a few things that can go wrong.
The file could be encoded wrong, have CR/LF markers (they show up as `^M` when opened in `vim`, for example), could be offset by a time difference compared to your video or could be for the wrong frame rate and will drift ahead or lag behind as the movie progresses.
All are irritating and all are solvable.

# Fixing encoding issues

This issue is particularly noticeable when you have accented characters in the subtitles.
Accented characters outside of the ASCII character set can have different representations in different encodings.
Now, the primary cause of this is Windows using ISO-8859 as the default locale.
However, most sane machines use UTF-8 as their locale and when opening a file from a Windows-using uploaded will show weird symbols instead of the accented characters.

To fix this, we need to convert the encoding to UTF-8.
First, check the encoding of the file with the `file` command.
If it returns `us-ascii` or `utf-8` you're okay.

    $ file --mime-encoding --brief subtitles.srt
    iso-8859-1

Unfortunately, this one doesn't.
So, we must use a utility like `iconv` to convert the encoding to UTF-8.
`iconv` writes its output to the console, so it must be redirected to a file to capture it.
Do NOT redirect it to the same file---it will cause the file to be cleared before it can be read.

    $ iconv -c --from-code=iso-8859-1 --to-code=utf8 subtitles.srt > fixed-subtitles.srt

Incidentally, the `-c` option tells `iconv` to carry on till it reaches the end of the file and not stop when it encounters a character that is invalid in the final encoding.
It doesn't have a long form.

# Fixing line termination issues

This is a very common problem for files originating from a Windows machine or older macs and is not just limited to subtitle files.
Windows machines typically use `\r\n` as the line termination characters, while older macs used to use only `\r`.
For reference, sane systems (pretty much everything but Windows today) use only `\n` (= LF) to terminate a line.
As usual, [Wikipedia](http://en.wikipedia.org/wiki/Newline) has a definitive writeup on this issue.

Calling `file` on these files will quickly spot the problem for you.

    $ file subtitles.srt
    subtitles.srt: ASCII text, with CRLF line terminators

Since I have errant `\r` (=CR) characters all over the place, I would use `tr` to truncate these characters.

    $ tr -d '\r' < subtitles.srt > fixed-subtitles.srt

If the file only had CR line terminators, I would have substituted the `\r` with `\n` characters.

    $ tr '\r' '\n' < subtitles.srt > fixed-subtitles.srt

Note that the input is from the `stdin` and the output is to `stdout`, so it needs to be redirected to another file.
If you want a utility that would do this in-place, you could use `dos2unix` for the first case.

    $ dos2unix subtitles.srt

# Fixing delay issues

When subtitles are out of sync with the video, they appear too early or too late.
Delays of 250 ms and above are very easily noticeable by most people.
Similarly, delays less than 100 ms are usually not easily perceived by most people.
So, the idea is to use trial and error and get the relative delay to something that's not perceivable.

The relevant controls for `mplayer` as as follows.
Using "O" toggles the display of an on-screen timer, accurate to seconds.
Using "X" and "Z" adjusts the subtitle delay by 100 ms in opposite directions.
Use the first subtitled dialog for determining this delay as precisely as you can.

Once you have a value you want to try, use `srttool` from the `transcode` package for this.
Let's say we have a case where the subtitles appear 3800 ms before when they should (according to the video).

    $ srttool -d 3.8 -i subtitles.srt -o fixed-subtitles.srt

Verify that there is no perceptible delay between the video and the subtitle.
If there is, repeat this step again till you're satisfied.

One of the nice things that `srttool` does is renumber the entries.
Entries could be out of sequence if you remove any leading or trailing subtitles that identify the website or the translator.
While adjusting the delay, you could just slip in a `-r` option to have `srttool` renumber the entries correctly.

# Fixing frame rate issues

There are several [standard frame rates](http://en.wikipedia.org/wiki/Frame_rate#Digital_video_and_television) that you could encounter.
Most movies are shot at 24 frames per second.
When using the NTSC format, this will usually be presented at 24000/1001 frames per second as this cleanly matches the 30000/1001 frames per second NTSC frame rate when [pulled down](http://en.wikipedia.org/wiki/Three-two_pull_down).
Similarly, the PAL format uses 25 frames per second.

Begin by syncing the first dialog as described in the previous section.
Now, skip to the end of the video and check if the sync is preserved.
If it is noticeably worse than the sync at the beginning of the subtitle file, you probably have a frame rate issue.

Record (approximately) the times of the first dialog and the last dialog from the video.
Let's say the first dialog happens about 60.5 seconds into the video and the last dialog is at 2425 seconds.
Compare this to what you see in the subtitles file.
Since you synced the first subtitle, they should be pretty close.
In this case, say, the subtitle file says 00:01:00,256 = 60.256 seconds.
And similarly, the last subtitle is at 00:40:21,232 = 2421.232 seconds.
This duration is a couple of seconds shorter than the video duration and the subtitle shows up too soon by the end of the video.
So, the subtitles must be stretched as they are from a higher frame rate source.

Calculate the ratio with the approximate duration from the video on the numerator and the subtitle duration in the denominator.
Here's where it pays off to be as exact as possible with the video duration.
Typically, an accuracy of 0.5 seconds is easily doable and is sufficient for most purposes.
Our ratio is ( 2425 - 60.5 ) / ( 2421.232 - 60.256 ) = 1.001493...

Typically, the ratio will be very close to one of these values (inexact ratios have a trailing ellipsis):

fps ratios  |               |               |               |               |
:-:         |:-:            |:-:            |:-:            |:-:            |:-:
            | 23.976        | 24.000        | 25.000        | 29.970        | 30.000
23.976      | 1             | 0.999001...   | 0.959041...   | 0.8           | 0.799201...
24.000      | 1.001         | 1             | 0.96          | 0.8008        | 0.8
25.000      | 1.086957...   | 1.041667...   | 1             | 0.834167...   | 0.8333333...
29.970      | 1.25          | 1.248751...   | 1.198801...   | 1             | 0.999001...
30.000      | 1.25125       | 1.25          | 1.2           | 1.001         | 1

Use the column corresponding to the video fps.
Using `mplayer` on the command line will usually output the frame rate along with other data.
In NTSC regions, this is probably going to be 23.976, the first column.
Our ratio is in this column and shows that the source frame rate was probably 24 fps and the subtitles must be stretched by 1.001 to properly sync with our video.

`srttool` supports stretching as long as the subtitle hour doesn't expand or shrink by more than a minute.
This sets a +/-1.6% bound on our ratio (0.983333... to 1.016667...).
If that works, calculate the shrink per hour in seconds, which is just 3600 * | ratio - 1 |.
In our case, it's exactly 3.6 seconds.

    $ srttool -e -3.6 -i subtitles.srt -o fixed-subtitles.srt

As you can see from the table, there are plenty of ratios that don't fit in this narrow bound.
If you have one of those ratios, a better option is to use `mkvmerge` followed by `mkvextract` and let `mkvtoolnix` do all the work for us.
Here's a possible example for a stretch ratio of 1.25.

    $ mkvmerge --quiet --output tempfile.mkv --sync 0:0,1.25 subtitle.srt
    $ mkvextract --quiet tracks tempfile.mkv 0:subtitle.srt
    $ rm tempfile.mkv

The subtitle file is then overwritten with the stretched version.
Now, re-sync the first dialog and the synchronization should be valid across the entire file.

