---
title: On music player databases
layout: post
series: music-player
categories: [ project KDE ]
tags: [ music, amarok, mysql, clementine, sqlite, rhythmbox, xml ]
---

Music managers deal with lots of data and metadata relating to one or more music libraries they manage.
Let's take a look at the possible ways in which they might go about doing that.
For this purpose, I'll look at the databases used by three music players, Amarok, Clementine and Rhythmbox.
Amarok, in its 1.x days, used to offer a choice between SQLite, MySQL, or PostgreSQL as the database backend.
In its 2.x form, these options have been whittled down to just MySQL.
Clementine, its cousin-by-fork, also whittled down its options, but selected SQLite, instead.
Rhythmbox is unrelated to the two projects and uses an XML data store.

I regularly use Amarok on my desktop, and Clementine on my laptop.
I have briefly used Rhythmbox on my laptop in the past, but quickly abandoned it for Clementine.
I'll first begin with a description of Amarok's database, then move on to the relatively simpler schema used by Clementine and Rhythmbox.

# Amarok

## What a MySQL database looks like

MySQL is one of the programs that can be used to manage something called a relational database.
Relational databases are comprised of many tables/relations.
Each row/tuple in a relation/table represents a relationship between the columns/attributes of the relation.
Relational databases may be comprised of several tables, each expressing a new relation between the various attributes.
Each tuple in a relation must either have a unique attribute or set of attributes, called a key to identify it uniquely.
Finally, the SQL in the name refers to the Structured Query Language, a way to formulate all interactions (create/retrieve/update/delete) with the database management system.

MySQL uses a server process to guard access to the databases it manages.
The server operates on a "data directory" where each database lives in a sub-directory.
The MySQL server may have users and permissions defined, limiting or granting access to various databases in granular detail.
To manage each database, MySQL allows the database to specify its storage engine.
The storage engine is what processes the SQL queries and organizes how the data is stored and retrieved.
Depending on the storage engine, the contents of the database sub-directory can look quite different.

The default, InnoDB storage engine creates just a `.frm` file, one for each table, containing the structure and the data stored in that table.
The MyISAM storage engine, creates a `.frm` file to store the structure of the table, a `.MYI` file to store the indices of that table and a `.MYD` file to store the actual data.
There are other storage engines, but that goes a bit beyond the scope of this post.

## What an Amarok database looks like

Knowing the above, let's take a look at how Amarok stores its internal data in `~/.kde4/share/apps/amarok/mysqle/`.
The file system looks familiar and contains a single database called `amarok`, composed of several tables.
Right away, we can tell that this is a MySQL database and probably uses the MyISAM storage engine.

{% highlight text %}
mysqle
└── amarok
    ├── admin.frm
    ├── admin.MYI
    ├── ...
    └── years.MYD
{% endhighlight %}

In order to connect to this database, we need to launch a MySQL (mariaDB, I mean) server and connect through a MySQL/mariaDB client.
The config options for the server are helpfully recorded in a `my.cnf` file in the parent directory.
While it's probably quite safe to connect to the live database, I'd rather not chance any corruption of the data.
Let's make a copy of this data directory and connect to that instead.

{% highlight bash %}
$ mkdir /path/to/db/
$ cp -r ~/.kde4/share/apps/amarok/mysqle/ /path/to/db/
$ cp ~/.kde4/share/apps/amarok/my.cnf /path/to/db/
{% endhighlight %}

Technically, I don't really need the `my.cnf` file and can just start a server with default options, but I'll try to play it by the book here.
Edit the `my.cnf` file so that the `datadir` option now points to the current location of the `mysqle` directory.
Now, start the MySQL/mariaDB server using the `mysqld` binary.
Avoid using relative paths in the command as different options seem to consider paths relative to different directories.
Using absolute paths makes each path unambiguously clear.

{% highlight bash %}
$ mysqld --defaults-file=/path/to/db/my.cnf \
         --default-storage-engine=MyISAM \
         --datadir=/path/to/db/mysqle \
         --socket=/path/to/db/sock \
         --pid-file=/path/to/db/pidfile \
         --skip-grant-tables \
         --skip-networking &
{% endhighlight %}

Some explanation of the options used is in order.
The `--default-storage-engine` option sets the storage engine to MyISAM.
This matches the contents of the `my.cnf` file.
The `--datadir` option sets the data directory to the new location of the `mysqle` directory.
Next, we specify a socket file, a pseudo-file used to communicate back and forth with the server process.
Next, we specify a pid file, a text file which will contain the process ID of the server.
It comes in handy when stopping the server---simply `kill $(cat pidfile)`.
Now, we are down to the final two options.
The first, `--skip-grant-tables`, stops the server from bothering with enforcing permissions on various tables.
With this option on, anyone connecting to this server can do anything to any table.
This is considered a rather unsafe way of running things in production, but suits our purposes.
The last option, `--skip-networking` should always accompany `--skip-grant-tables` as matter of best practices as it prevents any connections from outside of localhost while the server is run in this vulnerable state.

Now, we can connect to this server using a mariaDB client, the `mysql` binary, and begin our dive.

{% highlight bash %}
$ mysql --socket=/path/to/db/sock amarok
{% endhighlight %}

## What an Amarok database *really* looks like

The Amarok database is comprised of about a dozen tables.
I'll present a guided tour through the information stored in this database.

