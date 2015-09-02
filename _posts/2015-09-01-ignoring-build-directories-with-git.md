---
title: Ignoring build directories with git
layout: post
categories: [ user guides ]
tags: [ git, cmake ]
comments: true
---

I happen to use `cmake` for my projects and typically do an out-of-source build in a directory I lazily call `build/`.

{% highlight console %}
$ cd project/
$ mkdir build/
$ cd build/
$ cmake ..
$ make install # I typically install to $cmake_source_dir/
$ cd ../
{% endhighlight %}

I also use `git` to version control my projects and I want it to ignore the build directory.
Ignoring untracked files (not just the build directory is easy.
Simply set showuntrackedfiles to no or false in your configuration and `git status` will ignore any file or directory not added to the index.

{% highlight console %}
$ git config --global status.showuntrackedfiles false
{% endhighlight %}

Another way to ignore specific files or directories would be to put them in a special file called `.gitignore`.
This file will be committed to the repository and would contain one line for each filter.

{% highlight text %}
# Contents of git ignore
build/
results.dat
{% endhighlight %}

This works okay for ignore the build directory and the results data file, but now, there's a `.gitignore` file that is untracked and present in the repository.
When using `git clean`, it gets in the way.

{% highlight console %}
$ git clean -nd
Would remove .gitignore
Would remove junk
Would remove trash/
$ git clean -df
Removing .gitignore
Removing junk
Removing trash/
{% endhighlight %}

One could commit this file to the repository, you might say.
True.
If you're okay with that, this is the end of this post.
If you're like me and are don't think `.gitignore` has any business being part of a repository, read on.

Within the `.git/` directory, there's a file at `.git/info/exclude` which behaves just like `.gitignore`.
However, it will not show up as an untracked file, will not need to be committed to the repository and will not be exported to the next poor sod who clones your work.
It's just for you and just for this repository.
So, that's what I do.
Add "build/" to this file, keep calm and carry on.

