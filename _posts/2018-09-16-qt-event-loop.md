---
title: Understanding Qt's Event Loop and Signals/Slots
layout: post
categories: [ programming ]
tags: [ C++, Qt ]
---

I had a bit of trouble wrapping my head around the idea of Qt's event loop and how it relates to the signals and slots mechanism.
Here are my notes from what I learned.

Qt's event loop starts the moment the underlying application's `exec()` function gets called.
Once started, the loop repeatedly checks for something to happen in the system, such as user-input through keyboard/mouse.
When it detects such stimuli, it creates an instance of a `QEvent` and directs it at the `QObject` instance that's at the top of the object tree.
This is done by calling the `QObject`'s `event()` function (thus `QEvent`s are expected to be handled by `QObject`s).
The top-level `QObject` may implement an event handler for this specific event type, or simple pass it on to its children (it may decide which child to pass it on to, of course).
At any point in the object tree, a `QObject` could choose to implement a handler and consume the event without passing it on to its children.
Eventually, one way or another, the event is handled or simply disregarded by a `QObject` with an appropriate handler.

As an example, let's click a `QPushButton` sitting within a `QWidget`.
The `QMouseEvent` arrives at `QWidget`'s `event()` function and it decides, based on the coordinates of the mouse click, that the event is the `QPushButton`'s problem to handle.
So, it calls `QPushButton`'s `event()` function with the event.
If the `QPushButton` were disabled, it would simply do nothing.
If, on the other hand, the `QPushButton` is not disabled, it will react to this `QMouseEvent` by emitting its `clicked()` signal.

This brings us to signals and slots.
`QObject`s react to `QEvent`s by implementing event handlers, functions that receive an event of a specific type and do something with it.
Often, "doing something with it" includes emitting a signal to let everyone know that it is reacting to this event.
Unlike events, which were directed at a specific `QObject`, signals are just broadcast without a target.
Slots connected to this emitted signal are then executed one by one, in the order in which they were connected to the signal.
For now, I assume these connected slots (and their objects) are in the same thread as the signal.

At this point, it is useful to note that the `Q{Core,Gui,}Application`'s `quit()` or `exit()` slots actually do not quit or exit the application immediately.
Instead, they tell the event loop to quit or exit when control return to the event loop.
This behavior of pushing an event onto the event loop (as a `Qt::QueuedConnection`) tripped me up because I expected the slot would be immediately executed and the application would stop dead in its tracks and quit.

Once all the slots connected to signals triggered by events are executed, the control will eventually return back to the main event loop and the cycle begins anew.

Let's verify all this with a simple example.

{% highlight cpp linenos %}
#include <QDebug>

#include <QCoreApplication>
#include <QObject>
#include <QTimer>

class Foo : public QObject
{
    Q_OBJECT

    public:
    Foo( QObject* parent = 0 ) : QObject( parent )
    {}

    private:
    void doStuff()
    {
        qDebug() << "Emit signal one";
        emit signal1();

        qDebug() << "Emit finished";
        emit finished();

        qDebug() << "Emit signal two";
        emit signal2();
    }

    signals:
    void signal1();
    void signal2();

    void finished();

    public slots:
    void slot1()
    {
        qDebug() << "Execute slot one";
    }

    void slot2()
    {
        qDebug() << "Execute slot two";
    }

    void start()
    {
        doStuff();

        qDebug() << "Bye!";
    }
};

int main( int argc, char** argv )
{
    QCoreApplication app( argc, argv );

    Foo foo;

    QObject::connect( &foo, &Foo::signal1, &foo, &Foo::slot1 );
    QObject::connect( &foo, &Foo::signal2, &foo, &Foo::slot2 );

    QObject::connect( &foo, &Foo::finished, &app, &QCoreApplication::quit );

    QTimer::singleShot( 0, &foo, &Foo::start );
    return app.exec();
}

#include "main.moc"
{% endhighlight %}

Use the following simple CMake file to compile,

{% highlight cmake %}
# Minimum version requirement
cmake_minimum_required( VERSION 3.12 )

# Name of the project
project( test )

# Find Qt modules
find_package( Qt5 COMPONENTS Core REQUIRED )

# Include build directory contents
set( CMAKE_INCLUDE_CURRENT_DIR ON )

# List C++ source files
set( CPP_SOURCES main.cpp )

# Automatically handle MOC headers
set( CMAKE_AUTOMOC ON )

# Automatically handle UI files
set( CMAKE_AUTOUIC ON )

# Automatically handle resource files
set( CMAKE_AUTORCC ON )

# Create executable
add_executable( test ${CPP_SOURCES} )

# Link Qt libraries
target_link_libraries( test Qt5::Core )
{% endhighlight %}

{% highlight bash %}
$ mkdir build/
$ cd build/
$ cmake -DCMAKE_BUILD_TYPE=Release ../
$ make
{% endhighlight %}

Let's review this code first.
We set up an instance of `Foo` with two of its signals connected to two of its slots.
Further, there's a `finished()` signal, which is connected so as to quit the application when emitted.
We connect a single-shot timer to `Foo`'s start() function and are now ready to enter the main event loop.

When the `exec()` function is called, the event loop begins.
The first event that happens is the timer emitting a timeout after 0 ms.
The `timeout()` signal is connected to the `Foo` object's `start()` slot.
Before any other events are polled, the `start()` slot will be executed to completion.
This leads to the `doStuff()` method, which emits `signal1()`.
Immediately, the slot connected to this signal, `slot1()` will be executed.
Once control returns to `doStuff()`, it emits a second signal, `finished()`.
Uh, oh.
This signal is hooked up to the application's `quit()` slot!
Does this mean the application would quit immediately?

The answer is no.
As discussed earlier, the `QCoreApplication::quit()` slot actually calls `QCoreApplication::exit( 0 )`, which in turn queues up an exit event in the main event loop.
The actual quitting will not happen until control returns to the main event loop.

So, we happily continue with `doStuff()`, emit a second signal, `signal2()`, execute its slot, `slot2()` and return to `start()`.
We also get a "Bye!" message from `start()` before the control reaches the end of `start()`.
Now, we are back in the main event loop.

The first queued up event now is to quit the application, which then happens.
The output on the shell looks something like this,

{% highlight bash %}
$ ./test
Emit signal one
Execute slot one
Emit finished
Emit signal two
Execute slot two
Bye!
{% endhighlight %}

So, if I wanted to quit the application immediately, say upon encountering an error, how would I do that?
Throw an exception, catch it within start, signal completion/failure and simply return (to the main event loop).
