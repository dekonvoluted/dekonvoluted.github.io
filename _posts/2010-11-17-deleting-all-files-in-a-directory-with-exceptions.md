---
title: Deleting all files in a directory with exceptions
layout: post
categories: [ user guides ]
tags: [ bash, globs ]
comments: true
---

It's easy to delete all files in a directory:

    $ rm *

However, making exceptions to this command is a little tricky.
Suppose I have a LaTeX file (report.tex) in a directory, along with a shell script (createreport.sh) that processes this file to produce a PDF file (report.pdf) and/or a DVI file (report.dvi) and I want to keep only these files and delete all the temporary files created by the compiler---log, aux, etc.
Normally, I'd include this deletion step in the contents of the shell script, perhaps like this,

{% highlight bash %}
#!/bin/bash

latex report || exit 1
pdflatex report || exit 1
rm -f *.aux
rm -f *.log
rm -f *.out
exit 0
{% endhighlight %}

This is a limited solution as it requires me to know beforehand, all the file extensions that I would want to delete.
It would be great if I could tell `rm` to just spare the four original file extensions and delete *anything else*.

# Extended Globs

To do that, use `rm` like this,

    $ shopt -s extglob
    $ rm -f !(*.+(tex|sh|pdf|dvi))

This is an example of nesting two [extended globs](http://en.wikipedia.org/wiki/Glob_(programming)).
The explanation is found about a thousand lines into the bash manpage:

{% highlight text %}
If the extglob shell option is enabled using the shopt builtin, several extended pattern matching operators are recognized.
In the following description, a pattern-list is a list of one or more patterns separated by a |. Composite patterns may be formed using one or more of the following sub-patterns:

?(pattern-list)
Matches zero or one occurrence of the given patterns

*(pattern-list)
Matches zero or more occurrences of the given patterns

+(pattern-list)
Matches one or more occurrences of the given patterns

@(pattern-list)
Matches one of the given patterns

!(pattern-list)
Matches anything except one of the given patterns
{% endhighlight %}

In my example, the first line enables the use of extended globs.
Then, I used the +() glob to present a list of valid extensions and used a !() glob around that to exempt such files from deletion.
So, `rm` will delete all files except `.tex`, `.sh`, `.pdf` or `.dvi`.

# Going deeper

Since rm is a dangerous command to use, you can test out the test with `ls` or `echo` like this:

    $ shopt -s extglob
    $ ls !(*.+(tex|sh))
    $ echo !(*.+(pdf|dvi))

This should print out the names of all files that are not `.tex`, `.sh` for the first example and not `.pdf` or `.dvi` files for the second example.

You can concoct similar negating tests for your needs:

- Match files that don't have a `.xyz` extension

        !(*.xyz)

- Match files that don't begin with `abc`

        !(abc*)

- Match all files that don't start with `a`, `b`, `c`, `d` or `e`

        !([a-e]*)

- Match all files that don't start with `a` or `b` and don't end with `c` or `d`

        !(+(a|b)*+(c|d))

# Further reading

[A good explanation of extended globs](http://www.linuxjournal.com/content/bash-extended-globbing)

