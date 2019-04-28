---
title: Implementing a collection scanner
subtitle: Part 1 - Directory scanner
layout: post
series: music-player
categories: [ project KDE ]
tags: [ music, C++ ]
---

Let's write a collection scanner.
Given a root directory, the job of the collection scanner is to descend into the collection and catalog its contents.
For starters, let's just catalog the directories.

Here's a basic implementation.
The function `scanDir` starts out from the root of a music collection and recurses into every non-empty subdirectory.
Each non-empty directory visited is recorded in a list.

{% highlight cpp linenos %}
#include <QDebug>

#include <QDir>
#include <QList>
#include <QString>

void scanDir( QList<QString>& directoryList, const QString& directory )
{
    auto dir = QDir( directory );

    // Terminate recursion if directory is empty
    if ( dir.isEmpty() ) return;

    // Record the directory
    directoryList << dir.absolutePath();

    // Scan all subdirectories
    for ( const auto& subDirInfo : dir.entryInfoList( QDir::Dirs | QDir::NoDotAndDotDot ) ) {
        scanDir( directoryList, subDirInfo.absoluteFilePath() );
    }
}


int main( int argc, char** argv )
{
    QList<QString> directoryList;
    QString root = "/media/audio/music/";

    scanDir( directoryList, root );

    // Write out all directories found (to stderr)
    for ( const auto& directory : qAsConst( directoryList ) ) {
        qDebug() << directory;
    }
}
{% endhighlight %}

This implementation is procedural and not very Qt-like (by which I mean, it's not very event-driven).
Here's my shot at making it event-driven.

The DirScan class now has a slot to get it started and emits a finished signal when done, which quits the application.
The start signal is triggered by a single-shot timer with zero delay.
There's an issue with passing an invalid root directory to this class---the `scanDir` method recurses infinitely, overflows the stack and segfaults the application.
For now, as long as the user is not naughty, we get back a list of non-empty directories inside the root of the collection.

{% highlight cpp linenos %}
#include <QDebug>

#include <QCoreApplication>
#include <QDir>
#include <QList>
#include <QObject>
#include <QString>
#include <QTimer>

class DirScanner : public QObject
{
    Q_OBJECT

public:
    DirScanner( const QString& path, QObject* parent = 0 ) : QObject( parent )
    {
        setRoot( path );
    }

private:
    QString m_root;
    QList<QString> m_directories;

    void setRoot( const QString& path )
    {
        // Check if directory is valid
        // TODO: Handle case when directory is not valid
        auto rootDir = QDir( path );
        if ( rootDir.exists() ) {
            m_root = rootDir.absolutePath();
        }
    }

    void scanDir( const QString& directory = "" )
    {
        // Start scanning at root if no directory is given
        if ( directory.isEmpty() ) scanDir( m_root );

        auto dir = QDir( directory );

        // Terminate recursion if directory doesn't exist or is empty
        if ( not dir.exists() ) return;
        if ( dir.isEmpty() ) return;

        // Record the directory
        m_directories << dir.absolutePath();

        // Recursively scan subdirectories
        for ( const auto& subDirInfo : dir.entryInfoList( QDir::Dirs | QDir::NoDotAndDotDot ) ) {
            scanDir( subDirInfo.absoluteFilePath() );
        }
    }

signals:
    void finished();

public slots:
    void start()
    {
        // Scan directories recursively
        scanDir( m_root );

        // Summarize the scan results
        for ( const auto& directory : qAsConst( m_directories ) ) {
            qDebug() << directory;
        }

        // Signal completion
        emit finished();
    }
};

int main( int argc, char** argv )
{
    QCoreApplication app( argc, argv );

    // Create a directory scanner
    QString root = "/media/audio/music/";
    DirScanner scanner( root );

    // Quit application when the scan completes
    QObject::connect( &scanner, &DirScanner::finished, qApp, &QCoreApplication::quit );

    // Launch a single run of the directory scanner
    QTimer::singleShot( 0, &scanner, &DirScanner::start );

    return app.exec();
}

#include "main.moc"
{% endhighlight %}

We're off to a good start!

TODO:
0. Implement a database.
1. Record the root to a collections table.
2. Scan a collection and write the found directories to a directories table.
3. Incremental-scan the collection and update newly found directories (and remove missing ones?)
    a. When a directory is missing, record the time of last scan that found it and leave it.
    b. If the last-seen time is more than say 60 days ago, drop the entry.
    c. Is it fast enough to write last-seen time to the DB every time we do a scan?

So far, I know the first two tables I want to create.
1. collections -> basically knows the root directory for now. Should probably list the protocol, etc.
2. directories -> Stores relative paths of directories from the root of each protocol. Stores the directory, its collection id, mtime and maybe the last seen time.

This is a good start, but we'd like to have a collection scanner that understands the difference between an initial scan and an incremental scan.

