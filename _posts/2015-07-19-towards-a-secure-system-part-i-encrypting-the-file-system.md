---
title: Towards a secure system
subtitle: Part I - Encrypting the file system
series: security
layout: post
categories: [ user guides ]
tags: [ dm-crypt, luks ]
comments: true
---

This is the first of a multi-part series focusing on setting up a secure Linux system.
While this and the following parts are written with a laptop/netbook form factor in mind, the tools and steps can, with equal validity, be applied towards setting up a secure desktop system as well.

This first part will deal with encrypting the file system on your computer.
A system using unencrypted storage media is vulnerable to physical access.
Someone could simply take the SSD or HDD and connect it to another machine and copy the files over.
If the file system is encrypted, however, this will not be possible without decrypting the media first.
Before we begin, let's get a few FAQs out of the way.

1. Why should I bother with encryption?

    Sigh.
    It is perhaps a sign of the times that this question even needs to be answered.
    It comes down to mindset, I'm afraid and I encourage you to think of encrypted systems the same way you would think about password-secured logins.
    Just like a password secures a login, an encrypted file system is secured against unauthorized access to your files on the physical hardware.

2. How inconvenient is it to work with an encrypted file system?

    This really depends on the encryption scheme you choose.
    In this writeup, I'll use what comes built in with a standard linux kernel, dm-crypt, to manage encrypted volumes which have a LUKS header, so, I'll answer for that.
    A disk partition encrypted this way starts with a LUKS (Linux Unified Key Setup) header which specifies between one and eight ways of decrypting it.
    Each of these ways or "slots" could either use a passphrase, like a password, or a key file, which is just a regular file being used as a sort of password.
    If a key file cannot be found (it would usually be on removable media like a USB drive), the system will fall back to a passphrase.
    You don't really have to have eight passwords or key files, mind you.
    Typically, you'd set up a key file and a passphrase as a backup.

    So, in practice, it's not any more inconvenient than having to either stick a USB drive in when booting up, or if you lose it, type in a password.
    You will not need to decrypt the hard disk when resuming from sleep.

3. Will encryption cost performance? Will it slow down my system?

    This is unavoidable, but it's hardly perceptible on my netbook.
    So, physics says yes, but in actual usage, it's not noticeable.

4. What if I lose the USB key with the key file or forget my passphrase?

    Since the whole point of encrypting a disk is to deny access in such cases, the answer is that you will not be able to access your files without being able to decrypt the medium.

    In practice, you should have one or more of the following set up to deal with this eventuality:

    - A backup of your key file in a secure place.
    - A physical, written down copy of your passphrase stored in a secure place.
    - A recent backup of your files, stored offline on a encrypted hard disk which uses a different passphrase and/or key file.

    Note that it makes no sense to encrypt your system if backup is not encrypted as well.

5. Can I use this encrypted drive with a Windows or MacOS computer?

    Yes, probably.
    I don't know for sure.
    Since I'm not really interested in a multi-OS setup, I didn't bother to look into this much deeper than a cursory search.
    The results seem... promising.

6. Can I encrypt the file system of a currently functioning computer?

    There are ways to create encrypted containers to store files in, while the remaining system is unencrypted.
    However, this post will focus on full file system encryption and that needs to happen when the partitions are being prepared during installation.

7. How hard is it to set up an encrypted system? How long will it take?

    Not really and not very long.
    In fact, you just need to follow a couple of extra steps during the installation process.

