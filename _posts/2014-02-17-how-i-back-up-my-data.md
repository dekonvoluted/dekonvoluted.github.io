---
title: How I back up my data
category: 'Tips'
tags: rsync ext4 btrfs backup
---

# How I back up my data

I suppose, if I had to put a number on it, it would be... three.
Three TB, that\'s how much of my data is at stake.
That\'s how much data I stand to lose.
It is a modest number, but it\'s obviously of vital importance to me that I don\'t lose any of my data.
The two primary dangers facing it are bit-rot and drive failure.
I am ashamed to admit that I don\'t really have a strategy in place to deal with bit-rot just yet.
[Btrfs](http://arstechnica.com/information-technology/2014/01/bitrot-and-atomic-cows-inside-next-gen-filesystems/) simply couldn\'t get here any sooner.
But I do have a defense against drive failure.
I have never lost any data to drive failure so far and I am doing my best to make sure I don\'t start now.
If you don\'t have a backup strategy in place, hopefully, this will get you started.

I have data spread over three volumes.

* ### Home
My home directory contains active projects I\'m working on, application settings, crypto keys, important documents, etc.
This is currently on a 180 GB SSD.

* ### Archive
Cold storage for files that I don\'t think I\'ll need access any time soon.
This is a sparsely utilized 1 TB HDD.

* ### Media
Entertainment files---movies, music, etc. on a 3 TB HDD.

My backup strategy is to make periodic, incremental copies of my three volumes.
I currently to this to two HDDs, one backing up my home and my archive and the other entirely devoted to backing up my media.
I do this periodically (at least weekly), so if any of my active disks croak, I should be able to get a new device and restore my most recent backup and not lose more than a week\'s worth of changes.

Now, for the longest time, I used to create snapshot-style backups with my data exactly mirrored on the external, backup drive.
The advantage of this is that the backup device itself is a clean drop-in replacement for the drive it\'s a mirror of.
It\'s also space efficient in that it uses no more space that the amount of data being mirrored.
The downside, however, is that there is almost no history preserved.
There is just one snapshot to restore back to.
Of course, depending on available space, you could keep several complete snapshots of the data.

This is where incremental backups come in handy.
The simplest implementation of this would be to use `rsync` and create hard links to unchanged files and only copy over changed files.
Each hard link points to the same data on the disk.
So, older hard links can be safely deleted without compromising the integrity of the newer 'snapshots'.
This makes operations like deleting older snapshots, restoring a snapshot, etc. trivially easy.
[This page](http://www.mikerubel.org/computers/rsync_snapshots/) has a great summary that goes over several considerations when setting up incremental backups.

To put this into action, I now have a simple python script that reads in a configuration file specifying the source and destination and creates an incremental backup.
A sample configuration file could look like this,

{% highlight ini %}
[name]
source = /path/to/source
destination = /path/to/destination
{% endhighlight %}

And the corresponding destination could look something like this,

    name/
    ├── 2014-01-11/
    ├── 2014-01-19/
    ├── 2014-01-22/
    ├── 2014-01-25/
    ├── 2014-01-26/
    ├── 2014-02-01/
    ├── 2014-02-06/
    ├── 2014-02-08/
    ├── 2014-02-13/
    └── latest -> 2014-02-13/`

## Implementation

At its core, the python script needs to execute an `rsync` call like this,

    /path/to/rsync --archive --link-dest=/path/to/destination/latest /path/to/source/ /path/to/destination/YYYY-MM-DD

Let\'s implement that first.
A simple function called `archive_preset()` that takes three arguments, the preset name, the source path and the destination path.

{% highlight python %}
def archive_preset( preset, source, destination ):
    today = date.today().strftime( '%Y-%m-%d' )
    destination_path = destination + '/' + preset + '/'

    # Avoid error messages during the first run
    if not path.isdir( destination_path ):
        mkdir( destination_path )
        mkdir( destination_path + '/' + today )
        symlink( destination_path + '/' + today, destination_path + '/latest' )

    # Compose the rsync call
    sync_command = '/usr/bin/rsync'
    sync_command += ' --verbose --archive --exclude=lost+found'
    sync_command += ' --link-dest=' + destination_path + '/latest '
    sync_command += source + '/ '
    sync_command += destination_path + '/' + today

    call( sync_command, shell=True )

    # Update link to latest backup
    unlink( destination_path + '/latest' )
    symlink( destination_path + '/' + today, destination_path + '/latest' )
{% endhighlight %}

This function can be called upon successfully parsing an input configuration file using `ConfigParser`.
Multiple such presets may be passed to the program, so a function called process_preset_files() could accept one or more presets and issue calls to archive_preset() for each valid one.

{% highlight python %}
def process_preset_files( preset_files ):
    for preset_file in preset_files:
        if not path.isfile( preset_file ):
            print( preset_file, 'is not a valid input.' )
        else:
            config = ConfigParser()
            config.read( preset_file )

            for section in config.sections():
                preset = section
                source = path.realpath( config[ section ][ 'source' ] )
                destination = path.realpath( config[ section ][ 'destination' ] )

                if not path.isdir( source ):
                    print( source, 'is not a valid source.' )
                    exit( 1 )

                if not path.isdir( destination ):
                    print( destination, 'is not a valid destination.' )
                    exit( 1 )

                archive_preset( preset, source, destination )
{% endhighlight %}

Now, all that remains is to write a front-facing bit to handle inputs and interact with the user.

{% highlight python %}
if __name__ == '__main__':
    parser = ArgumentParser( formatter_class=RawDescriptionHelpFormatter, description = '''
    Create and maintain incremental backups.
    Backups are described by presets like this,

        [home]
        source = /home/user/
        destination = /mnt/backup/

    A single preset file can contain many such presets.
    Multiple preset files can be supplied as arguments.''' )
    parser.add_argument( 'PRESETS', nargs='+', help='One ore more INI files containing presets.' )
    args = parser.parse_args()

    process_preset_files( args.PRESETS )
{% endhighlight %}

This script is being maintained in [this repository](https://github.com/dekonvoluted/archive).

Feel free to clone it, modify it, use it and pass it on.
I prefer to manually run it once a week or so.
You might consider hooking it up to a cron job.
Note that if you plan to make backups more often than a day, you would want to add the hour, minute, maybe even second to the snapshot names.
Also, over time, your external backup device will get filled up and you will need to delete old snapshots to free up space.
Since the backup device is a maze of hard links, it won\'t be easy to figure out just how many older snapshots you need to delete to free up enough space for the next backup.
Just delete them one by one till enough space is freed up.
Conceivably, the script could be updated to automatically delete older snapshots to make space for the current one.

