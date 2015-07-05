---
title: Towards an encrypted system
layout: post
categories: [ user guides ]
tags: [ dm-crypt, luks ]
comments: true
---

# Why bother?

It is perhaps a sign of the times that this question needs to be addressed before getting into any details.
But really, encrypted systems should be the default and should be considered as normal as and equivalent to having a password-based login.
A password ensures that someone cannot log into your computer and access your account.
An encrypted system is much the same, in that it ensures that someone cannot plug one of your hard disks into their computer and access your files.

# How inconvenient is it?

In practice, it's not any more inconvenient that having to either type in a password or stick a USB drive in during boot up.
In fact, that step is pretty much the only reminder you will have that your system is encrypted.

# How does it work?

The variety and details of the various implementations is a little overwhelming to take in.
The arch wiki offers a concise writeup on [how the process works](https://wiki.archlinux.org/index.php/Disk_encryption#How_the_encryption_works) along with a summary of [various implementations](https://wiki.archlinux.org/index.php/Disk_encryption#Available_methods).
The standard option is to go with `dm-crypt` which already comes built in with the Linux kernel.

# Installation procedure

The [beginner's guide](https://wiki.archlinux.org/index.php/Beginners'_guide) lists the following steps for the installation procedure.

1. Boot the installation medium.
2. Establish an internet connection.
3. Prepare your storage devices.
4. Select a mirror.
5. Install the base system.
6. Generate an fstab.
7. Chroot and configure the base system.
8. Reboot.

Setting up an encrypted system affects steps 3, and 7.

## Preparing the storage devices

Normally, one would use `cgdisk` to format the storage devices into partitions of the desired size and use `mkfs` to format those partitions.
However, this time, we want to encrypt those partitions first.

The user interface to encrypting/decrypting a volume is provided by the `cryptsetup` command.
Let's say the raw partition is `/dev/sda3` and we would like to encrypt it using `dm-crypt`.
Begin by creating an encrypted volume on this partition.
In its simplest form,

{% highlight console %}
# cryptsetup luksFormat /dev/sda3
{% endhighlight %}

The `cryptsetup` utility has several optional flags to specify the cipher, key size, etc.
See [this page](https://wiki.archlinux.org/index.php/Dm-crypt/Device_encryption) for very good explanations of the options.
The simple command above will use some sane defaults and ask for a passphrase to encrypt this device.
(Note that you can set up both a passphrase and a key file.
In fact, you can set up up to *eight* ways of unlocking your encrypted device.)

The encrypted device can now be unlocked and used like a normal partition.
The unlocked volume will become available on `/dev/mapper/` (`dm` stands for "device mapper") at a "mount point" of your choosing.
I'll pick something silly like, `my-crypt-device` for this example.

{% highlight console %}
# cryptsetup luksOpen /dev/sda3 my-crypt-device
{% endhighlight %}

Now, you can use `/dev/mapper/my-crypt-device` in place of `/dev/sda3` for creating the file system (`mkfs.ext4 /dev/mapper/my-crypt-device`), mounting the file system (`mount /dev/mapper/my-crypt-device /mnt`), etc.

Remember that the `/boot` partition is still unencrypted and will remain that way.

## Chroot and configure the base system

This step deviates from the normal route when building the initramfs image and setting up GRUB.
[Here's](https://wiki.archlinux.org/index.php/Dm-crypt/System_configuration) the arch wiki page for reference.
The deviation is that we need to configure GRUB first, then rebuild the initramfs image to parse that.

During boot up, GRUB needs to know that the root device it's looking for (`/dev/mapper/my-crypt-device`) is actually an unlocked encrypted device.
The raw `/dev/sda3` partition and the unlocked `/dev/mapper/my-crypt-device` volume have different UUIDs.
Use `ls -l /dev/disk/by-uuid` to get them.

Now, before generating the `/boot/grub/grub.cfg` file, edit the `/etc/default/grub` file to tell GRUB this by passing the `cryptdevice` parameter.

{% highlight diff %}
-GRUB_CMDLINE_LINUX_DEFAULT="quiet"
+GRUB_CMDLINE_LINUX_DEFAULT="cryptdevice=/dev/disk/by-uuid/e852ae5d-82e2-5525-1947-92abc23df27c:my-crypt-device quiet"
{% endhighlight %}

Now, generate the `/boot/grub/grub.cfg` file as usual and note that this option now appears there.

Next, we need to add a hook to the initramfs image to have it look for an encrypted root partition.
Edit the `/etc/mkinitcpio.conf` file and add the `encrypt' hook before the `filesystems` hook.

{% highlight diff %}
-HOOKS="base udev autodetect modconf block filesystems keyboard fsck"
+HOOKS="base udev autodetect modconf block encrypt filesystems keyboard fsck"
{% endhighlight %}

Remember to do this after generating the GRUB configuration as that is parsed by the `encrypt` hook when you run `mkinitcpio -p linux`.

One thing to look out for is if you use a non-US keymap, you might want to add the `keymap` hook here so that you can type your passphrase in the desired keymap instead of hunting-and-pecking in qwerty.
I use dvorak, so I needed this extra bit.

Once you've rebuilt the initramfs image, continue with the rest of the installation procedure.
When you reboot, you should be either asked for a passphrase (if you went with the default set up) or need to insert your USB drive to provide the key file.

# Offline access

Reading the encrypted volume from another machine requires you to open/decrypt it before mounting and accessing the files.
You would connect the drive and open the partition (say, `/dev/sdb3` now) with `cryptsetup`.
Either specify the passphrase or provide a path to the key file.
Make sure you have the `dm_crypt` kernel module loaded.

{% highlight console %}
# modprobe dm_crypt
# cryptsetup luksOpen /dev/sdb3 my-crypt-device
# mount /dev/mapper/my-crypt-device /mnt
{% endhighlight %}

Now you can access the files on the drive at the mount point (`/mnt').

