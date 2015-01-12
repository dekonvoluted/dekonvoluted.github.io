---
title: Finding the nth prime
layout: post
categories: [ puzzles ]
tags: [ C++, python ]
---

Here's a puzzle that I played with a few years ago when I was learning python.
The aim is to write a program that will accept one argument, `n`, and print out the nth prime.
Something like,

{% highlight console %}
$ ./nthprime 1000
7919
{% endhighlight %}

Here's my solution from back then.
Since 2 is tricky, let's initialize our list of primes with 2.
Count from 3 onwards till we've found the requisite number of primes.
For each number, test divisibility by all the primes known before it.
To save time, we only need to test divisibility for primes whose squares are less than the candidate number.
To further save time, we'll count up in steps of two (skipping all even numbers entirely.
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

{% highlight console %}
$ g++ --std=c++11 -o nth-prime nth-prime.cpp
$ time ./nth-prime 1000
7919

real    0m0.004s
user    0m0.003s
sys     0m0.000s
{% endhighlight %}

Okay, to get to a thousand primes, it just took 4 ms.

{% highlight console %}
$ time ./nth-prime 100000
1299709

real    0m0.799s
user    0m0.797s
sys     0m0.000s
{% endhighlight %}

Hmm.
It gets to a hundred thousand prime numbers in 0.8 seconds.

{% highlight console %}
$ time ./nth-prime 1000000
15485863

real    0m21.242s
user    0m21.240s
sys     0m0.003s
{% endhighlight %}

What?!
A million primes takes twenty seconds?!
Unacceptable.
Let's compile with optimization to see if that makes a difference.

{% highlight console %}
$ g++ --std=c++11 -O1 -o nth-prime nth-prime.cpp
$ time ./nth-prime 1000000
15485863

real    0m2.230s
user    0m2.227s
sys     0m0.003s
{% endhighlight %}

Whoa!
Using -O1 cuts this down to just over two seconds to find the millionth prime number.
I wonder if -O2 or -O3 would do even better...

{% highlight console %}
$ g++ --std=c++11 -O2 -o nth-prime nth-prime.cpp
$ time ./nth-prime 1000000
15485863

real    0m2.239s
user    0m2.237s
sys     0m0.000s
{% endhighlight %}

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

{% highlight console %}
$ g++ --std=c++11 -O1 -o nth-prime nth-prime.cpp
$ time ./nth-prime 1000000
15485863

real    0m2.245s
user    0m2.243s
sys     0m0.000s
{% endhighlight %}

Wait, we got *slower*?

{% highlight console  %}
$ time ./nth-prime 1000000
15485863

real    0m2.246s
user    0m2.240s
sys     0m0.003s
{% endhighlight %}

Yup.
We definitely got a tad bit slower.
Could higher optimization levels help us now?

{% highlight console %}
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
{% endhighlight %}

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

{% highlight console %}
$ g++ --std=c++11 -O2 -o nth-prime nth-prime.cpp
$ time ./nth-prime 1000000
15485863

real    0m2.216s
user    0m2.213s
sys     0m0.000s
{% endhighlight %}

Well, that's about as far as it goes with C++, I guess.
Still, 2.2 seconds to the millionth prime isn't too shabby.

Let's try implementing the same algorithm in python.
Now, python is interpreted and so we'll use the benefit of all that we learned speeding up the code in C++ to help it run as fast as possible.

{% highlight python linenos %}
#!/usr/bin/env python

n = 1000000

# Start with 2 already added to list
# Reserve enough memory
primes = [ 2 ] * n
primesq = [ 4 ] * n

primesFound = 1

# Test only odd numbers
primeCount = 0
isPrime = True;
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

    primeCount = 1
    candidate += 2

print( primes[ n - 1 ] )
{% endhighlight %}

Okay how bad can it be?

{% highlight console %}
$ chmod +x ./nth-prime.py
$ time ./nth-prime.py
15485863

real    5m6.184s
user    5m5.923s
sys     0m0.193s
{% endhighlight %}

The above results were obtained with gcc 4.9.2 and python 3.4.2 on a Core i7 920 machine with 9 GB of RAM (I doubt that mattered too much).

From my notes from back then (2011), on the computer I was testing this out on, C++ got to the millionth prime in 11 seconds, python took 10 minutes and a second and MATLAB took 4 minutes and 40 seconds.
Of course, all of that testing was done with different versions of gcc and python, so the numbers haven't scaled evenly.

So, anyway, that's why I stayed away from scripting languages as much as possible.
Sorry, python, sorry, ruby.
I should have learned to appreciate you two earlier...

