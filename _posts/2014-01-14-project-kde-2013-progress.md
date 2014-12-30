---
title: Project KDE
subtitle: 2013 progress
layout: post
categories: [ project KDE ]
tags: [ kde ]
---

I thought it might be a good idea to revisit my competency in the four tools I [set out]({% post_url 2012-11-18-project-kde-the-first-steps %}) to master in 2012.
These tools were Qt, C++, cmake, and git. Here's how last year went down.

# Qt

I started 2013 knowing little to nothing about Qt and compared to that, I'm much further ahead.
I can now put together a primitive GUI without much sweat.
I can write a basic Qt application from scratch, but will have trouble getting anything more complicated working.

The beleaguered tutorial is nearly done, but still unfinished.
I think the game deserves a part of the blame.
It's so much fun to play---because I made it;
It's like being a kid again.
I do plan to wrap it up soon.

The biggest step forward here was in getting familiar with QPainter.
I can now do primitive 2-D graphics, which is nice.

There's plenty of things left to learn in 2014.
My first task here is to complete the tutorial.
Then, I plan to devote some time working on the Equilibrium project (I'll write about that sometime soon).
With a little more familiarity with Qt, I think I can take on some of the junior jobs on bugs.kde.org.

# C++

I got to really grok OOP concepts and work with many parts of the standard library this year, particularly containers and algorithms.
Got to dabble with iterators and functionals with lots of work using lambda expressions.
So, lots of progress here.

# cmake

Little to no progress here.
I did have to debug a cmake issue in Equilibrium, but I wouldn't consider myself much smarter because I fixed it.
I can still write basic cmake source code, but that's about it.

# git

I got a lot more familiar with advanced usage of git and can juggle commits quite competently now.
I also got to be quite comfortable with submodules.
The list of things I'm not comfortable with is much shorter, with probably reflogs being the most notable topic.
That, and the internals of how git works, maybe.

So, table time.
Here's how I'd rate myself at the end of 2013.

Topic   | 2012  | 2013
:-      |:-:    |:-:
Qt      | 0     | 2
C++     | 4     | 6
cmake   | 1     | 1
git     | 5     | 7

Progress across the board.
I also picked up some auxiliary skills I didn't have before.
I got to tinker with `zsh` as `bash` at work is woefully incomplete without `bash-completion` and I can't stand `tcsh`.
I got to learn how to use `doxygen` to document my code.
And last, but not the least, I got to grok `vim` a bit more.
It really is a powerful text editor.

# Things I want to learn in 2014

It's now time to plan the next year.
First, I see gaping holes in my knowledge of Qt and cmake.
The former is much higher priority, but as my projects get more complicated, I'll probably need to learn cmake as well.

I also need to get comfortable using exceptions in C++.
I've always glossed over the try/throw/catch bits and it's time to give that a proper go.

I also want to make more progress on the Equilibrium project, something I have yet to blog about.
It's basically a project to write a gas equilibrium calculator.
Some of the basic classes have been written.
It's time to write a data parser to read in thermodynamic data and follow that up with writing a simple solver.
Then, it'll be time to give the program a usable GUI.

Two other tools, I've been feeling the lack of are a debugger and a profiler.
I still debug by littering my code with `cout` statements.
I've half-heartedly read through some documentation on `gdb`, but it would be great to make some progress here.

As for profiling my code, it should help me see if a change is actually making my code faster or if it's actually slowing it down.
Specifically, I'd like to get properly acquainted with `valgrind`'s `massif` tool...

Here's to a productive 2014!

