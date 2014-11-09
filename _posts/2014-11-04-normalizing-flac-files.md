---
title: Normalizing FLAC files
layout: post
categories: [user guides]
tags: [bash, flac, metaflac, replay gain]
---

> This is now part of a series of posts.
> The updates are as follows.

> [Normalizing FLAC files - With Ruby - Part I]( {% post_url 2014-11-08-normalizing-flac-files-with-ruby-part-i %} )

> [Normalizing FLAC files - With Ruby - Part II]( {% post_url 2014-11-09-normalizing-flac-files-with-ruby-part-ii %} )

I converted my music collection to FLAC sometime in 2011.
Prior to that, my collection was encoded in the MP3 format.
However, upon realizing that lossless audio is obviously the best way to store music, I rebuilt my music collection from source (audio CDs).
The ripping, and tagging steps are topics for blog posts in their own right, but this one's about the final step, the normalization.

After I've completed tagging a fresh batch of FLAC files, they are in a directory structure like this,

    Artist/
    └── YYYY - Album/
        ├── 01 - Track.flac
        ├── 02 - Track.flac
        ├── 03 - Track.flac
        ├── 04 - Track.flac
        └── album.jpg

The artist may have multiple albums and albums have multiple tracks.
An album may be incomplete, in which case, I leave out the track numbers.
It may also not have a good album cover, in which case, the album.jpg may not be present.
This album art, by the way, is also embedded into the Vorbis tag.

I also use this opportunity to re-encode the music file.
This is because these FLAC files don't always come from audio CDs and I want to get rid of any non-standard tags, etc.

### Re-encoding

To reencode a FLAC file, one would call the `flac` command like this,

{% highlight bash linenos %}
flac --silent --force foo.flac
{% endhighlight %}

This will quietly decode and encode the FLAC file in place.
However, every once in a while, you might come across a FLAC file that has an ID3 tag.
In that case, you'll get an error like this,

    ERROR: input file foo.flac has an ID3v2 tag

If that happens, we need to follow a different route.
First, let's decode the FLAC data into a WAV file like this,

{% highlight bash linenos %}
flac --silent --decode --output-name=foo.wav foo.flac
{% endhighlight %}

Next, we need to save the Vorbis tag information in the file.
To do this, we'll export the tags to a text file.

{% highlight bash linenos %}
metaflac --export-tags-to=foo.ini foo.flac
{% endhighlight %}

The contents of this exported file look something like this,

{% highlight ini linenos %}
TITLE=The Title
ARTIST=The Artist
ALBUM=The Album
GENRE=TheGenre
TRACKNUMBER=1
DATE=1999
{% endhighlight %}

Now, we need to encode the WAV file back into FLAC.

{% highlight bash linenos %}
flac --silent --output-name=bar.flac foo.wav
{% endhighlight %}

And reapply the tags back to the fresh FLAC file.

{% highlight bash linenos %}
metaflac --import-tags-from=foo.ini bar.flac
{% endhighlight %}

Let's put this into a nice bash function.
This forms the inner-most function of our script and is called only when absolutely necessary.

{% highlight bash linenos %}
reencode()
{
    echo "Removing ID3 tags."

    # Decode and extract metadata to temporary location
    TMP=$(mktemp --directory)
    cp "${1}" $TMP/original.flac
    flac --silent --decode --output-name=$TMP/original.wav $TMP/original.flac
    metaflac --export-tags-to=$TMP/metadata.ini $TMP/original.flac

    # Reencode and import metadata from original file
    flac --silent --output-name="${1}" $TMP/original.wav
    metaflac --import-tags-from=$TMP/metadata.ini "${1}"

    # Embed album art, if found
    DIR=$(dirname "${1}")
    [[ -f "${DIR}"/album.jpg ]] && metaflac --import-picture-from="${DIR}"/album.jpg "${1}"

    # Recalculate replay gain
    metaflac --remove-replay-gaini "${1}"
    metaflac --add-replay-gain "${1}"

    # Clean up temporary files
    rm --recursive --force $TMP
}
{% endhighlight %}

### Normalizing

This represents the "normal" code-path.
The input to this function is a FLAC file.
The function must try to do some clean up and apply a replay gain value.
If it encounters an error, it will call the `reencode()` function to clean up the file.

{% highlight bash linenos %}
normalize()
{
    # Check if the file is a FLAC file
    if [[ "${1}" != *.flac ]]
    then
        return
    fi

    # Avoid following links
    if [ -h "${1}" ]
    then
        echo Avoiding link "${1}"
    fi

    # Reencode and normalize
    flac --silent --force "${1}"
    if [[ $? -ne 0 ]]
    then
        reencode "${1}"
    else
        metaflac --preserve-mod-time --add-replay-gain "{1}" || echo -n "Replay gain error: "
    fi

    echo $(basename "${1}")
}
{% endhighlight %}

Next, we need a recursive function that will dig into directories and call `normalize()` on every FLAC file it encounters.
For added awesomeness, we can fork off multiple `normalize()` calls and wait for all of them to finish before moving to another directory level.

{% highlight bash linenos %}
processDir()
{
    echo $(basename "${1}")/

    # Recurse into directory
    for content in "${1}"/*
    do
        if [ -f "${content}" ]
        then
            normalize "${content}" &
        elif [ -d "${content}" ]
        then
            # Act only on regular directories
            if [ -h "${content}" ]
            then
                echo "Avoiding link "${content}"
            else
                processDir "${content}"
            fi
        fi
    done

    # Wait for all files in current directory to be processed before moving on
    wait
}
{% endhighlight %}

Now, we just need wrapper functions around these three main functions and we have a script.
At this point, we have to use `getopts` and encounter the familiar problem with bash scripts that don't use their own argument parser: we can either take one argument with spaces in it, or take multiple arguments without spaces in them.
For this case, accepting a single argument is not a bad way to go, but this limitation does mean that this script is a prime candidate to be rewritten in ruby or python.

{% highlight bash linenos %}

readonly PROGNAME=$(basename $0)
readonly ARGS="$@"

process()
{
    local ARG=$(realpath "${1}")

    if [ -f "${ARG}" ]
    then
        normalize "${ARG}"
    elif [ -d "${ARG}" ]
    then
        processDir "${ARG}"
    else
        exit 1
    fi
}

main()
{
    args=$(getopt --name ${PROGNAME} --options "h" --longoptions "help" -- ${ARGS})

    [ $? -eq 0 ] || exit 1

    eval set -- "${args}"

    while test $# -gt 0
    do
        case "${1}" in
            -h|--help)
                printUsage
                exit 0;;
            --)
                shift
                break;;
            *)
                shift
                break;;
        esac
        shift
    done

    if [ $# -eq 0 ]
    then
        process "./"
    else
        process "$*"
    fi
}

main "$@"

exit 0
{% endhighlight %}

Put it all together and we have a script that will reencode and normalize one or more FLAC files.
I typically run it on the Artist or Album directory and have it clean up all the FLAC files inside.

The code is maintained in [this repository](https://github.com/dekonvoluted/normalizeFLAC).
As usual, feel free to use, modify and pass on.