{% highlight sql %}
MariaDB [amarok]> SHOW TABLES;
+----------------------+
| Tables_in_amarok     |
+----------------------+
| admin                |
| albums               |
| amazon               |
| artists              |
| bookmark_groups      |
| bookmarks            |
| composers            |
| devices              |
| directories          |
| genres               |
| images               |
| labels               |
| lyrics               |
| playlist_groups      |
| playlist_tracks      |
| playlists            |
| podcastchannels      |
| podcastepisodes      |
| statistics           |
| statistics_permanent |
| statistics_tag       |
| tracks               |
| urls                 |
| urls_labels          |
| years                |
+----------------------+
25 rows in set (0.00 sec)
{% endhighlight %}

### Devices

Let's start by walking through the devices table.
The devices table stores a unique ID for each device mount point ever seen by Amarok.
This includes USB drives, NFS shares, etc. and contains a lot of old, obsolete data---forgotten hard disks, old USB drives, things like that.

{% highlight sql %}
MariaDB [amarok]> DESCRIBE devices;
+----------------+--------------+------+-----+---------+----------------+
| Field          | Type         | Null | Key | Default | Extra          |
+----------------+--------------+------+-----+---------+----------------+
| id             | int(11)      | NO   | PRI | NULL    | auto_increment |
| type           | varchar(255) | YES  | MUL | NULL    |                |
| label          | varchar(255) | YES  |     | NULL    |                |
| lastmountpoint | varchar(255) | YES  |     | NULL    |                |
| uuid           | varchar(255) | YES  | UNI | NULL    |                |
| servername     | varchar(80)  | YES  | MUL | NULL    |                |
| sharename      | varchar(240) | YES  |     | NULL    |                |
+----------------+--------------+------+-----+---------+----------------+
7 rows in set (0.00 sec)

MariaDB [amarok]> SELECT * FROM devices LIMIT 3;
+----+------+-------+----------------------+--------------------------------------+------------+-----------+
| id | type | label | lastmountpoint       | uuid                                 | servername | sharename |
+----+------+-------+----------------------+--------------------------------------+------------+-----------+
|  1 | uuid | NULL  | /media/music         | bc809478-921b-460e-b0c8-156abbb9a13f | NULL       | NULL      |
|  2 | uuid | NULL  | /media/audio         | fa410c5e-3f5d-492b-98d8-d7a69d0b1aca | NULL       | NULL      |
|  3 | nfs  | NULL  | /net/qnapts231/audio | NULL                                 | qnapts231  | /audio    |
+----+------+-------+----------------------+--------------------------------------+------------+-----------+
3 rows in set (0.00 sec)
{% endhighlight %}

### Directories

Next, knowing the mount point of each device, let's look into the directories table.
This table stores the path to each directory where a playable music file was found.
The path stored is relative to the mount point and the mount point is referenced by the ID from the devices table.
Like the devices table, this table also has accumulated a lot of obsolete data and contains directories from devices that no longer exist.
Amarok seems to want to never forget old mount points, just in case they reappear.
While that does lead to a pleasant user experience (plug in an old hard drive and ratings, etc. are preserved and ready), it leads to quite a bit of cruft building up in the database.
Perhaps a middle path may be to define a duration of time after which entries are automatically retired, then deleted from the database.

Lastly, the directories table also records the last time point at which the directory was changed.
I don't know why for certain; it may be to avoid scanning directories whose timestamps haven't changed.

{% highlight sql %}
MariaDB [amarok]> DESCRIBE directories;
+------------+---------------+------+-----+---------+----------------+
| Field      | Type          | Null | Key | Default | Extra          |
+------------+---------------+------+-----+---------+----------------+
| id         | int(11)       | NO   | PRI | NULL    | auto_increment |
| deviceid   | int(11)       | YES  | MUL | NULL    |                |
| dir        | varchar(1000) | NO   |     | NULL    |                |
| changedate | int(11)       | YES  |     | NULL    |                |
+------------+---------------+------+-----+---------+----------------+
4 rows in set (0.01 sec)

MariaDB [amarok]> SELECT * FROM directories LIMIT 3;
+----+----------+-----------------------------------+------------+
| id | deviceid | dir                               | changedate |
+----+----------+-----------------------------------+------------+
|  1 |        2 | ./music/Muse/2003 - Absolution/   | 1352585099 |
|  2 |        2 | ./music/U2/1988 - Rattle And Hum/ | 1340255597 |
|  3 |       53 | ./The Wailers/                    | 1361750752 |
+----+----------+-----------------------------------+------------+
3 rows in set (0.00 sec)
{% endhighlight %}

### URLs

Next, the database records the actual paths to the songs in the directories above.
The path is cross-referenced by the device ID and the directory ID, but oddly, the relative path is remembered from the device mount point, not the directory.
This leads to redundant data, which could have been avoided.

This table also records a sort of checksum/hash for each URL, a uniqueid.
Amarok uses this uniqueid to identify a song, even if its location changes.
Just like a checksum, this uniqueid has its limits; if a song is moved, *and* its tags are edited, the checksum does not match anymore and the song cannot be identified anymore.

{% highlight sql %}
MariaDB [amarok]> DESCRIBE urls;
+-----------+--------------+------+-----+---------+----------------+
| Field     | Type         | Null | Key | Default | Extra          |
+-----------+--------------+------+-----+---------+----------------+
| id        | int(11)      | NO   | PRI | NULL    | auto_increment |
| deviceid  | int(11)      | YES  | MUL | NULL    |                |
| rpath     | varchar(324) | NO   |     | NULL    |                |
| directory | int(11)      | YES  | MUL | NULL    |                |
| uniqueid  | varchar(128) | YES  | UNI | NULL    |                |
+-----------+--------------+------+-----+---------+----------------+
5 rows in set (0.00 sec)

