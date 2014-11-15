---
title: Normalizing FLAC files - with Ruby
subtitle: Part III
layout: post
categories: [user guides]
tags: [ruby, flac, recursion]
---

> This is the last part of a series of posts.
> <ul>
>     <li><a href="{% post_url 2014-11-04-normalizing-flac-files %}">Normalizing FLAC files</a></li>
>     <li><a href="{% post_url 2014-11-08-normalizing-flac-files-with-ruby-part-i %}">Normalizing FLAC files - with Ruby - Part I</a></li>
>     <li><a href="{% post_url 2014-11-09-normalizing-flac-files-with-ruby-part-ii %}">Normalizing FLAC files - with Ruby - Part II</a></li>
>     <li>Normalizing FLAC files - with Ruby - Part III</li>
> </ul>
> The code is maintained in [this repository](https://github.com/dekonvoluted/normalizeFLAC).

I thought I was done with this project, but I had one niggling issue at the end of the last update.
Let me explain the issue first.
Here's the directory structure I'm working with.

    Artist/
    └── YYYY - Album/
        ├── TT - Track.flac
        └── album.jpg

There are many artists, many albums and many tracks.
I expect the sequence of operations to look like this,

    Entering (one) Artist/
    Entering (one) YYYY - Album/
    Fork off (each) TT - Track.flac
    ...
    Wait for (each) fork to exit
    Leaving YYYY - Album/
    Process other albums
    Leaving Artist/

To make this magic happen, here's a simplified version of the code I was relying on.

{% highlight ruby linenos %}
def processDir( dirPath )
    Dir.foreach( dirPath ) do | content |
        next if content == "." or content == ".."

        contentPath = dirPath + "/" + content
        if File.directory?( contentPath )
            processDir contentPath
        elsif File.file?( contentPath )
            fork do
                processFile contentPath
            end
        end
    end

    Process.wait
end
{% endhighlight %}

However, instead of doing what I expected, the sequence of execution looked like this,

    Entering (one) Artist/
    Entering (one) YYYY - Album/
    Entering other albums
    Fork off (each) TT - Track.flac
    ...

This forked off so many processes that it was maxing out the hard disk I/O.
More confusingly, it seemed to do the right thing if an album contained a single track, but not if an album had many tracks.

In desperation, I rewrote the code to collect files and directories at each level, process files first and then recurse into directories.

{% highlight ruby linenos %}
def ProcessDir( dirPath )
    directories = []
    files = []

    Dir.foreach( dirPath ) do | content |
        next if content == "." or content == ".."

        contentPath = dirPath + "/" + content
        if File.directory?( contentPath )
            directories.push( contentPath )
        elsif File.file?( contentPath )
            files.push( contentPath )
        end
    end

    files.each do | file |
        fork do
            processFile file
        end
    end

    Process.wait

    directories.each do | dir |
        processDir dir
    end
end
{% endhighlight %}

This turned out to be a good thing as this bit of code actually throws an error which led me to the root cause of the problem.

    ./normalizeFLAC.rb:23:in `wait': No child processes (Errno::ECHILD)

The error is because I called `Process.wait`, but on the first level, there were no files and no child processes to wait for.
And there was the answer I was looking for.

The `Process.wait` documentation states that when called without a pid, it waits for a child process to exit.
Another way of putting that would be that it waits for the first child process to exit and doesn't wait for the remaining processes after that.
This was why the script continued on its merry way, forking a whole lot of processes.
As soon as the first child process reported back, the code moved on to the next directory and the next and so on.

The fix for this is to use `Process.waitall` which, unlike `Process.wait`, waits for all child processes.
It also doesn't throw errors if there are no child processes to wait for.
With this simple fix, the code now behaves as I expect it to.
And I can finally move on to the next project.

