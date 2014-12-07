---
title: Using VNC between two linux computers
layout: post
categories: [ user guides ]
tags: [ x11vnc ]
---

# Problem Background

I want to connect to my work computer from home, to the primary X session and continue working remotely.
My work computer is the vnc server.
My home computer (the client) is to use a vnc viewer such as krdc (KDE Remote Desktop Client) to allow me to control the remote machine.
An added layer of complexity arises from the firewall that I need to tunnel through to reach my machine at work.

# Solution

Server side, I'll use x11vnc to accomplish this.
This is because x11vnc allows me to connect to the primary X session---I need this since I might already have applications running at work and would like to continue where I left off.
If this is not a concern, you can use tightvnc or other vnc servers, but you will need to start a separate X session to connect to.

As an aside, for working with GUI programs, vnc works out better than ssh with X11 forwarding.
This is because if the connection gets dropped, an application forwarded through ssh will terminate, sometimes uncleanly, leading to potential data loss or corruption.
vnc, on the other hand, leaves the application running on the server and you have the possibility of resuming after you reconnect.
Further, if the application was already running on the server to start with, ssh forwarding doesn't really help.

> Tunneling all vnc communication through an ssh tunnel, though optional, is highly recommended.

1. Install the `x11vnc` package on the server.

        # pacman -S x11vnc

2. Set up a vnc password for authentication.

    This step is optional, but recommended as without a password, anyone can connect to the vnc server.
    The following command will store a vnc password in ~/.vnc/passwd.

        $ x11vnc -storepasswd

3. Open the first of two tunnels.

    The first tunnel is for ssh.
    The following command will open a tunnel from local port 2222 (or any other port of your choice) to remote port 22.

        $ ssh -fNL 2222:REMOTE:22 USERNAME@GATEWAY

4. Connect to the remote server and start the x11vnc server.

        $ ssh -p 2222 localhost
        REMOTE $ x11vnc -create -usepw -noxdamage

    The `-create` flag for x11vnc will scan for X sessions you're logged into and connect to it if it finds one.
    If you're not logged in, or if someone else is logged in at the remote machine, it will create a new session for you.
    This new session cannot be viewed by someone at the remote server console.

    The `-usepw` flag tells the server to use an authentication password.
    The first place this looks for a stored password is in ~/.vnc/passwd.

    The `-noxdamage` flag is a performance option that worked well for me.

    When starting the x11vnc server, make a note of the port number the x11vnc server is listening on.
    Usually, this will be port 5900.

5. Open the second tunnel to the port vnc is listening on.


        $ ssh -fNL 5959:REMOTE:5900 USERNAME@GATEWAY

    Replace 5900 with the appropriate port number, if necessary.

6. Start a vncviewer locally and connect to the remote x11vnc server.

When you're done, terminate the x11vnc server on the remote machine.
If you logout, the server automatically terminates.

# Problems

- If you connect to a locked X session, it remains visible remotely.
    Other than leaving your monitor turned off, I haven't come up with a better solution for this.
    If the remote machine is either at the login screen or if someone else is already logged in, the new session is invisible to the remote user.
- Performance is wickedly slow, especially when compared to protocols like rdp (remote desktop from Windows).
    This seems to be the best vnc is capable of.
    I've heard good things about freeNX and will play with it when I get the time.
    If you have any suggestions about improving the performance of vnc, do let me know!

