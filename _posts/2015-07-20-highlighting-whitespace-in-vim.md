---
title: Highlighting whitespace in Vim
layout: post
category: [ user guides ]
tags: [ vim ]
---

Whitespace in code is generally a good thing.
Indentation makes each code block stand out visually and helps make the logic easy to follow.
Well indented code also helps you write better code---too many levels of indentation, for instance, is a sure sign that the code paths should be rethought.
Newlines separate coherent hunks of code from each other, making debugging much easier.
Spaces padding arithmetic operations of function arguments punctuate code and visually separate out multiple elements therein.
One could and perhaps should think of code as poetry (rather than prose).
Whitespace punctuates the streams of thought woven through it and carves out stanzas where otherwise, there would just be an incomprehensible wall of text and symbols.
After all, the point of writing code is to communicate ideas to other people, not to computers.

Now, with that having been said, I particularly hate to see two kinds of whitespace in code:

* Indentation using only tab characters or worse, a mixture of tabs and spaces
* Trailing white space after code, or empty lines consisting entirely of whitespace

Now, the first one is subjective, I'll grant.
There are plenty of good reasons for using tabs for indentation, the most convincing of which is that the tab character as a unit of indentation decouples the visual representation from the semantic meaning---everyone can choose just how wide they like to see their levels of indentation, while the code remains unchanged.
Using spaces for indentation inevitably leads to the next big question---how many spaces should one use for levels of indentation?
Answer: four, but I digress.
Back to the first point, yes, my hatred of tabs is subjective and the fact that I have plenty of company doesn't make me right.
Still, with due apologies to Emily Dickinson, the heart wants what it wants and the first point stands.
The remaining points, about mixed indentation and trailing white spaces are of course, undeniably and irredeemably evil.

Vim makes it easy to highlight whitespace characters using the `list` option.
When enabled (`set list`), the following classes of whitespace are highlighted,

* Tab characters are explicitly shown as "^I"
* Space characters are shown with a space, so not highlighted at all
* End-of-line is indicated with a "$"
* Trailing space, are also left blank, but the end of line "$" makes them easier to spot.
* Other whitespace related to a wrapped line, hidden text or non-breaking spaces (odd Unicode characters).

If the `set listchars=` option is used to specify one or more of these classes of whitespace, only those will be highlighted.
Most of these accept one character to use to highlight the whitespace.
Tab accepts two, one for the beginning of the tab character and the second character to fill the rest of the width of the tab.
Any character, with the exceptions of ":" and "," can be used for this, even Unicode characters, if your encoding is "utf-8".

A simple, non-unicode way to show tabs and trailing spaces could be enabled by adding this to ~/.vimrc:

{% highlight text %}
set list
set listchars=tab:>-,trail:~
{% endhighlight %}

This will cause this code,

{% highlight text %}
normal line
	tab before me
spaces after me    
{% endhighlight %}

to show up like this,

{% highlight text %}
normal line
>-------tab before me
spaces after me~~~~
{% endhighlight %}

If you have a modern Linux system, you are almost certainly using a UTF-8-friendly locale.
This means you can use more interesting Unicode characters to do this highlighting for you.
Here's the `listchars` excerpt from my own `~/.vimrc`:

{% highlight text %}
" Highlight tabs
" Highlight trailing spaces
" Digraphs for the symbols
" » = C-K > >
" · = C-K . M
" ◘ = C-K S n
set list
set listchars=tab:»·,trail:◘
{% endhighlight %}

Note that you can enter Unicode characters in Vim using digraphs.
Digraphs begin with Ctrl+K and are then followed by a two-character code.
The digraphs page lists all the available symbols and can be accessed with `:digraphs` straight from Vim.

I've already configured Vim to not use tabs while indenting.
So, `listchars` chiefly helps me notice and clean up trailing whitespace in my code.
It also highlights tab-based indentation in code written by others, which I can then secretly judge and disapprove of. :)

# Things that can and will go wrong

## Syntax errors

