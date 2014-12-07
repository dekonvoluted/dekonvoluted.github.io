---
title: My Adventures with Arch Linux
subtitle: Part 2 - Installation
layout: post
series: archlinux
categories: [ user guides ]
tags: [ arch linux ]
---

> This article refers to deprecated software and methods.
> It is presented here for archival purposes only.

> First and foremost, if you have any data that you'll regret losing, back it up.
> No, seriously!
>
> This is not a step by step installation guide.
> It's a bunch of notes regarding things to expect during the installation.
> Refer to the Beginner's Guide for a more complete walkthrough of the installation process.

# Backup!

This bears repeating.
Back up all data on an external hard disk before you consider installing Arch.
I'd suggest spending one week just making sure that everything you could possibly need is safely backed up.
It's better to be safe than sorry.

# Download

Download the latest ISO from [here](http://www.archlinux.org/download/).
Consider using the torrent.
It really doesn't take much longer than a regular download.
There is a choice between a 'core' ISO and an 'ftp' ISO.
Choosing the core option gives you a bigger ISO with many of the core system packages already on the CD.
This means no waiting time for downloading during the install.
However, the packages are likely to be out-of-date.
The ftp option gives you a smaller ISO and downloads the latest version of the core packages from an online repository.
This is usually the better option.
You also have a choice between a 32 bit and a 64 bit ISO.
If you don't know which one you want, go with the 32 bit option.

# Read up

The [Beginner's Guide](http://wiki.archlinux.org/index.php/Beginners_Guide) is a wealth of information that concerns the set up.
Regardless of your experience with linux hitherto, consider reading it at least a couple of times before you install.
It's also available as a text file on the installer CD.

If you can, also read up on what module/firmware packages you'll need to install for your wireless card, if you have one.
It'll help to know this when confirming the set of packages to install during the set up.

# Network

You'll need to be online to download packages from the arch repositories.
If it's a wired connection, there's little you need to do to get the machine online.
In fact, getting online is actually one of the first steps in the installer.
If you have a wireless connection, consider downgrading the security on the network to WEP temporarily during the install.
This vastly simplifies the process.

Regardless, here's a quick setup to setting up a network:

    $ ifconfig -a

> If the prompt is shown as $, the command does not need root access.
> A # prompt indicates that you need to be root to run this command.
> During the setup, you ARE root;
> but this notation will come in handy for use later.<

This will list all devices onboard the computer that can connect to a network.
Note the `INTERFACE` for your wired/wireless card.
Should you need to tell a wireless interface from a wired one, use the following command:

    # iwlist scan

This will list out a quick scan of all the wireless networks in the area.
It will also list out the interfaces that support scanning (i.e., the wireless interfaces).

Now, bring up the interface with,

    # ifconfig INTERFACE up

The next step only applies to wireless interfaces.
Skip this if your connection is wired.
This step will associate the interface with a wireless network using WEP.
As I suggested before, consider downgrading the security on your network to WEP (if you're using WPA/WPA2) at least temporarily.

    $ iwconfig INTERFACE essid ESSID key KEY

The `ESSID` can be within quotes if you have spaces in your network name.

Now, the final step is common to both wired and wireless devices.
This uses the dhcp cliend daemon to obtain an IP address for your computer.

    # dhcpcd INTERFACE

Finally, you can test your connection by pinging a network address.

    $ ping google.com

You should see ping times being shown. Ctrl+C to stop the pinging.

Other commands that will come in handy are:

    # dhcpcd -x INTERFACE

to stop the DHCP client daemon, and

    # ifconfig INTERFACE down

to bring the interface down.

If you need to troubleshoot, use the beginner's guide suggestions.

# Partitions

This is a very important step during your install.
If you have multiple hard disks, make sure you know which hard disk you're about to wipe clean.
Use the cfdisk utility to create the partitions.
Don't sweat about formatting them.
The installer will take care of formatting them during the setup.
The following commands will come in handy while working with hard disks and partitions.

    $ cat /etc/partitions

will list all the partitions you have, and

    $ ls -lF /dev/disk/by-uuid

will list the UUID's of the partitions.

    # mkfs.ext4 /dev/sda1

will format the sda1 partition using the ext4 file system.

Consider creating at least the following partitions:

- boot (about 128 MB is more than enough. ext2 is fine for this partition)
- root (a 10 GB, ext4 partition is a good start)
- swap (used for hibernating the machine. 10% more than the size of your RAM is good enough)
- home (leave the rest of the hard disk to this partition. ext4 is a good choice)

# Packages

As long as you install the base packages, you can always install any other packages you may need later.
Don't sweat it too much during the setup trying to decide which packages you need.
If you have a wireless card, you may need to make sure you get the appropriate package for the module at this point.
My Intel Pro Wireless 2915 card on my laptop needed the ipw2200 package, for example.

# System Files

You'll have a chance to go over key configuration files at the end of the install.
You'll likely find that you have very little you want to change at all at this point.
You can always load 'em up later and edit them to your heart's content. :)

# Reboot!

If all went well, you should be able to boot into your freshly installed Arch linux system.
Your journey is far from over.
In fact, it's just beginning!

    # reboot

