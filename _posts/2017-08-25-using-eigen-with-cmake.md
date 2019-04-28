---
title: Using Eigen with CMake
layout: post
categories: [ user guides ]
tags: [ C++, eigen, cmake ]
---

Here's how you would write a CMake file to compile some C++ code using the [Eigen](http://eigen.tuxfamily.org/index.php?title=Main_Page) linear algebra library.
First, an example C++ source file.

{% highlight cpp linenos %}
#include <Eigen/Dense>

#include <iostream>

int main()
{
    Eigen::MatrixXd m = Eigen::MatrixXd::Random( 5, 5 );
    std::cout << "Original matrix: \n";
    std::cout << m;

    std::cout << "Transpose: \n";
    std::cout << m.transpose();
}
{% endhighlight %}

Here's the corresponding CMake file.

{% highlight cmake linenos %}
# Set minimum required version
cmake_minimum_required( VERSION 3.9.1 )

# Name the project
project( C++-Eigen-Example )

# Find the Eigen config file and use it
find_package( Eigen3 3.3.4 REQUIRED CONFIG )

# Add source code to the manifest
set( CPP_SOURCES main.cpp )

# Build executable
add_executable( main ${CPP_SOURCES} )
target_link_libraries( main Eigen3::Eigen )
{% endhighlight %}

Note the use of the [`find_package`](https://cmake.org/cmake/help/v3.9/command/find_package.html) call with the `CONFIG` (or equivalently, [`NO_MODULE`](https://eigen.tuxfamily.org/dox/TopicCMakeGuide.html)) option.
This causes CMake to locate and use a config file called `Eigen3Config.cmake` which it will end up finding in `/usr/share/eigen3/cmake/`.
That file will define a target called `Eigen3::Eigen` containing a set of instructions to include the Eigen headers in the main target.
"Linking" this library to the executable will cause the headers to be included during compilation, making everything work.

By the way, this works for Eigen versions 3 and above, using CMake versions 3 and above.
I've used Eigen 3.3.4 and CMake 3.9.1 above, just because they are the current versions at the time of writing.