MariaDB [amarok]> SELECT * FROM urls LIMIT 1;
+----+----------+----------------------------------------------------------+-----------+-------------------------------------------------------+
| id | deviceid | rpath                                                    | directory | uniqueid                                              |
+----+----------+----------------------------------------------------------+-----------+-------------------------------------------------------+
|  1 |        2 | ./music/Massive Attack/1998 - Mezzanine/ - Teardrop.flac |     14378 | amarok-sqltrackuid://5ffc0724c7aa10b17b8c1c0c784edfbb |
+----+----------+----------------------------------------------------------+-----------+-------------------------------------------------------+
1 row in set (0.00 sec)
{% endhighlight %}

### Tracks

Now, we get to the metadata embedded in the file at the URL.
Amarok reads and records several components of the metadata embedded in the file and indexes many of them by uniqueness in their own tables.
Note that YEAR is indexed---metadata for the YEAR or DATE field is usually just a UTF-8 text field and beyond a recommendation that the format adhere to the ISO 8601 standard, there are no limitations on what this field can contain.

Now, this schema has an inherent assumption that is not necessarily true.
It assumes that all these fields should have unique values for a given song.
This doesn't hold for at least four of the attributes,

* Artist - Multiple artists may have collaborated on this song.
* Album - The song may have appeared on multiple albums and re-releases.
* Genre - The song may be considered as belonging to multiple genres.
* Composer - Multiple composers may have collaborated on this song.

In my opinion, these four should not appear in this table.

{% highlight sql %}
MariaDB [amarok]> DESCRIBE tracks;
+---------------+--------------+------+-----+---------+----------------+
| Field         | Type         | Null | Key | Default | Extra          |
+---------------+--------------+------+-----+---------+----------------+
| id            | int(11)      | NO   | PRI | NULL    | auto_increment |
| url           | int(11)      | YES  | UNI | NULL    |                |
| artist        | int(11)      | YES  | MUL | NULL    |                |
| album         | int(11)      | YES  | MUL | NULL    |                |
| genre         | int(11)      | YES  | MUL | NULL    |                |
| composer      | int(11)      | YES  | MUL | NULL    |                |
| year          | int(11)      | YES  | MUL | NULL    |                |
| title         | varchar(255) | YES  | MUL | NULL    |                |
| comment       | text         | YES  |     | NULL    |                |
| tracknumber   | int(11)      | YES  |     | NULL    |                |
| discnumber    | int(11)      | YES  | MUL | NULL    |                |
| bitrate       | int(11)      | YES  | MUL | NULL    |                |
| length        | int(11)      | YES  | MUL | NULL    |                |
| samplerate    | int(11)      | YES  |     | NULL    |                |
| filesize      | int(11)      | YES  | MUL | NULL    |                |
| filetype      | int(11)      | YES  |     | NULL    |                |
| bpm           | float        | YES  |     | NULL    |                |
| createdate    | int(11)      | YES  | MUL | NULL    |                |
| modifydate    | int(11)      | YES  |     | NULL    |                |
| albumgain     | float        | YES  |     | NULL    |                |
| albumpeakgain | float        | YES  |     | NULL    |                |
| trackgain     | float        | YES  |     | NULL    |                |
| trackpeakgain | float        | YES  |     | NULL    |                |
+---------------+--------------+------+-----+---------+----------------+
23 rows in set (0.00 sec)

MariaDB [amarok]> SELECT * FROM tracks LIMIT 3;
+-------+-------+--------+-------+-------+----------+------+--------------+---------+-------------+------------+---------+--------+------------+----------+----------+------+------------+------------+-----------+---------------+-----------+---------------+
| id    | url   | artist | album | genre | composer | year | title        | comment | tracknumber | discnumber | bitrate | length | samplerate | filesize | filetype | bpm  | createdate | modifydate | albumgain | albumpeakgain | trackgain | trackpeakgain |
+-------+-------+--------+-------+-------+----------+------+--------------+---------+-------------+------------+---------+--------+------------+----------+----------+------+------------+------------+-----------+---------------+-----------+---------------+
| 32755 | 32755 |    702 |  1104 |    26 |        1 |   51 | Paradise     |         |        NULL |       NULL |     903 | 217000 |      44100 | 24829510 |        3 | NULL | 1450213375 | 1371356885 |     -7.84 |     -0.693056 |     -7.84 |     -0.693056 |
| 32756 | 32756 |    991 |  1512 |     4 |        1 |   19 | Battersea    |         |           1 |       NULL |     982 | 230000 |      44100 | 28858939 |        3 | NULL | 1450213375 | 1393709479 |     -7.84 |     -0.110439 |     -7.84 |     -0.110439 |
| 32757 | 32757 |    991 |  1512 |     4 |        1 |   19 | One Way Ride |         |           2 |       NULL |    1047 | 202000 |      44100 | 27113510 |        3 | NULL | 1450213375 | 1393709479 |     -4.86 |             0 |     -4.86 |             0 |
+-------+-------+--------+-------+-------+----------+------+--------------+---------+-------------+------------+---------+--------+------------+----------+----------+------+------------+------------+-----------+---------------+-----------+---------------+
3 rows in set (0.00 sec)
{% endhighlight %}

### Artists

This is a simple table, just listing the textual representation of each artist against a unique key.

