---
title: Preserving extended attributes during rsync
layout: post
categories: [ user guides ]
tags: [ rsync, ext4 ]
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

This example shows a movie rated 6 (out of 10) and tagged with some descriptive tags.
This metadata will NOT be present in your backups, unless you explicitly use the `--xattrs` option.

And what if you want to use `cp` and preserve these attributes?
Just use the `-a/--archive` flag and you're good to go!

