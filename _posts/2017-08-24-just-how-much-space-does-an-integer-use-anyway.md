---
title: Just how much space does an integer use, anyway?
layout: post
categories: [ classroom ]
tags: [ C++ ]
comments: true
---

Four bytes.
You'd probably say four bytes.
That's probably what `sizeof (int)` returns on your machine.
And you'd be right.

Most machines today are 64-bit systems and use the LP64 [data model](http://en.cppreference.com/w/cpp/language/types#Data_models) (long == void* == 64 bits or 8 bytes).
If you have an older 32-bit system lying around, it would use the ILP32 data model (int == long == void* == 32 bits or 4 bytes).
In both cases, int uses 4 bytes.
You can check which data model your system uses by running this program,
{% highlight cpp linenos %}
#include <iostream>

int main()
{
    // Print out the data model used
    // ILP32: 4/4/4
    // LP64: 4/8/8
    std::cout << "Data model: " << sizeof ( int ) << '/' << sizeof ( long ) << '/' << sizeof ( void* ) << '\n'
}
{% endhighlight %}

Now, consider the following two programs.
How much memory would you expect each of them to use?

{% highlight cpp linenos %}
// First program
#include <iostream>
#include <vector>

int main()
{
    // Request storage for ten million integers
    auto p = std::vector<int>( 1e7, 0);

    char c;
    std::cin >> c;
}
{% endhighlight %}

{% highlight cpp linenos %}
// Second program
#include <iostream>

int main()
{
    // Request storage for ten million integers
    for ( auto counter = 0; counter < 1e7; ++counter ) {
        auto p = new int( 0 );
    }

    char c;
    std::cin >> c;
}
{% endhighlight %}

Knowing that storing an integer takes up four bytes, you would expect ten million of them to take up 4 * 1e7 / 2^20 = 38.15 MB of memory.
And that would be almost spot-on for the first program.
However, you will probably find that the second program uses almost ten times as much, 305.3 MB, possibly more.
I encourage you to copy and run these two programs to confirm that.
What's going on?

In both cases, the programs ask for and initialize ten million integers worth of storage with zeros.
The only difference is that the first program asks for all that memory at once, while the second program requests it one integer at a time.
When memory is allocated on the heap, the heap manager writes some metadata *before* the allocated space.
This metadata contains information about how much space ahead was allocated, and where the next free space can be found.
It will be used when you use `delete` the storage and return it to the system.
Since the metadata written by `new` may not be the same as that written by `malloc` or any other memory allocator your system may be using, it is encouraged to use the corresponding ways to free the memory.
If you acquired it with `new`, free it with `delete`.
If you acquired it with `malloc`, free it with `free`.

So, when the first program requests a large chunk of memory, the amount of space taken up by this metadata header is negligible in comparison.
However when the second program makes ten million requests, this overhead quickly adds up.
You could calculate approximately how much metadata is added to each integer by taking the ratio of the memory usage.
In my case, the ratio is 8, so 8 * 4 = 32 bits, or two pointers worth of space for each integer.
This ratio need not be the same on your machine though, because that depends on another feature of your system.

Let's illustrate that feature by demonstrating some more interesting behavior.
Consider this third program and guess how much memory it would use.

{% highlight cpp linenos %}
// Third program
#include <iostream>

int main()
{
    // Request storage for ten million integers
    auto p = new int[ 10000000 ];

    char c;
    std::cin >> c;
}
{% endhighlight %}

Surely, this should again use about 38 MB of memory?
Nope, I measured about 140 KB.
What's happening now?

Since the values of these integers weren't initialized to anything yet, the system just held on to the memory and didn't give us anything.
You could consider this a basic form of optimizing for reduced memory usage.
If you initialize all the ten million integers to zero, then, the memory usage shoots back up to 38 MB.

Okay, now consider this modification to the third program.

{% highlight cpp linenos %}
// Fourth program
#include <iostream>

int main()
{
    // Request storage for ten million integers
    auto p = new int[ 10000000 ];
    p[ 999999 ] = 0;

    char c;
    std::cin >> c;
}
{% endhighlight %}

This time, I've asked for storage for ten million integers, but only initialized a not-entirely-randomly selected integer to zero.
Now, how much additional memory, compared to the third program, do you think this program will use?
On my system, it uses 2 MB of additional memory compared to the third program.
When I changed it to initialize only the first integer, or just the last integer to zero, that additional memory dropped down to about 8 bytes or so.
Again, I encourage you to try this out for yourself.
For bonus points, initialize some, but not all of the integers and watch how repeatable the memory usage is.
On my system, I find that for less than half a million integers, the additional memory usage soon jumps and stays constant at 2 MB.
Once this is crossed, however, the memory usage reported is erratic and not repeatable, until it reaches 38 MB when all ten million integers have been initialized.
I would now really love to know what's going on.

I don't know this for sure, but here's my best guess.
The heap manager doesn't always allocate the exact amount of memory you ask for, particularly when you're squabbling over relatively tiny amounts like 4 bytes.
In such cases, the heap manager would just allocate a larger chunk of memory and move on to do more important things.
This plays into heap memory alignment where the heap manager always ensures that there is a minimum value of allocated space that matches up with the length of an instruction (on IA32 systems, a word is 32 bits long, for instance).
In any case, the memory alignment plays into how much additional memory is allocated when the heap manager receives ten million calls for 4 bytes each.

Even so, I can't explain the odd behavior when a large array is partially initialized.
If you have any additional information or corrections, feel free to share here.

