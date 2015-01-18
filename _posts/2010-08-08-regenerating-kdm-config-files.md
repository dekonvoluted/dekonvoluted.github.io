---
title: Regenerating KDM config files
layout: post
categories: [ user guides ]
tags: kdm
comments: true
---

Most people will not encounter any issues with the login screen.
However, if you do set out to customize it and run into trouble, you can use the following procedure to reset kdm to "factory default" condition.

At some point, I downgraded from an unstable beta release to the older, stable release of KDE.
Rather unsurprisingly, the downgrade didn't go smooth.
One of the things that broke was the login screen.
I understand this happened because the `kdmrc` file was referencing the new greeter screen, which no longer existed after the downgrade.

Ideally, the way to fix this would be to fire up System Settings and head to the login theme control module and set things right.
For whatever reason, it didn't work for me.
So, I had to manually edit the `kdmrc` file, found at `/usr/share/config/kdm/kdmrc`.
It is a very convoluted file and I don`t recommend trying to edit it by hand.
I tried deleting it, but turned out it doesn't get automatically regenerated---I was shown a very basic fallback login screen instead.

The command that saved the day is `genkdmconf`. This command regenerates the contents of the `/usr/share/config/kdm` directory.
Navigate to the location of your kdm configuration files (`locate kdmrc` should do it) and issue the following command as root in that folder:

    # genkdmconf --no-old

The `--no-old` option tells genkdmconf to not bother reading the old config files and start fresh.
Now, you should have a brand new set of configuration dialogs.
The old versions of the configuration files will be saved with a .bak extension.
It's entirely safe to delete them when you're done.

    # rm *.bak

Now, you can restart X and enjoy your fresh new login screen.

