---
title: Preserving extended attributes while copying files
layout: post
categories: [ user guides ]
tags: [ rsync, cp, ext4 ]
---

> This is the second draft of this write up and goes into more detail about preserving and restoring extended attributes when copying files.

# Ce n'est pas un livre

The books I read growing up, I remember them as more than just words.
I remember also, the touch or texture of the paper on which they were printed, the binding of embossed leather or cardboard, the smell of the pages, even the weight of the books themselves;
while these are meaningless in and of themselves, they garnish the experience of reading a book.

In the same way, the metadata that your file system stores along with your files is likely to contain a lot of auxiliary information that you might want to preserve along with the file.
Metadata is simply data about data.
This includes the timestamp, noting when the file was created or last modified, the permissions and ownership information, noting who is allowed to read it or modify it.
You may want to know that a certain file has been with you for a very long time, or that you last made edits to a file that one summer.
Increasingly, these days, this might also include tags and comments you might want to record about the file.

The KDE subsystem `baloo` exposes and indexes this sort of metadata and allows you to search your files using them.
You could, for instance, search for all the files that relate to a particular project because you tagged them as such.
Its predecessor, `nepomuk` used to store this data in an internal database.
As long as you're using a sane file system, `baloo` now stores this metadata as extended atttributes right on the file system.

# Extended attributes

