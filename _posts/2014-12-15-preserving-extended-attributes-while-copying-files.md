---
title: Preserving extended attributes while copying files
layout: post
categories: [ user guides ]
tags: [ rsync, cp, ext4 ]
---

When using `rsync` to make backups, one usually uses the `-a/--archive` flag to preserve file system metadata like ownership, modification times, etc.
The `rsync` documentation states that the `--archive` option stands for `--recursive`, `--links`, `--perms`, `--times`, `--group`, `--owner`, `--devices`, `--specials` and explicitly avoids `--hard-links`, `--acls`, and `--xattrs`.

On KDE systems, the `baloo` subsystem stores all user-created metadata (tags, ratings, and comments) in the file system extended attributes.
You can quickly check all the extended attributes stores for a given file using the `getfattr` command.

{% highlight console %}
$ getfattr --dump /media/media/movies/1949\ -\ Late\ Spring.mkv
getfattr: Removing leading '/' from absolute path names
# file: media/media/movies/1949 - Late Spring.mkv
user.baloo.rating="6"
user.xdg.tags="Drama Film,Japanese Film"

{% endhighlight %}

This example shows a movie file with a rating and a couple of tags associated with it.
Normally, when this file is backed up with `rsync`, this metadata will be lost.
To preserve this metadata, you should use the `--xattrs` option.

And what if you want to use `cp` to copy the file and still preserve these attributes?
Most of the time, when you make a copy of a file, you probably don't want to retain any old metadata.
You would normally want ownership, file creation time, etc. to start fresh for the copy.
If you do want to retain all the metadata, that's also possible.
Unlike `rsync`, `cp`'s `-a/--archive` option does preserve extended attributes as well as the normal file system metadata.
So, simply use `cp --archive` and you will not lose any of it.

Following the rationale that when you make a copy, you want to drop all the metadata belonging to the original file, when you drag and drop a file in Dolphin and make a copy, the new copy starts without any of the extended attributes of the original file.
Unfortunately, there doesn't seem to be a way to do a drag-and-drop copy while preserving all the metadata.

A final note.
Copying extended attributes, whether by using `rsync` or `cp`, makes sense only if the file system (both the origin and the destination) supports it.
Most sane file systems, ext4 for instance, do.
If you use FAT or NTFS on the other hand, please just don't.

