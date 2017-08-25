---
title: Finding the longest sorted subsequence
layout: post
categories: [ puzzles ]
tags: [ ruby ]
comments: true
---

Another problem to solve, the problem statement goes like this,
Given a sequence of numbers, find the longest subsequence that is sorted in ascending order when the relative ordering of the elements is preserved.
For instance, given [ 1, 0, 2, 1, 3, 2, 4, 3, 5 ], we should find the sorted subsequence, [ 1, 2, 3, 4, 5 ].

A very basic implementation of a solution would cycle through each element of the original sequence and record all possible subsequences that this element could be a part of.
If the new element is larger than all elements of a known subsequence, the subsequence gets one element longer.
If the new element is smaller than all elements so far, it gets to start its own subsequence.
If a subsequence has elements both smaller and larger than the new element, a new subsequence can be started with the smaller elements with the new element at the end.
This effectively ends up creating a set of all possible sorted subsequences.
In the end, the longest of these possibilities is the answer.

Here's the solution implemented in ruby.

{% highlight ruby linenos %}
#!/usr/bin/env ruby

# Return the longest sorted subsequence

def getLongestSortedSubsequence( inputArray )
    subsequences = Array.new

    inputArray.each do | element |
        subsequences.each do | subsequence |
            # Add element to already known subsequences, if possible
            subsequence.push element if subsequence.last < element

            # Create new subsequences if necessary
            if subsequence.last > element
                newSubsequence = subsequence.select { | x | x < element }
                newSubsequence.push element
                subsequences.push newSubsequence if not subsequences.include? newSubsequence
            end
        end

        # Start a subsequence if none exist yet
        subsequences.push [ element ] if subsequences.empty?
    end

    # Return the longest of subsequences
    return subsequences.max { | a, b | a.length <=> b.length }
end

puts "Longest sorted subsequence is #{ getLongestSortedSubsequence [ 1, 3, 2, 2, 3, 1, 4, 0, 5 ] }"
{% endhighlight %}

Now, let's estimate the order of efficiency of this algorithm.
We cycle through the elements of the sequence once, so that's at least linear in the number of elements.
Next, when comparing the current element to all the previous subsequences, the worst case happens if the elements in the input array are in descending order.
That introduces a linear term again in the number of elements in the array.
Finally, there's a possible search for elements in subsequences smaller than the current element.
The efficiency of this step depends on how ruby implements select, and could be in constant time if the subsequences are hashed.
So, this solution runs in at least O(n²) time, compared to the best known solution, outlined [here](http://en.wikipedia.org/wiki/Longest_increasing_subsequence), which runs in linear time.