[Extended attributes](http://en.wikipedia.org/wiki/Extended_file_attributes#Linux) are supported by ext4, and consist of pairs of names and values.
Each attribute name falls under four namespaces, of which the `user` namespace is the one we'll be dealing with.
The other namespaces, `system`, `trusted`, `security` are best left for access control and other security concerns at the system level.
[Freedesktop.org](http://www.freedesktop.org/wiki/CommonExtendedAttributes/) has published a set of recommendations in an effort to coordinate how key attributes are stored and accessed on a modern system.
For example, it recommends the attribute name `user.xdg.origin.url` should be used to store the original URL from which a file was downloaded from (which is how Chrome or Chromium stores it).
For other metadata, applications are free to define and store additional types under the `user` namespace.
`baloo` uses `user.baloo.rating` to store a five star rating on a scale from 0 to 10 half-stars.

Access to these attributes is provided by the `setfattr` and `getfattr` commands.
You can get a list of all extended attributes associated with a file like this,

    $ getfattr --dump 1949\ -\ Late\ Spring.mkv
    # file: 1949 - Late Spring.mkv
    user.baloo.rating="6"
    user.xdg.tags="Drama Film,Japanese Film"

Notice how the dump option basically writes out the name (or relative path) of a file, followed by a bunch of name-value pairs?
That's going to be useful later in this post.

Or, if you're on a KDE system, you can just mouse over the file in Dolphin and see some of this metadata show up on the information panel.

![dolphin-info-panel](/images/dolphin-info-panel.png)

# Creating metadata

The information panel is also where you would easily set these attributes.
Or you can do so from the command line,

    $ setfattr --name="user.xdg.language" --value="ja" 1949\ -\ Late\ Spring.mkv

# Preserving metadata

This is all great, but what happens when it comes time to copy or move a file with associated metadata?
First, know that your computer values the data contained in a file much more than the associated metadata and will always work to preserve that.
So, if you move a file from a file system that supports metadata to one that doesn't, the metadata will be silently dropped.
You will not get any warning that a file has associated metadata and it will be lost if you proceed to copy this file to a FAT disk because such warnings can quickly get out of hand if the user is transferring a large number of files.
The metadata will also not be preserved if you email a file, for instance.
With that out of the way, let's look at some ways you might copy or move a file and how they relate to metadata.

## Using Dolphin

Probably the most common way for people to move files around is by dragging and dropping it in a file manager.
Dolphin, of course gives you the option of copying or moving a file when you drag and drop it.
If you choose move, the metadata is copied along with the file.
If you choose copy, the system figures you want a copy of the file data, but not its metadata and will start you off with a fresh copy of the file.
There's no way to make a drag-drop copy while preserving extended attributes of a file that I am aware of.

## Using `cp` or `mv`

The terminal generation would rather just use `cp` to copy a file or `mv` to move a file.
As expected, `mv` preserves extended attributes and just moves a file from the source to the destination.
Again, as expected, `cp` will start you off with a fresh copy with none of the older metadata preserved.
However, you _can_ make a copy with the extended attributes preserved if you use the `-a/--archive` option.

    $ mv source/file-with-metadata destination/file-with-metadata
    $ cp source/file-with-metadata destination/file-without-metadata
    $ cp -a source/file-with-metadata destination/file-with-metadata

## Using `rsync`

Most backup utilities will use `rsync` and often will use the `-a/--archive` option as it preserves a lot of attributes.
You'd be forgiven for thinking this preserves extended attributes, but in fact, it does not.
The `rsync` documentation states that the `--archive` option stands for `--recursive`, `--links`, `--perms`, `--times`, `--group`, `--owner`, `--devices`, `--specials` and explicitly avoids `--hard-links`, `--acls`, and `--xattrs`.
That last one there is the option we want.
So, if you want to preserve your metadata, do remember to include `-X/--xattrs` (note that the short form is a capital X) as one of the flags when calling `rsync`.

    $ rsync --archive source/file-with-metadata destination/file-without-metadata
    $ rsync --archive --xattrs source/file-with-metadata destination/file-with-metadata

## Using `scp`

For one-off copy operations over a network, `scp` is extremely useful.
Unfortunately, it doesn't support extended attributes and there is no option to preserve them as far as I know.

    $ scp source/file-with-metadata destination/file-without-metadata

(As a sidenote, the OS X version does have a `-E` option, but is OS-specific and won't work unless both source and destination are running OS X.)

# Restoring metadata

Oops.
You've just made a copy of a file and ended up losing all its extended attributes.
Worse, you had an entire directory full of files with lots of carefully tagged information and all of that metadata is lost!
Or is it?

As long as you have a backup to retrieve this information from, nothing's lost.
Recall that `getfattr` using the dump option would give you a nice output containing the relative path of a file followed by its extended attributes.
You can dump the extended attributes of a single file, or even recursively get all the attributes of all files under the current directory.
Note that directories are treated just like files as far as extended attributes go.

    $ getfattr --recursive --dump ./
    # file: file1
    user.xdg.comment="This file has a comment attached to it."

    # file: dir1
    user.xdg.comment="Even directories can have extended attributes!"

    # file: dir1/file2
    user.baloo.rating="4"

    ...

Redirect this output into a file, say called metadata.txt.
You may even create such a file manually (why not?!).
All you need to do is to give this file to `setfattr` and set it to work.

    $ setfattr --restore=metadata.txt

And the file attributes will be applied to the copies as `setfattr` finds each file by its relative path and applies the following attributes to it.
This takes very little time as only the metadata is being written to the disk.
Note though that if you renamed a file or changed the (relative) path of a file, you may have to fiddle with the exported data before `setfattr` can use it.

# Deleting metadata

Ideally, `setfattr` would have an option to recursively delete all extended attributes of files passed to it as arguments.
Unfortunately, that's not the case and `setfattr` will only delete one extended attribute at a time, when specified by the name of the attribute.

    $ setfattr --remove=user.xdg.comment file-with-metadata

This is somewhat limiting if you want to just wipe an entire directory of files clean of all metadata, but it's not too hard to write a script that will intelligently do this for you.

# Closing thoughts

In a way, all this highlights how uneven the support for metadata and extended attributes is across tools right now.
On the plus side, `getfattr` and `setfattr` mostly work as expected.
The tools for copying or moving files also largely do things as is expected of them (i.e., preserve when moving, but not when copying).
But on the minus side, search tools are still in their infancy with the CLI ones particularly lacking in features.
An infamous example is `find` which does not know how to search using extended attributes.

On KDE systems, you can use the tags:/ kioslave to navigate your system using tags in Dolphin.
Navigating a movies collection like this is very cool.
I recommend checking this out.

But only a subset of the applications, with Dolphin, Gwenview and Digikam in the forefront, do anything interesting with extended attributes.
That is likely to change with upcoming releases, I hope.

I'd like to call out one specific application that generates a lot of valuable metadata, at least for me and does not do anything useful with it.
Amarok has a wealth of information buried in its internal database containing ratings, playcounts and other info that would be great to have access to via extended attributes of the music files themselves.
As this is metadata I'd hate to lose, it would be reassuring to be able to make a `getfattr` dump straight off a backup, if needed.
The more I think about this, the more it's starting to sound like something I'd like to try and implement myself...

# Further reading

Here's a [nice summary](http://www.lesbonscomptes.com/pages/extattrs.html) focussing on extended attributes support on other systems.

