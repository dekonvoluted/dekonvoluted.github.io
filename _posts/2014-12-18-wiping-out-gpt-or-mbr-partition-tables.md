---
title: Wiping out GPT or MBR partition tables
layout: post
categories: [ user guides ]
tags: [ gpt, mbr, sgdisk ]
---

Use this when you've utterly cocked up partitioning a disk and would simply like to start fresh without any old partition tables of any kind, whether they're GPT or MBR.
There is no data on the disk at this point, so the question of data loss should be moot.
Still, since we're only playing with partition tables, you [can recover](http://tldp.org/HOWTO/Partition/recovering.html) your old partitions if your job, life, or [credit rating](http://en.wikipedia.org/wiki/Brazil_(1985_film)) depended on it.

First, doubly verify that the disk you are planning to do this to is the correct one.

    $ lsblk

Once you know that you have the right disk, make sure it's not mounted.
In this example, I'm going to assume that the disk is `/dev/sdb`.

    $ sudo umount /dev/sdb

Now, just zap all partition tables using the `sgdisk` command from the `gptfdisk` package.

{% highlight console %}
# sgdisk --zap-all /dev/sdb
GPT data structures destroyed! You may now partition the disk using fdisk or
other utilities.
The operation has completed successfully.
{% endhighlight %}

# Further reading

The author's [webpage](http://www.rodsbooks.com/gdisk/index.html), particularly, [this section](http://www.rodsbooks.com/gdisk/wipegpt.html) is a good place to start.

