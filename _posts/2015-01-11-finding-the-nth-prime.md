---
title: Finding the nth prime
layout: post
categories: [ puzzles ]
tags: [ C++, python ]
---

Here's a puzzle that I played with a few years ago when I was learning python.
The aim is to write a program that will accept one argument, `n`, and print out the nth prime.
Something like,

    $ ./nthprime 1000
    7919

Here's my solution from back then.
Since 2 is tricky, let's initialize our list of primes with 2.
Count from 3 onwards till we've found the requisite number of primes.
For each number, test divisibility by all the primes known before it.
To save time, we only need to test divisibility for primes whose squares are less than the candidate number.
To further save time, we'll count up in steps of two (skipping all even numbers entirely).
Also, since we're skipping even numbers entirely, we needn't test divisibility by two, except for 3.

{% highlight cpp linenos %}
#include <iostream>
#include <sstream>
#include <vector>

int main( int argc, char** argv )
{
    if ( argc != 2 ) return 1;

    auto n = 0;
    std::stringstream( argv[ 1 ] ) >> n;
    if ( n < 1 ) return 1;

    // Start with 2 already added to list
    std::vector<int> primes{ 2 };

    // Test only the odd numbers
    auto isPrime = true;
    auto primeCount = 0;
    for ( auto candidate = 3; primes.size() < n; candidate += 2 ) {
        // Test divisibility by all primes up to sqrt of candidate
        while ( primes.at( primeCount ) * primes.at( primeCount ) <= candidate ) {
            if ( candidate % primes.at( primeCount++ ) == 0 ) {
                isPrime = false;
                break;
            }
        }

        if ( isPrime ) primes.push_back( candidate );
        else isPrime = true;

        // No need to test divisibility by 2
        primeCount = 1;
    }

    std::cout << primes.back() << std::endl;

    return 0;
}
{% endhighlight %}

Let's compile this and check how long it takes to get to the millionth prime.

    $ g++ --std=c++11 -o nth-prime nth-prime.cpp
    $ time ./nth-prime 1000
    7919

    real    0m0.004s
    user    0m0.003s
    sys     0m0.000s

Okay, to get to a thousand primes, it just took 4 ms.

    $ time ./nth-prime 100000
    1299709

    real    0m0.799s
    user    0m0.797s
    sys     0m0.000s

Hmm.
It gets to a hundred thousand prime numbers in 0.8 seconds.

    $ time ./nth-prime 1000000
    15485863

    real    0m21.242s
    user    0m21.240s
    sys     0m0.003s

What?!
A million primes takes twenty seconds?!
Unacceptable.
Let's compile with optimization to see if that makes a difference.

    $ g++ --std=c++11 -O1 -o nth-prime nth-prime.cpp
    $ time ./nth-prime 1000000
    15485863

    real    0m2.230s
    user    0m2.227s
    sys     0m0.003s

Whoa!
Using -O1 cuts this down to just over two seconds to find the millionth prime number.
I wonder if -O2 or -O3 would do even better...

    $ g++ --std=c++11 -O2 -o nth-prime nth-prime.cpp
    $ time ./nth-prime 1000000
    15485863

    real    0m2.239s
    user    0m2.237s
    sys     0m0.000s

Yeah, no that's about as far as we can ride this pony.
Now, let's try to see if the code could be optimized further.
There's no need to calculate the squares of the primes again and again.
Let's cache them and see if this has any effect.

{% highlight diff %}
diff --git a/nth-prime.cpp b/nth-prime.cpp
index 6f5113e..a6722e4 100644
--- a/nth-prime.cpp
+++ b/nth-prime.cpp
@@ -12,21 +12,24 @@ int main( int argc, char** argv )

     // Start with 2 already added to list
     std::vector<int> primes{ 2 };
