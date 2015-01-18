---
title: Manipulating PDF files
layout: post
categories: [ user guides ]
tags: [ pdf, ghostscript, pdfmarks, poppler ]
comments: true
---

From time to time, I've needed to reorganize PDF documents, by either combining several files into one large file or breaking up a large file into several small ones.
Somewhat less often, I've needed to modify the metadata associated with the PDF files.
In this post, I'll discuss how to accomplish these on a modern linux system using ghostscript and other readily available utilities.

All these operations are perfectly safe as the original file is left untouched.

# Merging PDF files

Our task is to merge several small PDF files into one large file.
To do this, call ghostscript like this.

    $ gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=$OUTPUT $INPUT1 $INPUT2 ...

The options are simple.
`-dBATCH` sets up ghostscript to run in batch mode.
This will cause gs to exit at the end of the run, rather than spawn a ghostscript shell.
 `-dNOPAUSE` tells ghostscript to move from file to file without pausing for user input (which is the default behavior).
`-sDEVICE` sets the output device to be the PDF generator and `-sOutputFile` is the name or path to the output PDF file.
Simple enough.
If you'd rather not see any output on the screen, pass the `-q` flag to suppress it.

# Extracting portions of a PDF file

In this task, I need to extract, say, pages 24 through 48 from a large PDF file.
This could be a chapter from a book or a section of the class notes you want to distribute.
For this task, call ghostscript like so.

    $ gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -dFirstPage=$FIRSTPAGE -dLastPage=$LASTPAGE -sOutputFile=$OUTPUT $INPUT

Again, the options are easy to understand.
Several of these are repeats from the previous section.
The new ones, `-dFirstPage` and `-dLastPage` are the beginning and ending page numbers to extract.
These can be the same page, in which case, only that page will be extracted.

A subset of the previous operation is to "explode" a PDF file into its pages.
To do this page by page can get tiresome and that's usually an indication that the task is better suited to be written out as a script.
Let's try writing a bash script to do this.

{% highlight bash linenos %}
#!/bin/bash

# explode.sh
# Will accept a file and create several PDF files from its pages

INPUT="${1}"
FIRSTPAGE=1
LASTPAGE=5 #FIXME

for page in $(seq $FIRSTPAGE $LASTPAGE)
do
  gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -dFirstPage=$page -dLastPage=$page -sOutputFile="${INPUT%.pdf}-${page}.pdf" "${INPUT}"
done

exit 0
{% endhighlight %}

Our script has come along quite nicely.
If passed a PDF file called large.pdf,

    $ chmod +x explode.sh
    $ ./explode.sh large.pdf

it will create a sequence of files.
The output file names are constructed by removing the trailing ".pdf" extension from the input file name, attaching a "-", page number and finally, adding back the ".pdf" extension.
So, for our large.pdf file, we get files named large-1.pdf, large-2.pdf, etc. each containing one page of large.pdf.
Astute readers will notice that if the original file were instead called large.PDF, this will produce large.PDF-1.pdf, large.PDF-2.pdf and so on.
However, since no astute reader would have file extensions in caps, it's not a pressing concern.

Nevertheless, note the #FIXME comment.
To get started, I've hardcoded the last page number to be 5.
This is obviously untenable and we need a way to determine, automatically, how many pages are present in a given PDF file.
Failing that, we'll have to update the LASTPAGE variable manually for every PDF file we want to use with our shell script.

I found that the nicest way to do this is using a command called `pdfinfo`.
This is part of the `poppler` package and will be present on any modern linux system since modern PDF readers like Okular are based on it.
The output of `pdfinfo` reads like this:

{% highlight console %}
$ pdfinfo datastruct.pdf
Producer:       GPL Ghostscript 9.06
CreationDate:   Sat Jan 26 09:08:22 2013
ModDate:        Sat Jan 26 09:08:22 2013
Tagged:         no
Form:           none
Pages:          10
Encrypted:      no
Page size:      612 x 792 pts (letter)
Page rot:       0
File size:      141437 bytes
Optimized:      no
PDF version:    1.4
{% endhighlight %}

Excellent.
See the entry for "Pages"?
We can now extract the number of pages in a PDF file by using `awk`.

    $ pdfinfo datastruct.pdf | awk '/Pages: / {print $2}'

So, sticking that into our bash script as this diff output shows,

{% highlight diff %}
---a/explode.sh
+++b/explode.sh
@@ -8,7 +8,7 @@
  
  INPUT="${1}"
  FIRSTPAGE=1
- LASTPAGE=5 #FIXME
+ LASTPAGE=$(pdfinfo "${1}" | awk '/Pages: / {print $2}')
  
  for page in $(seq $FIRSTPAGE $LASTPAGE)
  do
{% endhighlight %}

we end up with a perfectly serviceable explode utility.

# Modify PDF metadata

