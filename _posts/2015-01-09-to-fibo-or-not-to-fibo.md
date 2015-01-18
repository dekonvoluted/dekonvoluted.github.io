---
title: To Fibo or not to Fibo
layout: post
categories: [ puzzles ]
tags: [ C++ ]
comments: true
---

Over the break, I got to solve a problem that went something like this:
Given a list of numbers, determine whether each of them is found in the Fibonacci series or not.
The input is a file with the first line containing the number of values to be tested, followed by each value on a separate line.
It is stated that the count will be a positive integer between 1 and a hundred thousand, while the values themselves---also positive integers---could go as high as ten billion.

# By the power of ...φ!

A question like this suggests that there is a neat property that each number in the Fibonacci sequence would satisfy, and [there is](http://en.wikipedia.org/wiki/Fibonacci_number#Recognizing_Fibonacci_numbers).
I didn't know this property, but I did know that ratios of successive terms in the series tend to the golden ratio, φ = 1.618033988.
My first attempt was to try and use this to check a given number.
I reasoned that if I could divide a number again and again by φ, and get very close to unity, that number is a Fibonacci number.

This actually fails miserably and you can check it by trying to prepare a list of Fibonacci numbers using the powers of φ.
In the table below, `F` is one of the terms of the Fibonacci series which when multiplied or divided by φ, will/should produce its adjacent terms, after rounding to the nearest integer.
I've picked `x` and `y` for each case so that I get the terms between 1 and 89.

F | `[ round( F * ( phi ** i ) ) for i in range( x, y ) ]`
:-:| :-:
1 | [1, 2, 3, 4, 7, 11, 18, 29, 47, 76]
2 | [1, 2, 3, 5, 8, 14, 22, 36, 58, 94]
3 | [1, 2, 3, 5, 8, 13, 21, 33, 54, 87]
5 | [1, 2, 3, 5, 8, 13, 21, 34, 55, 90]
8 | [1, 2, 3, 5, 8, 13, 21, 34, 55, 89]

Reaching about midway through the sequence at F = 8 actually produces the correct series. However, you can always find a higher term in the series that will be incorrectly calculated by this.

# Prepare for overflow!

So, I fell back to the idea of having to count up the series to check each one.
I was apprehensive of this not working because I figured that there could be several terms under ten billion and I might even run out of memory.
I didn't realize that the Fibonacci series actually grows quite rapidly, crossing each order of magnitude in just four-five steps.
You can check this for yourself:

{% highlight cpp linenos %}
#include <iostream>
#include <sstream>

int main( int argc, char** argv )
{
    if ( argc != 2 ) return 1;

    long target = 0;
    std::stringstream( argv[ 1 ] ) >> target;
    if ( target < 1 ) return 1;

    long a = 0;
    long b = 1;
    int counter = 0;
    std::cout << ++counter << ": " << b << std::endl;

    while ( b <= target ) {
        b = a + b;
        a = b - a;
        std::cout << ++counter << ": " << b << std::endl;
    }

    return 0;
}
{% endhighlight %}

If you compile this and run it, you'll see that only 36 terms are needed to cross a million and ten billion is reached in just 50 terms.

1: 1\\
2: 1\\
3: 2\\
...\\
35: 9227465\\
36: 14930352\\
...\\
49: 7778742049\\
50: 12586269025

You'd have also noticed the use of `long` instead of `int` or even `auto`.
This is to avoid integer overflow as integers only go up to two billion or so.

Of course, all this was realized in hindsight.
I coded this solution thinking it was a brute force solution and I would come up with a more elegant solution once I get it working.

{% highlight cpp linenos %}
#include <iostream>
#include <algorithm>
#include <vector>
#include <fstream>

typedef long num;

int main()
{
    std::vector<num> series{ 1, 1 };

    std::ifstream infile;
    infile.open( "list.txt", std::ios::in );

    num total = 0;
    num number = 0;

    infile >> total;

    for ( num i = 0; i < total; ++i ) {
        infile >> number;

        while ( series.back() < number ) {
            series.push_back( series.back() + *(series.end() - 2) );
        }

        if ( std::find( series.begin(), series.end(), number ) != series.end() ) {
            std::cout << number << " isFibo" << std::endl;
        } else {
            std::cout << number << " isNotFibo" << std::endl;
        }
    }

    infile.close();
}
{% endhighlight %}

Notice the `typedef` changing all the numbers to `long` from `int` after I hit an integer overflow.
Each input is read and series terms are calculated only if needed.
Previous terms are cached in a vector.

Because the number of Fibonacci terms under ten billion is so small, this code runs extremely quickly.
The slowest operation here might be the resizing of the vector that's needed every time the number of terms increases past a power of two.
But without knowing the number of series terms that can be expected, I figured there was no point in reserving an arbitrary amount of memory for the vector.