Make sure that you use the correct syntax for setting the `listchars`.
The class of whitespace is to be followed by a colon, ":", and the symbol(s) you want to use to highlight it with.
Do not use "=", like I did once.

Use commas to separate the various classes, not spaces or anything else.


The tab class needs two symbols to highlight tabs.
Spaces and such will accept only one symbol.

## Locale errors

This one's a fun story and the main reason behind this post.
One day, you might launch Vim and get this doozy of an error message,

    Error detected while processing ~/.vimrc:
    line   23:
    E474: Invalid argument: listchars=tab:»·,trail:@~W~X
    Press ENTER or type command to continue

This is baffling, isn't it?
That trail symbol isn't showing up right anymore.
You can press enter, but you will see something like this (for the same example as above),

{% highlight text %}
normal line$
^I      tab before me$
spaces after me    $
{% endhighlight %}

The heck is it with all those dollar signs?
This happens for every single file you try to open.
You suspect that UTF-8 support is somehow broken on your computer.
You check your locale.

    $ locale
    locale: Cannot set LC_ALL to default locale: No such file or directory
    LANG=en_US.UTF-8
    LC_CTYPE="en_US.UTF-8"
    LC_NUMERIC="en_US.UTF-8"
    LC_TIME=en_GB.UTF-8
    LC_COLLATE="en_US.UTF-8"
    LC_MONETARY="en_US.UTF-8"
    LC_MESSAGES="en_US.UTF-8"
    LC_PAPER="en_US.UTF-8"
    LC_NAME="en_US.UTF-8"
    LC_ADDRESS="en_US.UTF-8"
    LC_TELEPHONE="en_US.UTF-8"
    LC_MEASUREMENT="en_US.UTF-8"
    LC_IDENTIFICATION="en_US.UTF-8"
    LC_ALL=

Shit, another error message!
Something about LC_ALL and sure enough, it's empty.
But, wait, wasn't it always empty?
What's the problem now?
Something's borked and you don't know what it is!
You check your `/etc/locale.conf` and it says,

{% highlight text %}
LANG=en_US.UTF-8
{% endhighlight %}

That looks right.
You wonder if you should fiddle with quotes, but no, that will not solve the problem.
You open up `/etc/locale.gen` and make sure that "en_US.UTF-8" in uncommented.
You regenerate the locales by running `locale-gen` as root.
Multiple times, just to be sure.

Mild panic sets in as this issue refuses to go away.
Your pathetic google-fu isn't helping.
Threads about `scriptencoding` lead you on wild goose chases, making you wonder if maybe all that talk about modern Linux systems and UTF-8 was a load of hooey.
You look closer at the output of `locale`.
You notice that one of the variables is not like the others.

See, it all started when you wanted time to be shown in 24-hour format.
The switch to Qt5 means that the time format comes directly from the locale variable set in your system.
Since the US region uses 12 hour time (barbarians!), you had switched the time region settings to good ol' Blighty and got your 24 hour clock.
You were happy, blissfully unaware that you had created all this mess.
One of your locale variables, LC_TIME, now refers to a locale that doesn't exist on your system.
Only en_US.UTF-8 is uncommented in your `/etc/locale.gen` and when you ran `locale`, only that locale was generated.
The fix then is to uncomment en_GB.UTF-8 as well and regenerate the locales.
And everything's magically okay.
Phew.

If something like this happens with your locale, UTF-8 will not work correctly in Vim.
If you had opened the digraphs page (:digraphs) you would have noticed that the digraphs only went up to 255 and most of the symbols (including the one you used for the trailing space above) are no longer supported.
This is a sure sign that something is not right with your locale.
Another tell-tale sign that the issue is with your locale is if Vim works fine in a tty, but not in X.
This indicates that your default LC variables are being messed with and you may not have all the locales generated.
In any case, just check your locale variables, edit `/etc/locale.gen` and make sure the locales are correctly generated.
Hope that helps you avoid a week long maddening debug session.

