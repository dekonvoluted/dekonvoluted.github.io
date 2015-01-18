---
title: Seamless file sharing with KDE
layout: post
categories: [ user guides ]
tags: [ avahi, fish, ssh ]
comments: true
---

This post documents what I did to get my three (KDE-powered) computers to seamless share files.
First, let me define the use case.

I'm browsing files on my desktop using Dolphin, the file manager.
I need to access files that are on my laptop.
My laptop is powered on and connected to the network.
I click on a shortcut in the Places sidebar and I can see the home directory on my laptop.
I can navigate around and drag-drop files to and from my laptop.

The following instructions use defaults wherever possible.
You're free to deviate from these defaults anytime you feel like it.

# SSH setup

First, I need to set up ssh on all the machines.
On each machine, I install the `openssh` package and start its daemon using `systemd` like so,

    # systemctl enable sshd

Next, I need to generate ssh keys to authenticate my connections.
On each machine, I create keys like so,

    $ ssh-keygen

I accept the defaults and pick a pass phrase.
Since I used no optional arguments to indicate the type or the size of the key pair, it defaulted to producing a 2048-bit long RSA key pair.

# Avahi setup

Now, I need to set up `avahi` so that these machines can discover each other on the network.
On each machine, I install the `nss-mdns` package and tweak a line in the `/etc/nsswitch.conf` configuration file so that the hosts line reads like so,

{% highlight yaml %}
hosts: files dns mdns
{% endhighlight %}

Now, I install the `avahi` package and start the avahi daemon like so,

    # systemctl enable avahi-daemon

Now, all machines appear on the network as hostname.local.

# SSH setup Part 2

This bit is optional, but I like the benefits it provides.
First, I don't want to have to type the ".local" part every time I access my machines.
Second, I'd like to not have to type in my passwords or my key passphrase every time I connect.

## SSH config

Create the `~/.ssh/config` file if it doesn't exist and define some hosts.
You can name them whatever you like and put in the actual parameters underneath.
In the following example, I named my host "laptop" and the only parameter I need is that its hostname is `theevilmachine.local`.
If your username on the host is not the same as the one on your current machine, you might want to add that here.
Similarly, if the ssh daemon is running on a non-default (22) port, you might also want to include that here.

{% highlight text %}
Host laptop
    Hostname theevilmachine.local
{% endhighlight %}

This lets you ssh to `theevilmachine.local` by typing just,

    $ ssh laptop

## SSH agent

Next, I want to not have to enter passwords or passphrases.
KDE will automatically launch an ssh-agent instance for you.
You just need to add your key (or keys) to the agent once per session.
The agent will handle the authentication transparently for you till you logout and your session ends.

Add your key (or keys) to the agent like this,

    $ ssh-add

You'll need to provide the passphrase for the key (or keys).
To start using the keys, you need to copy the public part of the key pair to each remote machine.
You can do this like so,

    $ ssh-copy-id laptop

# Dolphin setup

Almost there.
Now, just open your file manager and right-click on the Places sidebar and add a new entry.
You can pick the label and icon, but under location, put down `fish://laptop`.
Create an entry for each remote machine.

# Enjoy

That's it.
You're done.
At login, run `ssh-add` in a terminal to add your keys to the agent and enjoy seamlessly dragging and dropping files between your machines.

This will also make your work easier on the terminal.
For instance, if your keys have been added to the agent, you'll notice that tools like `scp` can tab-complete your path on remote machines.

