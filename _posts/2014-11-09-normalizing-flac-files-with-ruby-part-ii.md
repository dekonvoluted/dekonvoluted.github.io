---
title: Normalizing FLAC files - with Ruby
subtitle: Part II
layout: post
series: normalizing-flac-files
repo: https://github.com/dekonvoluted/normalizeFLAC
categories: [user guides]
tags: [ruby, flac, metaflac, id3tag, replay gain]
comments: true
---

I like to think of scripts from the inside out.
In the [previous update]( {% post_url 2014-11-08-normalizing-flac-files-with-ruby-part-i %} ), I got the core functionality in place.
The `FlacFile` class can handle any given FLAC file and re-encode and normalize it.
The next layer of the script deals with processing an input directory.

This can just be a simple function that accepts a path and recurses through the directory attempting to find FLAC files inside it.
To avoid infinite loops and other messy affairs, we will not follow any symbolic links and stick to true directories.
Such a function can be written like this,

{% highlight ruby lineanchors %}
def processDir( dirPath )
    return if not File.directory?( dirPath )

    Dir.foreach( dirPath ) { |content|
        contentPath = dirPath + "/" + content
        if File.directory?( contentPath )
            processDir contentPath
        elseif File.file?( contentPath )
            flacFile = FlacFile.new contentPath
            flacFile.normalize
        end
    }
end
{% endhighlight %}

We are assuming that this function only gets passed valid `dirPath`s.
Still, for sanity sake, we'll test to make sure it's a valid directory (or symlink, to be complete).
Next, we iterate over each entry in the directory.
If the entry/content is a directory, we recurse (opening us to a logic issue of potentially following a symlink).
And if the content is a file, we'll try to normalize it.

First, we need to close the logic gap of potentially following unsafe symlinks.

{% highlight ruby lineanchors %}
contentPath = dirPath + "/" + content
next if File.symlink?( contentPath )
{% endhighlight %}

Next, the `foreach` block ends up following the `.` and `..` directories as well, causing trouble.
To fix that, we'll skip those.

{% highlight ruby lineanchors %}
Dir.foreach( dirPath ) { |content|
    next if content == "." or content == ".."
{% endhighlight %}

Awesome.
Now, it would be great to fork off normalization processes off the parent thread.
That way, all FLAC files in the same directory could be processed at once.
Typically, we expect a dozen FLAC files to be present in a directory, so this should not get too out of hand.
If this assumption is not true and you have a folder with dozens (or worse, hundreds) of FLAC files, this is potentially unsafe and will use a lot of resources.
Here's the original block:

{% highlight ruby lineanchors %}
Dir.foreach( dirPath ) { |content|
    next if content == "." or content == ".."

    contentPath = dirPath + "/" + content
    next if File.symlink?( contentPath )

    if File.directory?( contentPath )
        processDir( contentPath )
    elsif
        flacFile = FlacFile.new contentPath
        flacFile.normalize
    end
}
{% endhighlight %}

And here's how the forked version looks.
Notice that we wait for all the forked processes to finish at each level before moving on.

{% highlight ruby lineanchors %}
Dir.foreach( dirPath ) { |content|
    next if content == "." or content == ".."

    contentPath = dirPath + "/" + content
    next if File.symlink?( contentPath )

    if File.directory?( contentPath )
        processDir( contentPath )
    elsif
        fork do
            flacFile = FlacFile.new contentPath
            flacFile.normalize
        end
    end
}

Process.wait
{% endhighlight %}

This function is done good to go.
As long as it's given a valid, absolute directory path, it will merrily recurse and process all files and directories inside.
If any FLAC files are found, it will attempt to normalize them, else it will leave them alone.

> EDIT: As it turned out, this function was actually NOT good to go.
> Read the [next update]({% post_url 2014-11-15-normalizing-flac-files-with-ruby-part-iii %}) to checkout the solution.

Great.
Now, it's time to move on to the next outer layer.
This function must take a raw input parameter and figure out if it's a valid argument.
If the directory or file doesn't exist, the user must be told of that.
I decided to not stop the script in that case, so the script will just print an error message for an incorrect path and move on to the other arguments.

{% highlight ruby lineanchors %}
def process( input )
    if not File.exists?( input )
        puts "ERROR. #{input} not found."
        return
    end

    inputPath = File.absolute_path( input )

    if File.file?( input )
        flacFile = FlacFile.new inputPath
        flacFile.normalize
    elsif File.directory?( inputPath )
        if not File.symlink?( inputPath )
            processDir inputPath
        end
    end
end
{% endhighlight %}

That works.
Finally, the outer-most layer.

{% highlight ruby lineanchors %}
require 'optparse'

if __FILE__ == $0
    optparser = OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} [-h|--help] [FILE|DIR] [FILE|DIR] ..."

        opts.on( "-h", "--help", '''Display this help message.

This script will reencode FLAC files and apply replay gain normalization...

        #... snipped ...

        ''' ) do
            puts opts
            exit
        end
    end

    optparser.parse!

    ARGV.each do |input|
        process input
    end
end
{% endhighlight %}

That's basically it.
The option parser handles printing out the help message.
I'm still not too happy with the formatting of the help message, but for now, it's in good shape.
After calling `parse!` on the option parser, ARGV will only contain the arguments.
We can just loop over them and process each in turn.

This script can now do everything the bash script could do, while able to handle short and long options, files and directories or a mix of both, with and without spaces in them.


# Next steps

One thing I would like to improve is to take in both process and processDir into the FlacFile class (perhaps renaming it to something like Normalizer or Reencoder).
That way, the outer loop just sifts through inputs and feeds absolute paths (when available) to the class and the class goes off and does the rest.
This way, vulnerable functions like processDir can be put in private access and hidden away.


For now, I'll clean up the code a bit and tag a new release.
The repository is, of course, [here](https://github.com/dekonvoluted/normalizeFLAC).
Feel free to use, modify and pass on.