8. What are my options? What if I want something else, like those encrypted containers you just mentioned?

    Be warned---the variety and details of the options available can be a bit overwhelming to take in all at once.
    The arch wiki offers a concise writeup on [how the process works](https://wiki.archlinux.org/index.php/Disk_encryption#How_the_encryption_works) along with a summary of [various implementations](https://wiki.archlinux.org/index.php/Disk_encryption#Available_methods).
    For reference, the focus of this post will be on using `dm-crypt` to manage LUKS volumes.

9. Anything else I should know?

    Data on an encrypted drive will still be vulnerable to corruption and disk failure.
    Regular backups are pretty much the only safeguard against that.

# Setting things up

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

Normally, one would use a tool like `cgdisk` to create partitions on a storage device and then use `mkfs` to format those partitions with a file system.
We still want to create the partitions on the disk, but we don't want to format those partitions just yet.

The user interface to encrypting/decrypting a partition/volume is provided by the `cryptsetup` command.
Let's say the raw partition is called `/dev/sda3` and we would like it to be an encrypted volume.

{% highlight console %}
# cryptsetup luksFormat /dev/sda3
{% endhighlight %}

Used like this with no options, this will use a symmetric, 256-bit AES cipher to encrypt the data on this volume.
The default also uses something called the XTS mode, which effectively halves the key length.
So, the default security level corresponds roughly to using a 128-bit AES encryption scheme.

This isn't a bad starting point at all and unless you feel particular about upping your security level, you could very well go with this default.
Now, if you do feel that sounds like irresponsible sheep talking, that's fine, too.
The `cryptsetup` utility has several optional flags to specify the cryptographic scheme you will be using in finer detail.
You can change the encryption scheme (`-c/--cipher`), the key size (`-s/--key-size`), the hashing algorithm (`-h/--hash`) and a couple of other options.
[This section](https://wiki.archlinux.org/index.php/Dm-crypt/Device_encryption#Encryption_options_for_LUKS_mode) is written for you.
In what follows, I'll go with the defaults.

While creating the encrypted partition, `cryptsetup` will also ask for a passphrase.
Pick a secure passphrase.
This passphrase length is limited to 512 characters, but you can have multiple passphrases by adding or removing slots.
All passphrases are equally valid and any of them can be entered to decrypt the device when prompted.

Create encrypted volumes on all the partitions that will be mounted and used.
Leave the boot partition unencrypted.

Once you've created an encrypted volume, it's time to create a file system inside it.
To do that it must be decrypted so that we can write data to it.
Decryption is handled by `dm-crypt` by making the decrypted device available under /`dev/mapper` (that's what the `dm` in `dm-crypt` stands for---device mapper) at a sort of mount point of your choosing.
For the purposes of this post, I'm going to go with something generic like, `my-decrypted-device`, but you could and should pick a more sensible name for the device.
For instance, if the device is the root partition, pick `root` or the hostname of the system itself.
This device name is just the name of the mount point and will not be remembered by the volume, but having a sensible name will help when referring to it in commands and logs.

{% highlight console %}
# cryptsetup luksOpen /dev/sda3 my-decrypted-device
{% endhighlight %}

This command will ask for a passphrase to use to decrypt the device.
The encrypted partition `/dev/sda3` is now available as a regular, seemingly unencrypted volume at `/dev/mapper/my-decrypted-device`.
We can use this decrypted volume to create a file system and write data to it.

{% highlight console %}
# mkfs.ext4 -L root /dev/mapper/my-decrypted-device
{% endhighlight %}

You can similarly proceed with the rest of the installation procedure using `/dev/mapper/my-decrypted-device` whenever you need to refer to `/dev/sda3`.

Repeat this procedure for every encrypted partition you have created.
Again, remember that the boot partition will remain unencrypted.

## Chroot and configure the base system

This step deviates from the normal route when it comes time to build the initramfs image and setting up the boot loader (GRUB).
[Here's](https://wiki.archlinux.org/index.php/Dm-crypt/System_configuration) the relevant arch wiki page for reference.
Deviate away from the procedure when configuring GRUB.

GRUB needs to know that the root device it's looking for ('/dev/mapper/my-decrypted-device`) is actually an unlocked encrypted device.
Now would be a good time to notice that the encrypted volume `/dev/sda3` and the decrypted volume `/dev/mapper/my-decrypted-device` while being the same volume, actually have different UUIDs.

{% highlight console %}
# blkid -f
{% endhighlight %}

or

{% highlight console %}
# ls -l /dev/disk/by-uuid/
{% endhighlight %}

The default generated /boot/grub/grub.cfg would contain a line to specify where the root file system is and it would look something like this,

{% highlight text %}
linux   /vmlinuz-linux root=UUID=<my-decrypted-device UUID> rw quiet
{% endhighlight %}

To let GRUB find the encrypted device, we need to set the `cryptdevice` option.
The recommended way to do this is to edit the `/etc/default/grub` and regenerate the `/boot/grub/grub.cfg` file using `grub-mkconfig`.
The `cryptdevice` parameter takes two values, the encrypted device location and the name of the device mapper mount point you want to use.
Again, I've used `my-decrypted-device` here, but you should pick something more sensible.
Make the following edit in `/etc/default/grub`.

{% highlight diff %}
-GRUB_CMDLINE_LINUX_DEFAULT="quiet"
+GRUB_CMDLINE_LINUX_DEFAULT="cryptdevice=UUID=<encrypted-device-uuid>:my-decrypted-device quiet"
{% endhighlight %}

And regenerate the GRUB configuration file.

{% highlight console %}
# grub-mkconfig -o /boot/grub/grub.cfg
{% endhighlight %}

Now that GRUB is ready, we need to regenerate the initramfs image to include the encrypt hook.
This hook is needed to decrypt the encrypted volume during boot up.
Edit the `/etc/mkinitcpio.conf` file and add the `encrypt' hook before the `filesystems` hook.

{% highlight diff %}
-HOOKS="base udev autodetect modconf block filesystems keyboard fsck"
+HOOKS="base udev autodetect modconf block encrypt filesystems keyboard fsck"
{% endhighlight %}

Now, rebuild the initramfs image.
This step will parse the GRUB configuration and identify the encrypted device and where it should be decrypted under `/dev/mapper`.

{% highlight console %}
# mkinitcpio -p linux
{% endhighlight %}

> One thing to look out for at this step is that if you use a non-US keyboard, you might want to add the `keymap` hook as well so that you can enter the passphrase in the layout you are familiar with.
> The `keymap` hook parses the `/etc/vconsole.conf` file to load the correct key map.
> Based on this, it will load up the specified key map when prompting for a passphrase.
> Keep in mind that this hook should be before the `encrypt` hook in the list.
> I use the dvorak layout and my `/etc/vconsole.conf` file looks like this.
>
> {% highlight cfg %}
KEYMAP=dvorak
{% endhighlight %}

Once you've rebuilt your initial ramdisk, continue with the default procedure and reboot your system.
You should now be greeted by a passphrase request before the root device can be accessed.

# Using a key file

If you want to enjoy the benefits of having an encrypted file system, but do not want to enter your length passphrase each time you reboot, you may want to use a key file instead.
A key file, as I said eariler, is just a regular file that is used in the place of a passphrase.
You could use a text file or a binary file, and you could use the entire file or just a part of it.
The size of the key file (or the part of the file used) has to be under 8 MB (8192 kB).

Recall that you can have up to eight different ways of decrypting your device.
Right now, our /dev/sda3 encrypted volume uses just a single passphrase.
So there are seven remaining slots for other ways to decrypt the device.
Let's add a new slot for a key file.

{% highlight console %}
# cryptsetup luksAddKey /dev/sda3 /path/to/keyfile
{% endhighlight %}

This will prompt for your passphrase and will then add a new slot for the key file.
Now, we need to tell GRUB to find the key file.
This is done by using the `cryptkey` parameter, just like we used the `cryptdevice` parameter earlier.
The `cryptkey` parameter takes three colon-separated values.
The first is the device on which the key file is present.
The second is the file system used on the device.
And the third is the path to the file relative to the device.
As an example, if I have a secret key file called my-secret-key on my USB drive, and this drive is a FAT32 device with a UUID 1234-5678, I'll need to add the following parameter to GRUB configuration:

{% highlight text %}
cryptkey=UUID=B01C-6138:vfat:my-secret-key
{% endhighlight %}

Add this to the same line specifying the `cryptdevice` parameter in `/etc/default/grub` and regenerate the GRUB configuration as before.

Next, we need to rebuild the initramfs image to include this information.
The initial ram disk image needs to know the file system to use to read the USB drive.
Since in this case, the USB drive uses FAT32, the module needed is `vfat`.

There is one additional complication because of using such an ancient file system.
FAT32 doesn't understand Unicode and stores all the file names in a different character set, or [code page](https://en.wikipedia.org/wiki/Code_page).
The default code page used by DOS and Windows is CP850, but for the US region, it's [CP437](https://en.wikipedia.org/wiki/Code_page_437).
The module to load this is `nls_cp437` (NLS is native/national language support).

Make the following edit to `/etc/mkinitcpio.conf` to include these two modules (or if you use a different file system on the USB key, the corresponding module).

{% highlight diff %}
- MODULES=""
+ MODULES="vfat nls_cp437"
{% endhighlight %}

That should do it.
Regenerate your initial ram disk image and reboot.
This time, with a key file set up, instead of prompting you for a passphrase, GRUB will search for the key file at the location you specified.
If you don't insert the USB drive in 10 seconds, GRUB will fall back to prompting for a passphrase.
This is why it is important to have at least one passphrase, in case you lose the USB key or the key file.

Here's the relevant Arch wiki page about [key files](https://wiki.archlinux.org/index.php/Dm-crypt/Device_encryption#Keyfiles).

# Multiple encrypted partitions

The use of key files makes using multiple encrypted partitions very easy.
You no longer have to enter each passphrase during boot up.
Instead, you can have the main root partition unlock using a key file and have the key files for other encrypted partitions be available on the root partition.
This way, once the root partition is unlocked, subsequent partitions get unlocked as well.

Let's say I have a /dev/sda4 which is my /home and it's encrypted.
The secret key for this volume is located at /etc/secret-keys/home-secret-key in root file system.
To have this partition automatically unlock once root is unlocked, I need to place this information is a file similar to `/etc/fstab` called `/etc/crypttab`.
Each entry contains the name of the decrypted device, the UUID of or path to the encrypted device, the location of the keyfile and any other options.
The entry for our example would look something like this,

{% highlight text %}
home    UUID=<encrypted-device-uuid>    /etc/secret-keys/home-secret-key
{% endhighlight %}

If your encrypted volume has a LUKS header, typically, you don't need to provide any additional options.
This will create a `/dev/mapper/home` from the given UUID and use the given secret key to decrypt it.
This newly decrypted device can now be referred to in `/etc/fstab` to mount at `/home`, perhaps something like this.

{% highlight text %}
UUID=<decrypted-device-uuid>    /home   ext4    defaults    0 1
{% endhighlight %}

Here's the relevant Arch wiki page on [crypttab](https://wiki.archlinux.org/index.php/Dm-crypt/System_configuration#crypttab).

# Swap partition/swap file

I can't really improve on the Arch wiki page on the [subject](https://wiki.archlinux.org/index.php/Dm-crypt/Swap_encryption).
The page details setting up dedicated partitions for swap with and without support for suspending to disk (hibernation).
For my use case, I opted to go with a simple swap file inside the root file system without any support for suspending to disk.

# Offline access

If you want to read an encrypted volume from another machine, you need to open/decrypt it, mount the decrypted volume and then access the files.
First, make sure you have the `dm-crypt` module loaded up.

{% highlight console %}
# modprobe dm_crypt
{% endhighlight %}

Next, open the device and specify the device name where the decrypted device will become available.

{% highlight console %}
# cryptsetup luksOpen /dev/sda3 my-decrypted-device
{% endhighlight %}

You'll need to provide one of the passphrases for this device.
If you have a key file available, you could use that as well.

{% highlight console %}
# cryptsetup --key-file /path/to/keyfile luksOpen /dev/sda3 my-decrypted-device
{% endhighlight %}

Now, mount the newly available decrypted device at a mount point of your choosing and access the files.

{% highlight console %}
# mount /dev/mapper/my-decrypted-device /mnt/
{% endhighlight %}

When done, umount the decrypted device, close it and then disconnect.

{% highlight console %}
# umount /mnt/
# cryptsetup luksClose my-decrypted-device
{% endhighlight %}

I hope this has answered many of the questions you might have when setting out to research using encrypted file systems.

