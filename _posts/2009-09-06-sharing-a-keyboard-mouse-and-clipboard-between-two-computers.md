---
title: Sharing a keyboard, mouse and clipboard between two computers
layout: post
categories: [ user guides ]
tags: [ synergy ]
comments: true
---

# Problem Background

I have two computers at home side by side and would like to share a keyboard and a mouse between them.
It would be a great help to share the clipboard as well as it would let me move bits of text really quickly between the two computers (select on one and paste in the other).

As an example, let's say the 'server' computer has a physical keyboard and mouse.
It is located to the right of the 'client' computer.
The server's keyboard and mouse needs to be used on the client.

# Solution

The package I'll use is called synergy.
Since synergy sends unencrypted information back and forth, I'll need to route it through an ssh tunnel so that no one can snoop on my key strokes and clipboard contents.
Here's how to implement this.

1. Install synergy on both computers.

    Arch linux has synergy in its `extra` repository.

        # pacman -S synergy

    > The # prompt indicates that the command requires root privileges.
    > Similarly, a $ prompt indicates that a command does not require root privileges.

2. Edit the /etc/synergy.conf file on both machines.

    This file specifies the physical layout of the screens to synergy.
    This way, The mouse will smoothly transition from one computer to another when it encounters the correct screen edge.

    The contents of synergy.conf should look like this on both machines: (Replace `SERVER` and `CLIENT` by the correct IP addresses/hostnames)

{% highlight yaml %}
section: screens
    SERVER:
    CLIENT:
end

section: links
    SERVER:
        left=CLIENT
    CLIENT:
        right=SERVER
end

section: aliases
end
{% endhighlight %}

    These files can also be saved in one's home directory as ~/.synergy.conf.

3. On the server, start the synergy server.

        $ synergys

4. On the client, open an ssh tunnel to the server.

    > Note that this is an optional, but strongly recommended step.

        $ ssh -fNL 24800:SERVER:24800 USERNAME@SERVER

5. On the client again, start the synergy client.

        $ synergyc localhost

    If there's no ssh tunnel running, replace `localhost` in the above command by `SERVER`.

Now, I have a working setup with two computers sharing the same mouse and keyboard!
The keyboard strokes are sent to the computer whose screen the mouse cursor is on.

# Problems

- If a corner or edge of the screen is shared between the two computers, kwin effects cannot be designated to those corners or edges.
- I've sometimes seen the mouse jump to the center of the client screen when transitioning past the edge of the server screen.

