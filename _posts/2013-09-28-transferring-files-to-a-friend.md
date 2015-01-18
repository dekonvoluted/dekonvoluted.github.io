---
title: Transferring files to a friend
layout: post
categories: [ user guides ]
tags: [ torrent ]
comments: true
---

I've often encountered the need to transfer one or more files (of various sizes) to someone who's otherwise reachable by instant messaging.
If file transfer over IM protocols was supported by all existing protocols, that would have been the end of the story.
However, it's probably safer to say that most IM protocols DON'T support file transfer, making this simple operation unnecessarily hard.
[XKCD](http://xkcd.com/949/) says it best, as usual.

I never thought of using torrents as a simple solution to this problem.
This is in part because I subconsciously associated torrents with public file sharing and didn't think of it when needing to share file privately.
Yet, this approach has some distinct advantages.
Virtually everyone has a torrent client installed and if they don't, suggestions are easy.
KDE's default download manager, `kget`, for instance, will happily launch torrents.
And the torrent files are always a few kilobytes in size, so they can always be sent over email (yes, I do see the irony of this solution still depending on getting a file across).
And as we'll see in a bit, creating a torrent file is a lot simpler than getting a secure server up and running.

# Creating a torrent file

In this step, we'll prepare the torrent file.
Launch your torrent client and look for an option to create a new torrent.
In KTorrent, this is under File > New and it should bring up a simple dialog box.
First, select the file or directory you want to send over.
You can leave most of the settings unchanged.
Selecting the use of DHT or not doesn't seem to make much of a difference for private torrents.

Then, add trackers to the torrent.
The following trio seem to be the popular choices for this step.
You need to add at least one.

    udp://tracker.openbittorrent.com:80/announce
    udp://tracker.publicbt.com:80/announce
    udp://tracker.istole.it:80/announce

That's it.
Hit OK and you'll have a torrent file ready to send to your friend.

Remember not to close your torrent application till the transfer is done.
You need to be "seeding" (or uploading) the file for your friend to "leech" (or download).

# Sending the torrent file

You can just attach this torrent file to an email and send it over.
If the two of you are tech savvy, you could encrypt the file using your friend's public key so that the file can't be opened by anyone else.
You might just want to do that for all your mails, actually.
A mail client like kmail makes this very simple to do.

# Transferring the files

When your friend launches the torrent, their torrent client will use the tracker to make a direct connection to your computer.
You should see them show up as a leech while you're the lone seeder.
You can track the transfer by looking at how much data has been uploaded.
When the transfer completes, this will roughly be equal to the size of the file you sent and the torrent will have two seeders.
At this point, both of you can safely stop the torrent from seeding and delete the torrent file and close torrent application.
Mission accomplished.