{% highlight sql %}
MariaDB [amarok]> DESCRIBE artists;
+-------+--------------+------+-----+---------+----------------+
| Field | Type         | Null | Key | Default | Extra          |
+-------+--------------+------+-----+---------+----------------+
| id    | int(11)      | NO   | PRI | NULL    | auto_increment |
| name  | varchar(255) | NO   | UNI | NULL    |                |
+-------+--------------+------+-----+---------+----------------+
2 rows in set (0.00 sec)

MariaDB [amarok]> SELECT * FROM artists LIMIT 3;
+----+-------------------+
| id | name              |
+----+-------------------+
| 15 | Elvis Presley     |
| 27 | Bob Dylan         |
| 28 | Simon & Garfunkel |
+----+-------------------+
3 rows in set (0.00 sec)
{% endhighlight %}

### Albums

A slightly more complex table, containing not just the album's relationship to the artist, but also to the album artwork.

Here again, I have some issues.
Neither the artist, nor the album artwork can be considered unique.
In case of the artist, while there can be a designated album artist in the embedded tags, it's entirely possible that several artists collaborated on this album.
Similarly, there can be multiple images associated with this album.
Hence, I think this table should just be a key and a value, like the artists table.

{% highlight sql %}
MariaDB [amarok]> DESCRIBE albums;
+--------+--------------+------+-----+---------+----------------+
| Field  | Type         | Null | Key | Default | Extra          |
+--------+--------------+------+-----+---------+----------------+
| id     | int(11)      | NO   | PRI | NULL    | auto_increment |
| name   | varchar(255) | NO   | MUL | NULL    |                |
| artist | int(11)      | YES  | MUL | NULL    |                |
| image  | int(11)      | YES  | MUL | NULL    |                |
+--------+--------------+------+-----+---------+----------------+
4 rows in set (0.00 sec)

MariaDB [amarok]> SELECT * FROM albums LIMIT 3;
+------+------------------------------------------+--------+-------+
| id   | name                                     | artist | image |
+------+------------------------------------------+--------+-------+
| 1500 | Dream Lover                              |    979 | 27096 |
| 1499 | The 4-Seasons Present Frankie Valli Solo |    978 |  NULL |
| 1498 | From A Jack To A King                    |    977 |  NULL |
+------+------------------------------------------+--------+-------+
3 rows in set (0.00 sec)
{% endhighlight %}

### Genres

Like the artists table, this is a simple table of key-value pairs.

{% highlight sql %}
MariaDB [amarok]> DESCRIBE genres;
+-------+--------------+------+-----+---------+----------------+
| Field | Type         | Null | Key | Default | Extra          |
+-------+--------------+------+-----+---------+----------------+
| id    | int(11)      | NO   | PRI | NULL    | auto_increment |
| name  | varchar(255) | NO   | UNI | NULL    |                |
+-------+--------------+------+-----+---------+----------------+
2 rows in set (0.00 sec)

MariaDB [amarok]> SELECT * FROM genres LIMIT 3;
+----+--------+
| id | name   |
+----+--------+
| 27 | Grunge |
|  2 | Pop    |
|  3 | Rock   |
+----+--------+
3 rows in set (0.00 sec)
{% endhighlight %}

### Composers

Again, this is just a simple key-value pairs table.
One odd thing with this table is that even though the schema clearly sets NULL as the default value for a missing composer, Amarok seems to never use this default.
Instead, a missing composer is mapped to an empty string.

{% highlight sql %}
MariaDB [amarok]> DESCRIBE composers; SELECT * FROM composers LIMIT 3;
+-------+--------------+------+-----+---------+----------------+
| Field | Type         | Null | Key | Default | Extra          |
+-------+--------------+------+-----+---------+----------------+
| id    | int(11)      | NO   | PRI | NULL    | auto_increment |
| name  | varchar(255) | NO   | UNI | NULL    |                |
+-------+--------------+------+-----+---------+----------------+
2 rows in set (0.00 sec)

+----+-------------------+
| id | name              |
+----+-------------------+
|  1 |                   |
| 28 | Henry Purcell     |
| 35 | Antonín Dvořák    |
+----+-------------------+
3 rows in set (0.00 sec)
{% endhighlight %}

### Years

Once again, this is a simple table containing key-value pairs.

{% highlight sql %}
MariaDB [amarok]> DESCRIBE years; SELECT * FROM years LIMIT 3;
+-------+--------------+------+-----+---------+----------------+
| Field | Type         | Null | Key | Default | Extra          |
+-------+--------------+------+-----+---------+----------------+
| id    | int(11)      | NO   | PRI | NULL    | auto_increment |
| name  | varchar(255) | NO   | UNI | NULL    |                |
+-------+--------------+------+-----+---------+----------------+
2 rows in set (0.01 sec)

+----+------+
| id | name |
+----+------+
| 83 | 1896 |
|  2 | 2010 |
|  3 | 1974 |
+----+------+
3 rows in set (0.00 sec)
{% endhighlight %}

### Images

This table indexes images available for album artwork by a unique ID.
The image could be found embedded in a track, in which case the path to the image simply contains the uniqueid from the urls table.
Otherwise, an absolute path to an image file is stored, for cases when the image is fetched from the internet, etc.
Like many of the other tables, this one's also filled with non-existent paths from invalid devices.

Images are associated to a track through its album.

{% highlight sql %}

MariaDB [amarok]> DESCRIBE images; SELECT * FROM images LIMIT 3;
+-------+--------------+------+-----+---------+----------------+
| Field | Type         | Null | Key | Default | Extra          |
+-------+--------------+------+-----+---------+----------------+
| id    | int(11)      | NO   | PRI | NULL    | auto_increment |
| path  | varchar(255) | NO   | UNI | NULL    |                |
+-------+--------------+------+-----+---------+----------------+
2 rows in set (0.00 sec)

