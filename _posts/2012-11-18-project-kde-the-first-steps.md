---
title: Project KDE
subtitle: The first steps
layout: post
categories: [ project KDE ]
tags: [ kde ]
comments: true
---

Project KDE is what I call my personal project to start contributing code to the KDE project.

Okay, first things first. I knew the following things about kde:


- it's written using the [qt](http://qt.digia.com/) (pronounced cute) toolkit
- Both qt and the rest of kde are mostly written in C++
- kde programs usually use <a href="http://www.cmake.org/">cmake</a> to automate the compiling process
- kde intends to move all their code from svn to the <a href="http://git-scm.com">git</a> version control system

The first two, qt and C++ are rather indispensable.
The second two are relatively less important and can be picked up along the way.
There are also kde-specific libraries that I need to get comfortable with, but I can worry about that later.
For now, I need to evaluate where I stand with respect to these four topics.

# Qt

At this point?
Very little.
Reassuringly, I do know it's very well documented and easy to use.
My first step will be to hit a tutorial, but that's getting ahead a bit.

# C++

I don't have much experience learning programming in a classroom setting.
I did take the mandatory programming class for engineering undergrads (which was taught in Pascal, yikes!).
And I took another undergrad class sometime later that dealt with "Object Oriented Programming for Scientists and Engineers".
Unfortunately, I think I slept through most of it and have very little recollection of what was taught in that class.

Luckily, this turns out to be okay, since most programmers will tell you that you learn more from tinkering away on your own projects than in a classroom.
Still, I feel that formal training is good to have, if only to have familiarity with the jargon.
That alone makes googling for answers so much easier.

So, I learnt C++ tinkering on my own, with plenty of help from google and the intertubes.
I recommend cplusplus.com's [tutorial](http://cplusplus.com/doc/tutorial/) in particular, which I have often returned to to brush up on relevant sections before attempting more complex code.
You don't need to know every section of it, just know where to look for help when you need it.
I still keep this website bookmarked for its [Reference](http://cplusplus.com/reference/) section.

# CMake

Googling "cmake tutorial" took me [here](http://www.cmake.org/cmake/help/cmake_tutorial.html) where I didn't understand much beyond step 2.
I never really found a good reference for learning cmake.
So, I mostly patched together a CMakeLists.txt from trial and error and got it working for compiling qt programs using information on [this](http://qt-project.org/quarterly/view/using_cmake_to_build_qt_projects) page.
Again, I'm jumping ahead.
For now, let's say I know very little of cmake and will learn it as I go along.

# Git

I understand the basic usage of git.
I know how to initialize a repository, commit changes, create, switch, merge and delete branches, and to push to, pull from or clone another location.
I know some more things like stashing changes, and popping them back, resetting to a previous commit, etc.
Excellent documentation exists in the form of the git community book, which can be found [here](http://git-scm.com/book), which I have bookmarked.
More hands-on and example-driven help can be found in github's [Help](http://help.github.com/) section which walks you through setting stuff up, creating a repository, etc.

I started by using git to keep versions of various small projects I attempt now and then.
Once I got familiar enough with it that I was confident of not losing any data, I used it to version control my thesis.
That was trial by fire and git passed with flying colors.
Now, I trust git (or what little I know of it) implicitly.

# Conclusion

Here's my score card, rating my know-how on a scale of 0 to 10:

:- | :-:
Qt | 0
C++ | 4
cmake | 1
git | 5

The most glaring shortcoming is qt.
So, my first step will be to familiarize myself with it.
The weekend is just beginning...

