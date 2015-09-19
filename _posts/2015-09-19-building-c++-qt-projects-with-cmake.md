---
title: Building C++/Qt projects with CMake
layout: post
categories: [ user guides ]
tags: [ C++, Qt, cmake ]
comments: true
---

Make files are convenient ways of recording and replaying a sequence of commands needed to build a program from source.
You define targets like `install` or `clean` and tell make what it needs to do to "reach" those targets.
Make is clever enough to skip steps that do not need to be executed, say if no files have changed since the last compilation step.
It would be fair to say that I enjoy everything about using make files except actually writing them.

Fortunately, there is no shortage of tools that will write a make file for you if all you need to do are well-known, standard steps.
My go-to tool for C++/Qt programs has been cmake.
I'll document what I know so far in this post.

A simple hello-world style program would normally be compiled manually like this.

{% highlight console %}
$ g++ main.cpp -o main
{% endhighlight %}

This can be compiled using a cmake file like this.

{% highlight cmake %}
cmake_minimum_required( VERSION 2.6 )

project( helloworld )

add_executable( helloworld hello.cpp )
{% endhighlight %}

This is saved as `CMakeLists.txt` in the same directory as `hello.cpp`.
When it's time to build it, it's generally built out of source, in a separate directory to keep the source code directory clean.

{% highlight console %}
$ mkdir build
$ cd build/
$ cmake ..
$ make
{% endhighlight %}

# Qt4

To compile a basic Qt4 application, we need a few more steps on top of this.
First, we need to find where the Qt4 files are installed.

{% highlight cmake %}
find_package( Qt4 REQUIRED )
{% endhighlight %}

This uses a cmake file that ships with cmake to find the location of the Qt4 install and sets up a few useful variables.
One such is the location of the Qt header files.

{% highlight cmake %}
include ( ${QT_USE_FILE} )
{% endhighlight %}

And finally, we need to link the Qt libraries to the executable.

{% highlight cmake %}
target_link_libraries( helloworld ${QT_LIBRARIES} )
{% endhighlight %}

If the source code needs to use macros like `Q_OBJECT`, we need to use `moc` to generate valid C++ code for `g++` to compile.

{% highlight cmake %}
qt4_wrap_cpp( moc_sources header.h )

add_executable( helloworld hello.cpp ${moc_sources} )
{% endhighlight %}

Similarly, if you have UI files that need to run `uic` to generate valid C++ code, they need to be processed similarly.

{% highlight cmake %}
qt4_wrap_ui( ui_sources hello.ui )

add_executable( helloworld hello.cpp ${ui_sources} )
{% endhighlight %}

And lastly, if you have resource files, there's one more command.

{% highlight cmake %}
qt4_add_resources( qrc_sources hello.qrc )

add_executable( helloworld hello.cpp ${qrc_sources} )
{% endhighlight %}

Put it all together and a typical Qt4 program might need to be compiled like this,

{% highlight cmake %}
# Version information for CMake
cmake_minimum_required( VERSION 2.6 )

# Name of the project
project( helloworld )

# Find Qt
find_package( Qt4 REQUIRED )

# Include Qt headers
include( ${QT_USE_FILE} )

# C++ source files
set( cpp_sources hello.cpp main.cpp )

# MOC headers
qt4_wrap_cpp( moc_sources hello.h )

# UI files
qt4_wrap_ui( ui_sources hello.ui )

# Resource files
qt4_add_resources( qrc_sources hello.qrc )

# create executable
add_executable( helloworld ${cpp_sources} ${moc_sources} ${ui_sources} ${qrc_sources} )

# Link Qt libraries
target_link_libraries( helloworld ${QT_LIBRARIES} )
{% endhighlight %}

With all this, you might be wondering if it isn't simpler to just use make files or even Qt's qmake.
wonder no more.
If you have---and you probably do---a newer version of cmake (3.0 and above), you can use automatic properties to get the `moc`, UI and resource files automatically processed.

Cmake will scan your C++ files, read through the included headers and decide whether they need to use `moc`.
If they do, it will run `moc` and put the resulting `moc_*.cpp` and `*.moc` files in the build/ directory.
These should be included in the C++ file and we need to tell cmake where it can finde these files using a new variable.

{% highlight cmake %}
cmake_minimum_required( VERSION 3.3 )

set( CMAKE_AUTOMOC ON )
set( CMAKE_INCLUDE_CURRENT_DIR ON )
{% endhighlight %}

Similarly, UI files can be processed if the C++ files include a header file called `ui_hello.h` and there's a `hello.ui` file present.
Again, the resulting ui_*.h files will be placed in the build directory, so we need to make sure to tell cmake to include the current directory.

{% highlight cmake %}
set( CMAKE_AUTOUIC ON )
{% endhighlight %}

Lastly, resource files are handled if any of the sources have a ".qrc" extension.
Note that you still need to include the file in the `add_executable` arguments.

{% highlight cmake %}
set( CMAKE_AUTORCC ON )
{% endhighlight %}

The new spiffy `CMakeLists.txt` now looks like this,

{% highlight cmake %}
# Version information for CMake
cmake_minimum_required( VERSION 3.3 )

# Name of the project
project( helloworld )

# Find Qt
find_package( Qt4 REQUIRED )

# Include Qt headers
include( ${QT_USE_FILE} )

# Include the build directory contents
set( CMAKE_INCLUDE_CURRENT_DIR ON )

# C++ source files
set( cpp_sources hello.cpp main.cpp )

# Automatically handle MOC headers
set( CMAKE_AUTOMOC ON )

# Automatically handle UI files
set( CMAKE_AUTOUIC ON )

# Automatically handle resource files
set( CMAKE_AUTORCC ON )
set( qrc_sources hello.qrc )

# create executable
add_executable( helloworld ${cpp_sources} ${qrc_sources} )

# Link Qt libraries
target_link_libraries( helloworld ${QT_LIBRARIES} )
{% endhighlight %}

# Qt5

For the most part, as far as cmake is concerned, going from Qt4 to Qt5 is just a matter of switching the property names from qt4* to qt5*.
So, `qt4_wrap_cpp` would become `qt5_wrap_cpp`, etc.
There are some other notable differences.
Qt5 is much more modular and the `find_package` command needs to either be told to find a specific set of modules or components.

{% highlight cmake %}
find_package( Qt5 COMPONENTS Widgets REQUIRED )
{% endhighlight %}

or

{% highlight cmake %}
find_package( Qt5Widgets REQUIRED )
{% endhighlight %}

Similarly, when linking libraries to target, we need to be more specific,

{% highlight cmake %}
target_link_libraries( helloworld Qt5::Widgets )
{% endhighlight %}

There is also no need to include the `QT_USE_FILE` explicitly.
So, the Qt5 version of the `CMakeLists.txt` looks pretty similar to the Qt4 one we just looked at.

{% highlight cmake %}
# Version information for CMake
cmake_minimum_required( VERSION 3.3 )

# Name of the project
project( helloworld )

# Find Qt
find_package( Qt5Widgets REQUIRED )

# Include the build directory contents
set( CMAKE_INCLUDE_CURRENT_DIR ON )

# C++ source files
set( cpp_sources hello.cpp main.cpp )

# Automatically handle MOC headers
set( CMAKE_AUTOMOC ON )

# Automatically handle UI files
set( CMAKE_AUTOUIC ON )

# Automatically handle resource files
set( CMAKE_AUTORCC ON )
set( qrc_sources hello.qrc )

# create executable
add_executable( helloworld ${cpp_sources} ${qrc_sources} )

# Link Qt libraries
target_link_libraries( helloworld Qt5::Widgets )
{% endhighlight %}