+-------+-------------------------------------------------------------------------------------------+
| id    | path                                                                                      |
+-------+-------------------------------------------------------------------------------------------+
| 26319 | amarok-sqltrackuid://123874bc8112e9127c1f8f16ed417e50                                     |
|  1620 | /media/music/Untagged/ELO/1973 - ELO 2/album.jpg                                          |
| 27523 | /home/karthikp/.kde4/share/apps/amarok/albumcovers/large/e799fd8156a9a822a75d65f2a2b2b048 |
+-------+-------------------------------------------------------------------------------------------+
3 rows in set (0.00 sec)
{% endhighlight %}

### Labels and URLs_Labels

Labels are user-applied tags, called so to disambiguate them from the embedded tags already in the song files.
Labels are also fetched from last.fm and displayed when a song plays.
However, unless you selected the option to save the labels (look in the options for the labels widget in the context view), they are not saved.

The first table, labels, stores each individual label along with a unique id.
The second, urls_labels table contains multiple mappings between track urls and label ids.
In this way, unique pairs of track urls and label ids are saved.

In my library, I haven't tagged/labeled any songs in this way, so my tables are empty.

{% highlight sql %}

MariaDB [amarok]> DESCRIBE labels; SELECT * FROM labels LIMIT 3;
+-------+--------------+------+-----+---------+----------------+
| Field | Type         | Null | Key | Default | Extra          |
+-------+--------------+------+-----+---------+----------------+
| id    | int(11)      | NO   | PRI | NULL    | auto_increment |
| label | varchar(255) | YES  | UNI | NULL    |                |
+-------+--------------+------+-----+---------+----------------+
2 rows in set (0.00 sec)

Empty set (0.00 sec)
MariaDB [amarok]> DESCRIBE urls_labels; SELECT * FROM urls_labels;
+-------+---------+------+-----+---------+-------+
| Field | Type    | Null | Key | Default | Extra |
+-------+---------+------+-----+---------+-------+
| url   | int(11) | YES  | MUL | NULL    |       |
| label | int(11) | YES  | MUL | NULL    |       |
+-------+---------+------+-----+---------+-------+
2 rows in set (0.00 sec)

Empty set (0.00 sec)
{% endhighlight %}

### Lyrics

Unlike tags, lyrics do seem to be saved after being fetched from the internet when a song is played.
Also, they are stored with the url id of the song serving as the key.

{% highlight sql %}
MariaDB [amarok]> DESCRIBE lyrics;
+--------+---------+------+-----+---------+-------+
| Field  | Type    | Null | Key | Default | Extra |
+--------+---------+------+-----+---------+-------+
| url    | int(11) | NO   | PRI | NULL    |       |
| lyrics | text    | YES  |     | NULL    |       |
+--------+---------+------+-----+---------+-------+
2 rows in set (0.00 sec)
{% endhighlight %}

### Statistics

I saved the best for the last.
This table contains the juicy listening statistics associated with each URL.
Although there is a column for marking a record as deleted, it does not seem to be used.
Recording the create date seems to be redundant as this is already stored in the tracks table (curiously, some of the tracks have a NULL creation date; others have a different creation date in the tracks table).
However, the access date is useful, it marks the last time this track was played.
In addition to that, this table records the rating and playcount and the score as of the last play.

I wish this table also recorded the skip count, the number of times the song was played, but did not complete.
I also wish that instead of just recording the last access time here, Amarok would record all access times in a separate table, indexed by track url or unique id.
Having access to listening history locally can open the door to all sorts of data analysis.

{% highlight sql %}
MariaDB [amarok]> DESCRIBE statistics; SELECT * FROM statistics LIMIT 3;
+------------+------------+------+-----+---------+----------------+
| Field      | Type       | Null | Key | Default | Extra          |
+------------+------------+------+-----+---------+----------------+
| id         | int(11)    | NO   | PRI | NULL    | auto_increment |
| url        | int(11)    | NO   | UNI | NULL    |                |
| createdate | int(11)    | YES  | MUL | NULL    |                |
| accessdate | int(11)    | YES  | MUL | NULL    |                |
| score      | float      | YES  | MUL | NULL    |                |
| rating     | int(11)    | NO   | MUL | 0       |                |
| playcount  | int(11)    | NO   | MUL | 0       |                |
| deleted    | tinyint(1) | NO   |     | 0       |                |
+------------+------------+------+-----+---------+----------------+
8 rows in set (0.00 sec)

+-------+-------+------------+------------+---------+--------+-----------+---------+
| id    | url   | createdate | accessdate | score   | rating | playcount | deleted |
+-------+-------+------------+------------+---------+--------+-----------+---------+
| 27655 | 27655 |       NULL | 1381341719 | 70.9091 |      6 |        10 |       0 |
| 27656 | 27656 | 1393186971 | 1393186971 |    37.5 |      0 |         7 |       0 |
| 27657 | 27657 | 1375660566 | 1375674966 |       0 |      0 |         1 |       0 |
+-------+-------+------------+------------+---------+--------+-----------+---------+
3 rows in set (0.00 sec)
{% endhighlight %}

### Other tables

Briefly, here is the description of the contents of the other tables.

* Admin

This table contains the schema versions for some of the tables.
Each time the schema for any of the tables is updated, the version number should be bumped here.

* Bookmarks and Bookmark groups

The groups table contains the types of bookmarks stored (position markers, playback ended markers, etc) and the bookmarks table contains the actual bookmarks themselves.
I don't really use this feature, so I have none saved (apart from some playback ended markers that Amarok seems to have saved for a few tracks).

