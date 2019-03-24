---
title: Using CMake's AUTOMOC correctly
layout: post
categories: [ programming ]
tags: [ CMake, Qt, moc, C++ ]
comments: true
---

Consider the following project:

```
repository/
|- CMakeLists.txt
`- src/
    |- main.cpp
    |- mainwindow.hpp
    `- mainwindow.cpp
```

Here's the main cpp file:

{% highlight cpp linenos %}
// File: main.cpp

#include "mainwindow.hpp"

#include <QApplication>

int main(int argc, char** argv)
{
    QApplication app(argc, argv);

    auto mainWindow = new MainWindow()
    mainWindow->show();

    return app.exec();
}
{% endhighlight %}

Here's the implementation of the main window class.
First, the header,

{% highlight cpp linenos %}
// File: mainwindow.hpp

#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>

class MainWindow : public QMainWindow
{
    Q_OBJECT

    public:
    MainWindow(QWidget* parent = 0);
    ~MainWindow() override = default;
};

#endif
{% endhighlight %}

and then, the cpp file,

{% highlight cpp linenos %}
// File: mainwindow.cpp

#include "mainwindow.hpp"

#include <QPushButton>

MainWindow::MainWindow(QWidget* parent) : QMainWindow(parent)
{
    // Display a simple pushbutton
    auto helloButton = new QPushButton("Hello");
    this->setCentralWidget(helloButton);
}
{% endhighlight %}

We wish to compile and run this program.
Here's what a modern CMake file would look like,

{% highlight cmake linenos %}
# File: CMakeLists.txt

cmake_minimum_required(VERSION 3.14)

project(test)

# Find Qt5 libraries
find_package(Qt5 REQUIRED COMPONENTS Core Widgets)

# Build the executable
add_executable(test)

target_sources(test PRIVATE src/main.cpp)
target_sources(test PRIVATE src/mainwindow.cpp)

set_target_properties(test PROPERTIES AUTOMOC ON)

target_link_libraries(test PRIVATE Qt5::Core)
target_link_libraries(test PRIVATE Qt5::Widgets)

install(TARGETS test RUNTIME DESTINATION bin)
{% endhighlight %}

The question is what needs to change, if anything, to make this work correctly with Qt's moc?
The conventional wisdom regarding moc is that if the moc-macro (here `Q_OBJECT`) exists in the header, you don't need to do anything. If the macro exists in the source, in the cpp file, then, you need to add an include at the end of the cpp file, `#include "mainwindow.moc"` so that the moc output is included in the compilation.
Since our macro exists in the header, by this reckoning, we can just leave things well enough alone and compile.
And sure enough, it compiles.

But what happens if I move the included headers to a separate location?
I change the repo's layout to this,

```
repository/
|- CMakeLists.txt
|- include/
|   |- mainwindow.h
`- src/
    |- main.cpp
    `- mainwindow.cpp
```
To account for this, I'll change the CMake file to specify that included headers should be found in the `include/` directory.

```diff
--- CMakeLists.txt
+++ CMakeLists.txt
@@ -13,7 +13,8 @@
  # Build the executable
  add_executable(test)

+ target_include_directories(test PRIVATE include/)
  target_sources(test PRIVATE src/main.cpp)
  target_sources(test PRIVATE src/mainwindow.cpp)

```

When compiling now, you will now get an error about a missing vtable.

```
/bin/ld: CMakeFiles/encode.dir/src/mainwindow.cpp.o: in function `MainWindow::MainWindow(QWidget*)':
mainwindow.cpp:(.text+0x27): undefined reference to `vtable for MainWindow'
collect2: error: ld returned 1 exit status
make[2]: *** [CMakeFiles/encode.dir/build.make:117: encode] Error 1
```

This is extremely weird.
There's no reason for what was just now working to break like this just because you relocated the included header file.
The issue is that moc output from the header file is no longer being included in the compilation.
But why?

Here are the "wrong" solutions to this problem.

1. Trying to go back to using `qt_wrap_cpp()` or similar macros to "wrap" the header file and get moc to notice the header file.
2. Adding the header file to the list of target sources. Yuck.

And here's the right answer.
The way CMake's automoc functionality works, it scans header and cpp files in a project for Qt macros.
If it finds a header file with a macro, it generates a file called `moc_<filename>.cpp`.
If it finds a cpp file with a macro, it generates a file called `<filename>.moc`.
Now, normally, these generated files are included in the combined moc file called `mocs_compilation.cpp`.
This works beautifully if the header and cpp files are together in the same directory, but unfortunately fails if the header is found through the target's `INCLUDE_DIRECTORIES` property.
I consider this to be a bug, but whatever.

So, the nicest option to fix this problem is to *always* include either `moc_<filename>.cpp` or `<filename>.moc` at the end of the implementation cpp file.
This way, the project setup is immune to relocations of the header file.
Now, the relative location of the HPP/CPP files no longer matters as long as you tell CMake where to find the include files using `target_include_directories()`.

I revisit this issue every time I start a Qt project, so here's a handy table summarizing how to never worry about moc again:

| HPP file | CPP file | Changes to end of CPP file | Changes to CMake file |
| :--- | :--- | :--- | :--- |
| No Qt macros | No Qt macros | Nothing to do! | Nothing to do! |
| No Qt macros | Has Qt macros | + `#include "<name>.moc"` | + `set_target_properties(<target> PROPERTIES AUTOMOC ON)` |
| Has Qt macros | No Qt macros | + `#include "moc_<name>.cpp"` | + `set_target_properties(<target> PROPERTIES AUTOMOC ON)` |
| Has Qt macros | Has Qt macros | + `#include "moc_<name>.cpp"`<br>+ `#include "<name>.moc"` | + `set_target_properties(<target> PROPERTIES AUTOMOC ON)` |

