---
title: Using accented or special characters and unicode symbols in linux
layout: post
repo: fix.me
categories: [ user guides ]
tags: [ unicode, compose ]
comments: true
---

> Before we begin, I need to mention that much of this applies to X-based GUI's.
> I have not yet found an easy or simple way (or need) to type in special characters in the console, that is, when X is not running.
> If you are a `vim` user, you can either use digraphs (Ctrl+K, or :dig) or type Ctrl+V, u and type in the hexadecimal code for the unicode character you want (say, (00e0) and voilà!
> Similar solutions exist for emacs users, too, I'm sure.
> As you'll see, it's more elegant in X.

> I also want to point out that this is not a good replacement for keyboard layouts.
> If you find yourself typing in another languages for longer than a few characters at a time, you really should look into using multiple keyboard layouts.

I often found the need to use accented characters, such as é, Å or Greek characters such α, Φ etc., but lacked the means to type it easily and quickly.
I found several kludgy, but somewhat usable ways to get around this:

- Use a character-picker, an app that will let you choose special characters from a table.
- Use an office app and copy the special character from there.
- Use krunner.
     Typing a # followed by the hexadecimal character code will let you select and paste a special character.
     #00e0, for instance will let you pick à.
- Use a keyboard layout that supports the accented characters and switch back to your default one after typing the character in.

Such solutions are not elegant and lack customizability.
So, I looked to AltGr and Compose keys for a better solution.
These are two techniques to enter special characters in X.
Since neither AltGr, nor Compose are found ubiquitously on keyboards anymore, it's up to the user to designate keys you don't use to assume their behavior.
AltGr works a bit like the shift key, entering special characters when pressed along with other keys.
However, the AltGr key combinations do not exist for Greek characters.
Further, the AltGr behavior is really just a subset of what the Compose key is capable of.

Pressing the Compose key tells the computer that the next few keys are part of a sequence.
The computer will search through a pre-defined list of sequences and when it finds a match, it will display the corresponding special character.
Till then, no characters will be displayed on the screen.
If no sequences match, it'll drop out of compose mode at the next character.

# Designating and Enabling the Compose Key

In what follows, we'll set up a Compose key and customize compose key sequences to suit our needs.
To know which keys can be designated as the compose key, pull up the following file: `/usr/share/X11/xkb/rules/xorg.lst`.
Scroll down to the Compose key section and pick an option that works for you.
I picked `compose:caps`, but I understand that `compose:rwin` and `compose:menu` are popular choices as well.

Now, we need to set this as an option for our X server.
What I describe will work for xorg-server 1.8 and up (or any set up that doesn't use hal for input hot-plugging---if you use hal, you probably need to enter this in an fdi file).
You also need to have root privileges to edit system files.
In the keyboard section of `/etc/X11/xorg.conf`, or in the appropriate .conf file in `/etc/X11/xorg.conf.d/`, add the XkbOptions line.
If you use multiple options, separate them using commas.

{% highlight text %}
Section "InputClass"
    Identifier "Keyboard"
    MatchIsKeyboard "yes"
    ...
    Option "XkbOptions" "...,compose:caps,..."
    ...
EndSection
{% endhighlight %}

Now, restart X to have your designated Compose key active.

If you don't have root privileges, you could still designate a Compose key using the keyboard settings control module in your DE.
And you shouldn't even require to restart X to enable it!
However, this is still less preferable as it will only work in your login and is tied to your choice of DE.

If you are curious to explore available compose key sequences, check out the so-called Compose file: `/usr/share/X11/locale/en_US.UTF-8/Compose`.

My locale in en_US.UTF-8, but replace it by your locale if it's different (use `locale | grep "LANG"` to find your locale).
This is a huge, 5000+ line text file listing enough key combinations to type in multiple languages.
If you balk at reading such a huge file, trial-and-error is often a good way to find key sequences as most of them are quite logical (e.g., multi-key + t + m = ™).

# Editing the Compose file

I felt that the default Compose file could use a cleanup for two reasons.
First, as I've stated earlier, I don't see the Compose file as a replacement for switching keyboard layouts.
The default compose file spends far too much time setting up various European and Asian language characters.
Second, while most shortcuts are well thought out, it's a bit overwhelming and badly organized.
Similar keyboard shortcuts are not found together (much like the Unicode character blocks, unfortunately).

Hence, I decided to cut down the number of key sequences to just the characters that I can see myself using and bring some organization to the list.
As you can see, the syntax is quite easy to understand:

    <Multi_key> [KEY SEQUENCE] : "[SYMBOL]" [UNICODE HEX OR OPTIONAL NAME OF SYMBOL] # [OPTIONAL COMMENT, USUALLY THE UNICODE DESCRIPTION]

For instance, to use \' + a to type á, the line will look like this:

{% highlight text %}
<Multi_key> <apostrophe> <a> : "á" U00E1 # LATIN SMALL LETTER A WITH ACUTE
{% endhighlight %}

Compose key sequences are case-sensitive.
So you can define another sequence to use \' + A to get Á.
Further, apart from alphabets and numbers, all other keys are referred to by their description: asciitilde (~), grave (\`), apostrophe (\'), asciicircum (^), exclaim (!), asterisk (\*), leftparens (() etc.
Read the original Compose file for more such names.

While defining your own sequences, be careful not to overload sequences or define two sequences in a way that you can't get to the second one.
The computer will enter the first matching sequence, so if you define two sequences like this:

{% highlight text %}
<Multi_key> <minus> <minus> : "–" U2013 # EN DASH
<Multi_key> <minus> <minus> <minus> : "—" U2014 # EM DASH
{% endhighlight %}

you will never be able to enter the EM DASH as by the time you hit the second minus, you'll drop out of Compose mode with an EN DASH.
Incidentally, the default Compose file solves the above problem by using the following sequences:

{% highlight text %}
<Multi_key> <minus> <minus> <period> : "–" U2013 # EN DASH
<Multi_key> <minus> <minus> <minus> : "—" U2014 # EM DASH
{% endhighlight %}

I set out to organize my Compose file into two broad sections with subsections as follows:

- Part A: Punctuation
    1. Accented Capital Latin Characters
    2. Accented Small Latin Characters
    3. Punctuation Marks
    4. Currency
    5. Emoticons, Miscellaneous
- Part B: Mathematics
    1. Capital Greek Characters
    2. Small Greek Characters
    3. Operators
    4. Fractions
    5. Superscripts
    6. Subscripts

Most of the compose key sequences in my file are the same as the original, but I invented some for new characters not in the original file.
For instance, compose sequences for Greek letters start with a g, while some mathematical symbols sequences start with an m:

{% highlight text %}
<Multi_key> <g> <a> : "α" U03B1 # GREEK SMALL LETTER ALPHA
<Multi_key> <g> <b> : "β" U03B2 # GREEK SMALL LETTER BETA
<Multi_key> <g> <g> : "γ" U03B3 # GREEK SMALL LETTER GAMMA
...
<Multi_key> <m> <d> : "∂" U2202 # PARTIAL DIFFERENTIAL
<Multi_key> <m> <I> : "∫" U222B # INTEGRAL
<Multi_key> <m> <i> : "∞" U221E # INFINITY
{% endhighlight %}

In other places, I changed the default sequences to type characters that were more important to my usage.
For instance, in the original Compose file, < + < produces the left guillemet («).
I find that the much less-than character (≪) is much more useful.
So, I defined it like so:

{% highlight text %}
<Multi_key> <less> <less> : "≪" U226A # MUCH LESS-THAN
{% endhighlight %}

Finally, in the emoticons and miscellaneous section, I added some whimsical characters that struck my fancy: ☢ (r + a), ☣ (b + h), ☯ (y + y), ಠ (l + o + d)... while retaining some equally interesting characters from the original Compose file: ☭ (C + C + C + P), ♥ (< + 3), ☺ (: + ))...

The new Compose file took a day to put together and came in at 250 lines and packed a lot more useful characters for me.

I could save my Compose file as ~/.XCompose and have it active just for myself after I log in, or I could replace the original file so that it is active for all users and available as soon as X starts---although I don't recommend using Unicode characters in usernames or passwords... it can make console-based recovery options virtually impossible.

My compose file is now hosted on a git repository and from time to time, I make edits to it.
You can find it [here](fix.me).

Feel free to edit and hence or otherwise, customize the compose key sequences I put together!
