---
title: My Adventures with Arch Linux
subtitle: Part 1 - Motivation
layout: post
series: archlinux
categories: [ user guides ]
tags: [ arch linux ]
---

> This article refers to deprecated software and methods.
> It is presented here for archival purposes only.

> Before I begin, a disclaimer. Arch Linux is DEFINITELY not for people new to linux.
> For them, I'd whole-heartedly suggest using a user-friendly distro like Ubuntu just to get a feel for how things work in linux.
> Arch Linux is also not for people who don't have the time or inclination to learn how their computer works.
> Frequently, you will need to dig into configuration files and sometimes, use trial and error to determine which settings work for you during the set up process.
>
> On the plus side, if you are comfortable with editing config files by hand, if you seek a high degree of control over what your machine does or if you are just too curious to be discouraged at this point, walk right in.
> You don't need to be a linux god to enjoy Arch Linux---I've never compiled a single package from source and I loved setting up Arch Linux on my laptop.

After reading [this blog](http://blog.antonywilliams.com/2008/07/13/linux-guru-then-switch-to-arch-linux/) on [FSDaily](http://www.fsdaily.com/EndUser/Linux_guru_then_switch_to_Arch_Linux), I was eager to try out [Arch linux](http://www.archlinux.org/).
The two biggest things that appealed to me were the idea of a rolling release (I was getting tired of the release update breaking my Kubuntu every six months, effectively forcing me to reinstall everything) and the promise of a "pure" linux experience.
On a minor note, I was also impressed by the assertion that Arch linux remained very up to date and was usually one of the first to release an updated version of a package.

A test install on virtualbox at work showed no glaring difficulties in using it as my main system.
The live CD also had no issues.
So, I decided to go ahead and wipe out Kubuntu Hardy and replace it with Arch Linux at work.
I chose the KDE3 environment as KDE4 (at that time, 4.0.5) still had issues.

I was pleasantly surprised by how light and responsive the system was.
There were no unnecessary daemons running and the memory usage at bootup was 109 MB.
That was impressive by itself.

A week or more later, KDE 4.1.0 was released and Arch, with its customary speed, [rolled it out](http://www.archlinux.org/news/402/) and replaced my KDE3 install.
This was probably not a very nice thing for Arch to do, but I had sufficient warning---the package manager told me exactly what it was going to do if I said yes.

KDE 4.1.0, if you haven't heard already, is quite stable and mature, so I didn't really mind losing my KDE3 install at the end of the day.
If anything, it convinced me that the time was ripe to roll out the install on my home laptop.

My expectations were not so modest for the 'home' install.
Everyone faults Kubuntu for providing one of the worst KDE experiences in the linux world.
So, firstly, I wanted to see what a "pure" install of KDE was really like.
Second, I expected the install to run very light on resources and thus, to be quick and responsive.
(To be fair, the Kubuntu install really wasn't all that heavy.)
Third, I expected to see fewer bugs because of Kubuntu specific alteration of the KDE packages.
Lastly, I wanted to have more control and knowledge of my system.
I wanted to know where to fix things if something broke.
Essentially, looking to advance my geek cred, I suppose.

The main reason for this series of posts is to archive my experience so that it may come in handy to someone else later on.
The second reason is to be able to refer to it myself if I need to perform another install in the future.

Next up, Part II – The Installation!