There was a time when metadata in files wasn't so important.
No one cared if a research paper had a metadata title that identified the paper as "Manuscript-draft24" or identified the author as "Adobe Professional 5.0" or something equally useless.
However, today, thanks to components like nepomuk and strigi, we may need to clean up the metadata from time to time so that we get more relevant results when searching.

There are two major classes of metadata that we are interested in.
The first category, simply called metadata, contains fields.
I'm particularly interested in the following fields: Title, Author, Subject, and Keywords.
The second category is the outline, consisting of a Table of Contents.
The entries in the Outline are called bookmarks (since that's what they are, bookmarks).
I made the distinction between these two categories because of an interesting problem.
Setting the fields in the former category to empty strings will effectively blank out those fields, but I have yet to find a way to remove existing bookmarks (I mean, Table of Contents entries) using ghostscript.
In other words, setting the metadata fields overwrites them, but setting bookmarks appends them.
So, you can add bookmarks, but can't remove them---at least, not using ghostscript.

Of course, there is a workaround.
Use another PDF creator that will simply disregard the Table of Contents.
One such is the PDF printer exposed by qt.
Simply click Print to PDF in Okular and the output PDF will contain no Table of Contents.

So, with that, let's dive in.
Metadata and Bookmarks are passed along to ghostscript by putting them in a text file that's traditionally named pdfmarks (you'll shortly see why).
The syntax of this file is quite simple to understand.
Comments are preceded by % signs.
Commands begin with a "\[" and end with the word "pdfmark" (that's why).

A basic pdfmarks file looks like this.

{% highlight postscript %}
% Metadata
[ /Title (My PDF File) /DOCINFO pdfmark

% Outline
[ /Page 1 /Title (My Title Page) /OUT pdfmark

[ /PageMode /UseOutlines /DOCVIEW pdfmark
{% endhighlight %}

The above file sets the title of the PDF file to "My PDF file", sets the entry for the first page to read "My Title Page" and finally, tells the PDF reader to open the PDF file with the Outline view shown.
In practice, I've seen most PDF readers disregard this suggestion.
Oh well, we'll still play by the rules.

The `/DOCINFO` section can be expanded to include all our fields of interest.
Similarly, the outline can contain simple as well as nested bookmarks.
Let me demonstrate this with two simple examples.
The first pdfmarks file will set all fields and mark only the Chapters.
This is the sort of outline you will want to use for a research paper or a comic book.

{% highlight postscript %}
[ /Title (My Blog Post) /Author (Karthik Periagaram) /Subject (Education, Technology) /Keywords (PDF, metadata, manipulation, ghostscript, linux) /DOCINFO pdfmark

[ /Page 1 /Title (Title Page) /OUT pdfmark
[ /Page 4 /Title (Table of Contents) /OUT pdfmark
[ /Page 10 /Title (Chapter 1) /OUT pdfmark
[ /Page 24 /Title (Chapter 2) /OUT pdfmark
[ /Page 38 /Title (Conclusions) /OUT pdfmark

[ /PageMode /UseOutlines /DOCVIEW pdfmark
{% endhighlight %}

The next pdfmarks file has a more complicated outline consisting of nested sections such as the ones you would find in a thesis.
Notice the syntax used to nest sections.

{% highlight postscript linenos %}
% Some simple metadata
[ /Title (My Thesis) /Author (Karthik Periagaram) /DOCINFO pdfmark

% Outline
% Simple bookmarks
[ /Page 1 /Title (My Title Page) /OUT pdfmark

% Chapter 1 has only one section
[ /Page 4 /Title (Chapter 1) /OUT pdfmark

% Nested bookmarks
% Chapter 2 has two sections
[ /Page 6 /Title (Chapter 2) /OUT pdfmark
[ /Count 2 /Title (Sections under Chapter 2) /OUT pdfmark
[ /Page 8 /Title (Section 2.1) /OUT pdfmark
[ /Page 10 /Title (Section 2.2) /OUT pdfmark

% Chapter 3 again has only one section
[ /Page 24 /Title (Chapter 3) /OUT pdfmark
{% endhighlight %}

Notice that the only difference is the `/Count` entry on line 14 that designates the following two entries as nested entries.
The title for this line doesn't matter.
You can nest as many times as you wish (or as the PDF standard permits---if there's a limit, I haven't found it).

So, we now know how to write a pdfmarks file, but how do we use it?
Simple.
Just pass it along with the input arguments to ghostscript.
So, if we want to add this metadata to a file, we say,

    $ gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=file-with-metadata.pdf input.pdf pdfmarks

Simple and dekonvoluted, just the way I like it.
Now, you can manipulate pages, metadata and bookmarks within any PDF file.
Enjoy.

# Further reading

[More info about pdfmarks than you ever wanted to know](http://partners.adobe.com/public/developer/en/acrobat/sdk/pdf/pdf_creation_apis_and_specs/pdfmarkReference.pdf)