* Playlist tracks, Playlists and Playlist groups

Playlist tracks contains the tracks along with ordering information for each playlist.
This table contains lots of redundant info (artist, album, etc.) which should have been avoided.
The playlist table simply contains the names of the playlists.
The playlist groups table is empty, but I assume it would contain the types of playlists if I used multiple types.

* Podcast channels and Podcast episodes

Like the playlist tracks and playlists, these tables would probably contain data about podcast channels and the episodes.
I don't use this feature, so my tables are empty.

* Statistics_permanent, Stastistics_tag

These appear to be zombie tables, possibly with outdated schemas that were never deleted from the database.

# Clementine

## What an SQLite database looks like

Now, onwards to Clementine.
Clementine only supports SQLite because the developers felt that they would rather have perfect support for one backend than flaky support for multiple ones.
Like MySQL, SQLite is a another program to store and manage a relational database through SQL queries and commands.
Unlike MySQL, however, an SQLite database is a single file, usually with a `.db` extension, which contains all the relations/tables in the database.
Also unlike MySQL, access to an SQLite database is simply a matter of having access to the `.db` file---there's no mucking about with users and permissions.
To connect to the database, one simply launches the SQLite binary on the database file.

## What a Clementine database looks like

Clementine stores its internal database in `~/.config/Clementine/clementine.db`, right next to what I presume is a backup copy of the same database.
Like for Amarok, I made a copy of the database before connecting to it.

{% highlight bash %}
$ mkdir /path/to/db/
$ cp ~/.config/Clementine/clementine.db /path/to/db/
$ cd /path/to/db/
$ sqlite3 clementine.db
{% endhighlight %}

## What a Clementine database *really* looks like

The tables in the Clementine database bear a passing resemblance to Amarok's.
This makes sense, considering that the project forked from the Amarok 1.x series.
However the similarities end rather quickly.
Notice the abundance of tables assigned for various web-based services.
Clementine's support of various web-based services makes Amarok 2.x's offerings look positively bare-bones.
Also notice the `_fts_*` tables accompanying each table.
These are tables created by the FTS (full-text-search) plugin.
The tables contain unintelligible binary data and help speed up text searches across the several attributes stored in each table.

Once again, I'll present a guided tour through the information stored in this database.

{% highlight sql %}
sqlite> .tables
amazon_cloud_drive_songs               podcast_episodes
amazon_cloud_drive_songs_fts           podcasts
amazon_cloud_drive_songs_fts_content   schema_version
amazon_cloud_drive_songs_fts_segdir    seafile_songs
amazon_cloud_drive_songs_fts_segments  seafile_songs_fts
box_songs                              seafile_songs_fts_content
box_songs_fts                          seafile_songs_fts_segdir
box_songs_fts_content                  seafile_songs_fts_segments
box_songs_fts_segdir                   skydrive_songs
box_songs_fts_segments                 skydrive_songs_fts
devices                                skydrive_songs_fts_content
directories                            skydrive_songs_fts_segdir
dropbox_songs                          skydrive_songs_fts_segments
dropbox_songs_fts                      songs
dropbox_songs_fts_content              songs_fts
dropbox_songs_fts_segdir               songs_fts_content
dropbox_songs_fts_segments             songs_fts_segdir
duplicated_songs                       songs_fts_segments
google_drive_songs                     spotify_search_songs
google_drive_songs_fts                 spotify_search_songs_fts
google_drive_songs_fts_content         spotify_search_songs_fts_content
google_drive_songs_fts_segdir          spotify_search_songs_fts_segdir
google_drive_songs_fts_segments        spotify_search_songs_fts_segments
icecast_stations                       subdirectories
magnatune_songs                        subsonic_songs
magnatune_songs_fts                    subsonic_songs_fts
magnatune_songs_fts_content            subsonic_songs_fts_content
magnatune_songs_fts_segdir             subsonic_songs_fts_segdir
magnatune_songs_fts_segments           subsonic_songs_fts_segments
playlist_items                         ubuntu_one_songs
playlist_items_fts                     ubuntu_one_songs_fts
playlist_items_fts_content             ubuntu_one_songs_fts_content
playlist_items_fts_segdir              ubuntu_one_songs_fts_segdir
playlist_items_fts_segments            ubuntu_one_songs_fts_segments
playlists
{% endhighlight %}

### A minor rant on SQLite

I find it almost impossible to make SQLite console output look good.
In fact, next to the output that mariaDB/MySQL produces, it looks particularly shabby.
By default, tables aren't aligned to columns and are printed without headers.

{% highlight sql %}
sqlite> PRAGMA table_info(devices);
0|unique_id|TEXT|1||0
1|friendly_name|TEXT|0||0
2|size|INTEGER|0||0
3|icon|TEXT|0||0
4|schema_version|INTEGER|1|0|0
5|transcode_mode||1|3|0
6|transcode_format||1|5|0
{% endhighlight %}

So, you turn on headers first.

{% highlight sql %}
sqlite> .headers on
sqlite> PRAGMA table_info(devices);
cid|name|type|notnull|dflt_value|pk
0|unique_id|TEXT|1||0
1|friendly_name|TEXT|0||0
2|size|INTEGER|0||0
3|icon|TEXT|0||0
4|schema_version|INTEGER|1|0|0
5|transcode_mode||1|3|0
6|transcode_format||1|5|0
{% endhighlight %}

Yeah, better.
At least you know what each column represents.
But you definitely want column alignment before this mess is readable.
So, you can turn on the column mode.

