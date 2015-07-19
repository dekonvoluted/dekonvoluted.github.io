---
title: Normalizing FLAC files - with Ruby
subtitle: Part I
layout: post
repo: https://github.com/dekonvoluted/normalizeFLAC
series: normalizing-flac-files
categories: [user guides]
tags: [ruby, flac, metaflac, id3tag, replay gain]
comments: true
---

I wrote about the script I use to normalize and reencode my FLAC files [here]( {% post_url 2014-11-04-normalizing-flac-files %} ).
I noted at the end that one of the issues with using bash scripts, or rather more specifically, with `getopt`, is that it has problems telling the difference between multiple arguments and arguments with spaces in them.
You can get around that using `getopts`, but then you give up `--long-options`.
If there's one thing I try and avoid, it's giving up options.

So, based on that, I concluded that the script is best rewritten in ruby or python.
This weekend, I went ahead and did just that.
The replacement ruby script is coming along pretty nicely.
First, I wrote a class that will handle a single FLAC file.
After checking that the file is real and valid, the script attempts to encode the file in-place.
If this fails---typically due to the presence of an ID3v2 tag---the script proceeds to decode and re-encode the file.
If it succeeded the first time, it just makes sure the replay gain value is correct and moves on.
All this is handled by a single class.

I needed to test the handling of FLAC files with ID3 tags in them.
I know that `kid3`, my tag editor of choice, doesn't show or add ID3 tags, so I'd need to find a file with one of those already present.
Since I'd fixed all the files in my library, I had to sift through my backups.
Sadly, my backups go only as far back as January 2014 and I'd fixed this issue in February 2013.
Damn!
I trawled the nets to see if I could find a FLAC file that had an intact ID3 tag.
After wasting far too much time doing this, I found out that simulating this using the `id3tag` utility is dead-easy.

    id3tag --v2tag --artist=TEST foo.flac

That's it.
`foo.flac` is now a FLAC file with an ID3v2 tag and `flac` will choke on it and trigger the re-encoding logic.

Here's what this class looks like at the moment:

{% highlight ruby lineanchors %}
# Normalize a single FLAC file
class FlacFile
    def initialize filePath
        if File.file?( filePath )
            if File.extname( filePath ) == ".flac"
                @filePath = File.absolute_path( filePath )
                @baseName = File.basename( @filePath )
                puts @baseName
                @dirName = File.dirname( @filePath )
                @albumArt = File.file?( "#{@dirName}" + "/album.jpg" )
                @validFile = true
                %x( flac --silent --test "#{@filePath}" )
                if $?.exitstatus != 0
                    @validFile = false
                end
            end
        end
    end

    # Normalize FLAC files
    def normalize
        return if not @validFile

        %x( flac --silent --force "#{@filePath}" )
        if $?.exitstatus != 0
            reencode
        else
            %x( metaflac --preserve-modtime --add-replay-gain "#{@filePath}" )
            if $?.exitstatus != 0
                puts "Replay gain error."
            end
        end
    end

    # Reencode FLAC files
    def reencode
        puts "Removing ID3 tags."

        Dir.mktmpdir { |tmpDir|
            FileUtils.cd( tmpDir ) do
                FileUtils.cp( @filePath, "original.flac" )

                # Decode file
                # Export tags
                %x( flac --silent --decode --output-name=original.wav original.flac )
                %x( metaflac --export-tags-to=metadata.ini original.flac )

                # Encode file
                # Import tags
                %x( flac --silent --force --output-name="#{@filePath}" original.wav )
                %x( metaflac --import-tags-from=metadata.ini "#{@filePath}" )
            end

            # Embed album art, if found
            if @albumArt
                %x( metaflac --import-picture-from="#{@dirName}/album.jpg" "#{@filePath}" )
            end

            # Calculate replay gain
            %x( metaflac --add-replay-gain "#{@filePath}" )
        }
    end
    private :reencode
end
{% endhighlight %}

There are some nice things to note at this stage.
First, this script will check for valid FLAC files using the `--test` option of the `flac` utility.
Only if a file is valid will it try to normalize it.
Next, the blocks written with `mktmpdir` (requires `tmpdir`) and `cd` mean that at the end of the block, the temporary directory is cleaned up automatically and the current directory is also returned.
This, I find really convenient about ruby blocks.
Lastly, I've made the reencode function private to the class so it can't be called from outside.
As a C++ person, having access modifiers within classes in ruby  makes me feel right at home.

Looking forward to writing the directory/file processing bits next!
The code is in the development branch of [this repository](https://github.com/dekonvoluted/normalizeFLAC) alongside the original bash script.

