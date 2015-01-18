---
title: Checking if a disk is present
layout: post
categories: [user guides]
tags: [cd, dvd, bluray, lsblk, blkid, bash, ruby, python]
comments: true
---

Here's an interesting problem.
I need a utility to let me know if a disk is present in an optical drive.
I'd like this utility to be used as part of scripts that need to get data from the optical drive.
Such scripts could just query using this utility before reading or attempting to mount the disk.

The utility would need to work on machines with an unknown number of optical drives;
and the disks, when present, could be CDs, DVDs or Blurays.
In all cases, I simply need to know if a disk is available to read from (and the device name like, /dev/sr0, etc.).

We'll first try to solve this from the command line.
One can always use the `lsblk` command to list all the block devices, including any and all ROM devices.
The output on a fictional machine could look like this,

{% highlight console %}
$ lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0   500G  0 disk 
└─sda1   8:1    0   500G  0 part /
sdb      8:16   0    50G  0 disk 
└─sdb1   8:17   0    50G  0 part /home
sr0     11:0    1     5G  0 rom
{% endhighlight %}

The output says that there are two hard disks, one with a 500 GB partition mounted on `/` and one with a 50 GB partition mounted on `/home`.
There is also a `rom` device present, `/dev/sr0`.
The size reported for the `rom` device is not current.
It is just the previous medium that was inserted into the drive.

This is off to a good start.
We can just grab a list of all the devices identifying themselves as `rom` to compile a list of optical drives.

{% highlight console %}
$ lsblk | awk '/rom/ {print $1}'
sr0
{% endhighlight %}

Next, we need to see if a medium is present in the ROM devices collected.
To do that, we can use the `blkid` command.
Note that some features of the `blkid` command need root privileges to return anything useful, but this is NOT one of them.
It's a good idea to always restrict permissions to the least viable level.
Now, if a disk is present, `blkid` will return something like this,

{% highlight console %}
$ blkid /dev/sr0
/dev/sr0: LABEL="MOVIE" TYPE="udf"
$ echo $?
0
{% endhighlight %}

And if a disk is absent, the non-zero exit code will reflect this accordingly.

{% highlight console %}
$ blkid /dev/sr0
$ echo $?
2
{% endhighlight %}

Now that we have all the tools, let's put together the query function in bash, ruby and python.
Here's the bash function first.

{% highlight bash linenos %}
list_available_drives()
{
    # Gather all drives identifying themselves as rom devices in an array
    declare -a drives=($(lsblk | awk '/rom/ {print "/dev/"$1}'))

    for drive in ${drives[@]}
    do
        temp=$(blkid ${drive})
        if test $? -eq 0
        then
            echo ${drive}
        fi
    done
}
{% endhighlight %}

Note that bash functions can only return exit codes, so a complicated data structure like an array needs to be passed out of a function in a special way.
One way to do that would be to use a global variable.
Here, we take another way out and simply echo out each available drive.
This function can be run in a `$()` subshell and captured into an array for use by another portion of the script.

{% highlight bash %}
declare -a my_available_drives=($(list_available_drives))
{% endhighlight %}

This doesn't always work.
For instance, if the array elements have spaces in the middle, this will break up the element at each space.
But here, when working with device names, that's probably not much of a concern.

Next, here's the ruby version.

{% highlight ruby linenos %}
def list_available_drives
    drives = %x( lsblk | awk '/rom/ {print "/dev/"$1}' ).split( '\n' )

    available_drives = Array.new

    drives.each do | drive |
        temp = %x( blkid #{drive} )
        available_drives.push( drive ) if $?.exitstatus == 0
    end

    return available_drives
end
{% endhighlight %}

Pretty straightforward to understand.
The list of drives is split using newlines into individual devices, each of which is queried using `blkid`.
When one or more of them returns a zero exit status, the disk is in the drive and ready for use.
This function then returns an array of all available optical devices.

Finally, here's an implementation in python.

{% highlight python linenos %}
from subprocess import check_output, call

def list_available_drives():
    drives = [ drive.decode() for drive in check_output( "lsblk | awk '/rom/ {print \"/dev/\"$1}'", shell = True ).splitlines() ]
    return [ drive for drive in drives if call( "blkid " + drive + "> /dev/null", shell = True ) == 0 ]
{% endhighlight %}

There are several complications here to note.
First, using `subprocess.check_output()` returns a byte array, which looks like this, `b'/dev/sr0\n/dev/sr1\n'`.
This needs to be split by newline and each element of that list must be converted into string by decoding it.
Also, the `check_output()` method doesn't cleanly escape quotes in the system command---notice the escaped double quotes, `\"`, around `/dev/` to prepend it to the device name from `lsblk`.

When split and decoded, the list of devices can be tested with `blkid` using `subprocess.call()` to get the exit status.
However, `call()` doesn't redirect the output silently like `subprocess.Popen()` can.
So, I've also had to forward any output to `/dev/null` to make it work silently.
In all, while this implementation has the fewest number of lines, it also has the most number of gotchas to trip an unwary (or newbie) programmer up.