{% highlight sql %}
sqlite> PRAGMA table_info(devices);
cid         name        type        notnull     dflt_value  pk
----------  ----------  ----------  ----------  ----------  ----------
0           unique_id   TEXT        1                       0
1           friendly_n  TEXT        0                       0
2           size        INTEGER     0                       0
3           icon        TEXT        0                       0
4           schema_ver  INTEGER     1           0           0
5           transcode_              1           3           0
6           transcode_              1           5           0
{% endhighlight %}

Ah, much bette... wait a minute!
Now the values are truncated.
The only way out (no joke) is apparently to specify the column widths manually.
"Screw that!," you say after typing a `.width` statement once, "I'm no peasant!
I'll use the explain mode instead."

{% highlight sql %}
sqlite> .explain on
sqlite> PRAGMA table_info(devices);
cid   name           type  notn  dflt  pk
----  -------------  ----  ----  ----  -------------
0     unique_id      TEXT  1           0
1     friendly_name  TEXT  0           0
2     size           INTEGER  0           0
3     icon           TEXT  0           0
4     schema_version  INTEGER  1     0     0
5     transcode_mode        1     3     0
6     transcode_format        1     5     0
{% endhighlight %}

Oh what fresh hell is this.
Now, the table headers are truncated *and* the columns are not aligned.
You do a quickie through the five stages of grief, hit [accept your fate] and move on with your work.

Luckily for you, dear reader, I will manually format the output of what follows to have full headers, full values and column alignment.
Don't you ever say I did nothing for you.

### Devices

As with Amarok, there's a devices table that sits atop the data hierarchy.
However, unlike Amarok, the devices table only seems to be there to store active devices, not a record of every hard disk the application has ever seen.
In my case, it's empty (and SQLite just returns nothing if there is nothing to say).

{% highlight sql %}
sqlite> PRAGMA table_info(devices);
cid         name               type        notnull     dflt_value  pk
----------  -----------------  ----------  ----------  ----------  ----------
0           unique_id          TEXT        1                       0
1           friendly_name      TEXT        0                       0
2           size               INTEGER     0                       0
3           icon               TEXT        0                       0
4           schema_version     INTEGER     1           0           0
5           transcode_mode                 1           3           0
6           transcode_format               1           5           0
sqlite> SELECT * FROM devices;
{% endhighlight %}

### Directories

The directories table contains the directories that Clementine was told to find music in.
This is basically the top-level directory of your music collection(s).

{% highlight sql %}
sqlite> PRAGMA table_info(directories);
cid         name        type        notnull     dflt_value  pk
----------  ----------  ----------  ----------  ----------  ----------
0           path        TEXT        1                       0
1           subdirs     INTEGER     1                       0
sqlite> SELECT * FROM directories;
path                  subdirs
--------------------  ----------
/home/karthikp/Music  1
{% endhighlight %}

### Subdirectories

The subdirectories table seems to contain every directory under the root directory, regardless of whether it contained a playable file or not.
In fact, the first instance in this table is the root directory itself.
Even so, each subdirectory is cross-referenced by the id of the root directory from the directories table.
Lastly, the last modified date is stored for each subdirectory.

{% highlight sql %}
sqlite> PRAGMA table_info(subdirectories);
cid         name        type        notnull     dflt_value  pk
----------  ----------  ----------  ----------  ----------  ----------
0           directory   INTEGER     1                       0
1           path        TEXT        1                       0
2           mtime       INTEGER     1                       0
sqlite> SELECT * FROM subdirectories LIMIT 3;
directory   path                                                                                 mtime
----------  -----------------------------------------------------------------------------------  ----------
1           /home/karthikp/Music                                                                 1502946627
1           /home/karthikp/Music/The Association                                                 1502700700
1           /home/karthikp/Music/The Association/1966 - And Then... Along Comes The Association  1502701493
{% endhighlight %}

### Songs

Unlike the multiple relations in the Amarok database, Clementine stores all its data in this one massive table.
It contains file system attributes, embedded tags, and listening statistics for each track in the local library.
Clementine clearly sees an advantage to storing library information in these monolithic chunks, because this schema is reused again and again.
The tables for Amazon cloud, Box, Dropbox, Google Drive, Magnatune, Seafile, Skydrive, Spotify, Subsonic, and Ubuntu are all designed identically.