+    std::vector<int> primeSquares{ 4 };

     // Test only the odd numbers
     auto isPrime = true;
     auto primeCount = 0;
     for ( auto candidate = 3; primes.size() < n; candidate += 2 ) {
         // Test divisibility by all primes up to sqrt of candidate
-        while ( primes.at( primeCount ) * primes.at( primeCount ) <= candidate ) {
+        while ( primeSquares.at( primeCount ) <= candidate ) {
             if ( candidate % primes.at( primeCount++ ) == 0 ) {
                 isPrime = false;
                 break;
             }
         }

-        if ( isPrime ) primes.push_back( candidate );
-        else isPrime = true;
+        if ( isPrime ) {
+            primes.push_back( candidate );
+            primeSquares.push_back( candidate * candidate );
+        } else isPrime = true;

         // No need to test divisibility by 2
         primeCount = 1;
{% endhighlight %}

Okay, time to test this.

    $ g++ --std=c++11 -O1 -o nth-prime nth-prime.cpp
    $ time ./nth-prime 1000000
    15485863

    real    0m2.245s
    user    0m2.243s
    sys     0m0.000s

Wait, we got *slower*?

    $ time ./nth-prime 1000000
    15485863

    real    0m2.246s
    user    0m2.240s
    sys     0m0.003s

Yup.
We definitely got a tad bit slower, presumably from having to store and retrieve the squares of all the primes found so far.
Could higher optimization levels help us now?

    $ g++ --std=c++11 -O2 -o nth-prime nth-prime.cpp
    $ time ./nth-prime 1000000
    15485863

    real    0m2.224s
    user    0m2.217s
    sys     0m0.007s
    $ g++ --std=c++11 -O3 -o nth-prime nth-prime.cpp
    $ time ./nth-prime 1000000
    15485863

    real    0m2.222s
    user    0m2.217s
    sys     0m0.003s

So, caching the squares managed to save us about 10 ms at the end of the day.
What if we reserve space for the vectors ahead of time, since we already know that we're out to find the first `n` primes?

{% highlight diff %}
diff --git a/nth-prime.cpp b/nth-prime.cpp
index a6722e4..236d84d 100644
--- a/nth-prime.cpp
+++ b/nth-prime.cpp
@@ -14,6 +14,9 @@ int main( int argc, char** argv )
     std::vector<int> primes{ 2 };
     std::vector<int> primeSquares{ 4 };

+    primes.reserve( n );
+    primeSquares.reserve( n );
+
     // Test only the odd numbers
     auto isPrime = true;
     auto primeCount = 0;
{% endhighlight %}

Yeah, let's try that.

    $ g++ --std=c++11 -O2 -o nth-prime nth-prime.cpp
    $ time ./nth-prime 1000000
    15485863

    real    0m2.216s
    user    0m2.213s
    sys     0m0.000s

That shaved off another 10 ms, but I'm starting to run out of ideas and it looks like that's as far as this goes with C++.
Still, 2.2 seconds to the millionth prime isn't too shabby.

Let's try implementing the same algorithm in python.
Now, python is interpreted and that puts it at a disadvantage, particularly since we asked the compiler to optimize the code.
Let's run this without any compiler optimization.

    $ g++ --std=c++11 -o nth-prime nth-prime.cpp
    $ time ./nth-prime 1000000
    15485863

    real    0m14.152s
    user    0m14.143s
    sys     0m0.007s

Okay, so it takes about 14 seconds to hit the millionth prime.
Now, let's use all the tricks we learned so far to get python off to a speedy start.

{% highlight python linenos %}
#!/usr/bin/env python

import sys

def nth_prime( n ):
    '''Return the nth prime number'''

    if ( n < 1 ):
        return None

    # Start with 2 already added to the list
    # Reserve enough memory
    primes = [ 2 ] * n
    primesq = [ 4 ] * n

    primesFound = 1
    primeCount = 0
    isPrime = True
    candidate = 3

    while primesFound < n:
        while primesq[ primeCount ] <= candidate:
            if candidate % primes[ primeCount ] == 0:
                isPrime = False
                break
            primeCount += 1

        if isPrime:
            primes[ primesFound ] = candidate
            primesq[ primesFound ] = candidate * candidate
            primesFound += 1
        else:
            isPrime = True

        # Test from 3 onwards and skip all even numbers
        primeCount = 1
        candidate += 2

    return primes[ n - 1 ]

print( nth_prime( int( sys.argv[ 1 ] ) ) )
{% endhighlight %}

Okay, we only test odd numbers, cache all the previous primes and their squares and only test divisibility with primes smaller than the square root of a number.
Let's see how fast this runs.

    $ chmod +x ./nth-prime.py
    $ time ./nth-prime.py 1000000
    15485863

    real    2m53.168s
    user    2m52.970s
    sys     0m0.150s

Oh wow.
The same implementation in python runs about ten times slower than the *slowest* it ran in C++ (without compiler optimizations).
Compared to the 2.2 seconds we could pare the C++ time down to, python's 170 second run time looks very pitiable indeed.

I'm sure this can be sped up further as I get more comfortable with python, but this is consistent with my notes from 2011 when I was just starting to play with python.
On the computer I was testing this out on then, C++ got to the millionth prime in 11 seconds, and python took almost 17 minutes before I optimized the code down to a hair over 10 minutes.
At the time, I was also using MATLAB, which took 4 minutes and 40 seconds to work through the same algorithm.
Of course, all of that testing was done with different versions of gcc and python, and the older code was a little ...different, so the numbers haven't scaled evenly.

So, anyway, the results of this experiment was largely why I avoided using python to process the data for my thesis.
This also meant that I generally avoided using both python and ruby for a very long time because I always thought of them as slow lumbering beasts.
It's only recently that I started rediscovering ruby and began appreciating just how easy it is to get things done with it.

For the record, the above results were obtained with gcc 4.9.2 and python 3.4.2 on a Core i7 920 machine with 9 GB of RAM.