{% highlight sql %}
sqlite> PRAGMA table_info(songs);
cid   name                    type     notnull  dflt_value  pk
----  ----------------------  -------  -------  ----------  ---------
0     title                   TEXT     0                    0
1     album                   TEXT     0                    0
2     artist                  TEXT     0                    0
3     albumartist             TEXT     0                    0
4     composer                TEXT     0                    0
5     track                   INTEGER  0                    0
6     disc                    INTEGER  0                    0
7     bpm                     REAL     0                    0
8     year                    INTEGER  0                    0
9     genre                   TEXT     0                    0
10    comment                 TEXT     0                    0
11    compilation             INTEGER  0                    0
12    length                  INTEGER  0                    0
13    bitrate                 INTEGER  0                    0
14    samplerate              INTEGER  0                    0
15    directory               INTEGER  1                    0
16    filename                TEXT     1                    0
17    mtime                   INTEGER  1                    0
18    ctime                   INTEGER  1                    0
19    filesize                INTEGER  1                    0
20    sampler                 INTEGER  1        0           0
21    art_automatic           TEXT     0                    0
22    art_manual              TEXT     0                    0
23    filetype                INTEGER  1        0           0
24    playcount               INTEGER  1        0           0
25    lastplayed              INTEGER  0                    0
26    rating                  INTEGER  0                    0
27    forced_compilation_on   INTEGER  1        0           0
28    forced_compilation_off  INTEGER  1        0           0
29    effective_compilation            1        0           0
30    skipcount               INTEGER  1        0           0
31    score                   INTEGER  1        0           0
32    beginning               INTEGER  1        0           0
33    cue_path                TEXT     0                    0
34    unavailable             INTEGER  0        0           0
35    effective_albumartist   TEXT     0                    0
36    etag                    TEXT     0                    0
37    performer               TEXT     0                    0
38    grouping                TEXT     0                    0
39    lyrics                  TEXT     0                    0
40    originalyear            INTEGER  0                    0
41    effective_originalyear  INTEGER  0                    0
sqlite> .mode line
sqlite> SELECT * FROM songs LIMIT 1;
                 title = Cherish
                 album = And Then... Along Comes The Association
                artist = The Association
           albumartist =
              composer =
                 track = -1
                  disc = -1
                   bpm = -1.0
                  year = 1966
                 genre = Oldies
               comment =
           compilation = 0
                length = 206000000000
               bitrate = 162
            samplerate = 44100
             directory = 1
              filename = file:///home/karthikp/Music/The%20Association/1966%20-%20And%20Then...%20Along%20Comes%20The%20Association/_-%20Cherish.mp3
                 mtime = 1502701493
                 ctime = 1502701493
              filesize = 4182725
               sampler = 0
         art_automatic = (embedded)
            art_manual =
              filetype = 5
             playcount = 0
            lastplayed = -1
                rating = -1
 forced_compilation_on = 0
forced_compilation_off = 0
 effective_compilation = 0
             skipcount = 0
                 score = 0
             beginning = 0
              cue_path =
           unavailable = 0
 effective_albumartist = The Association
                  etag =
             performer =
              grouping =
                lyrics =
          originalyear = -1
effective_originalyear = -1
{% endhighlight %}

# Rhythmbox

## XML databases

At its most basic, an XML file is just a store of data.
It consists of elements, which form enclosing tags around a text field.
Elements may contain other elements (sub-elements) instead of, or in addition to a text field.
Elements may also contain attributes within the enclosing tags.
If you've seen HTML code, you've more or less seen the basic structure of an XML file.

## What an XML database looks like

There's obviously no single, universal way to organize data in XML form.
Even so, the format of data stored in XML form can be well-specified using XML schema definitions.

## What Rhythmbox's XML database looks like

This is how Rhythmbox sees its music collection:

{% highlight xml %}
<?xml version="1.0" standalone="yes"?>
<rhythmdb version="2.0">
    <entry type="song">
        <title>Wonderlust King</title>
        <genre>Gypsy Punk</genre>
        <artist>Gogol Bordello</artist>
        <album>Super Taranta!</album>
        <duration>238</duration>
        <file-size>4571550</file-size>
        <location>file:///home/karthikp/music/Gogol%20Bordello/2007%20-%20Super%20Taranta_/_-%20Wonderlust%20King.mp3</location>
        <mtime>1502697383</mtime>
        <first-seen>1502946539</first-seen>
        <last-seen>1505023221</last-seen>
        <rating>5</rating>
        <date>732677</date>
        <media-type>audio/mpeg</media-type>
        <composer>Unknown</composer>
    </entry>
    <entry type="ignore">
        <title></title>
        <genre></genre>
        <artist></artist>
        <album></album>
        <location>file:///home/karthikp/music/Gogol%20Bordello/2007%20-%20Super%20Taranta_/album.jpg</location>
        <mtime>1502697730</mtime>
        <date>0</date>
        <media-type>application/octet-stream</media-type>
    </entry>
</rhythmdb>
{% endhighlight %}

Each song is stored as an entry with the attribute `type` set to `song`.
Each song contains the usual title, artist, album, genre, etc. tags as subelements of the entry.
Listening statistics are basically boiled down to first-seen, last-seen/played and a rating between 0 and 5 in steps of 0.5.

Album art, if found outside of the file, is also recorded in this XML file as an entry of type `ignore`.
I feel like this is an example of reusing an existing XML schema for a purpose that it wasn't intended for.

Rhythmbox has a separate playlist view, which comes with its own XML file storing queries, but this post has gone on for too long already, so I'll skip that.
In any case, I'm not interested in going down the XML path as I think databases have significant advantages to offer over what XML is capable of.
Perhaps it's worth noting that Amarok's scanner actually writes an XML file before it's imported by the application database proper.
This allows the scanner to be run separately from and even simultaneously with the main application.

# Conclusion

The three music players surveyed are typical of music players in linux today.
Amarok and Clementine use SQL databases for their database backend, while Rhythmbox uses an XML database.
Neither, incidentally, felt the need to use NoSQL databases as the benefits of scalability and freeform schemas don't really do much for music managers.

The difference in the way Amarok and Clementine databases are organized illustrates a concept called database normalization.
Clementine's monolithic database is in unnormalized form and contains much redundant data between tuples.
For instance, all songs from the same album have to list the album name repeatedly.
Due to such redundancies, such databases are supposed to have slower write times.
However, unnormalized databases are often used to improve read times---once a row is identified as the result of a query, all its fields are immediately available.

As I've indicated multiple times, Amarok's normalized database is much closer to the schema I have in mind for implementing as a backend for my mythic music player.
If anything, it doesn't go far enough in normalizing its contents to enable the sort of relationships I want to manage and query.
In my next post, I'll begin the process of implementing a collection scanner.

