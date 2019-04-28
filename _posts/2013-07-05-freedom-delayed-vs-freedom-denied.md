---
title: Freedom delayed vs. Freedom denied
layout: post
categories: [ musings ]
tags: [ gpl, free software ]
---

# If you build it, they will come

The tenets of software freedom boil down to granting the user the four essential freedoms: to use a program, to study it, to change it and to pass on the changes to others.
We may split the pool of users into two camps of passive and active users.
Passive users have no interest or no skill in studying and modifying the program and merely want to use it to get their work done.
Active users, or developers have the skills to study and improve the software.
In my ideal world, free software would be the norm.

However, over the years, advocates of software freedom have struggled to present their case to users and developers alike.
The problem with attracting more users boils down to availability (not being installed by default) and the quality (being buggy or unpolished) of free software.
These correlate with the paucity of developers that most, if not all free software projects currently face.
Hence, it all comes down to the problem of attracting more developers to free software.
I doubt I would face much opposition if I were to state that this is primarily a question of money.

I put it to you that the majority of developers choose to develop programs for closed platforms precisely for this reason.
They are not motivated by some anti-freedom ideology, nor are they merely pricks and hate all users.
It is simply a question of lucre and were it profitable to develop for an open platform, they would readily switch over.
An attendant fraction follow this majority to take advantage of the large available user base.
A somewhat smaller fraction develop for closed platforms due to a sense of allegiance and familiarity.
A very tiny fraction chooses to contribute to free software either because their needs are of limited importance to them, or through fortuity, they managed to be employed at a company that values free software.

A lot of this boils down to feedback loops and cycles, vicious or otherwise, that reinforce this distribution.
The distribution of passive users tends to mirror the distribution of the active users and this will lead irrevocably to closed platforms and technologies becoming the standards of public and government discourse.
If we are to prevent this from happening, we need to address the root cause of this distribution and that is the question of money.
For all the bluster of freedom, if we cannot address the basic needs of livelihood of the developers, we must necessarily resign ourselves to being in the underdog status, along with the commiserate loss of power and representation in the public sphere.
To bring this full circle, not only do we need to build it, we need to pay the builders or "they" will never even have the option to begin with.

# We interrupt this program for a special news bulletin...

You might think that the recent developments relating to games arriving to Linux, exemplified by Steam's release of a linux client, constitute a counterexample.
A case where the passive user base forms the leading edge of the feedback loop.
You might argue that with the availability of games, passive users, with no interest or skill in development will switch platforms and developers will follow.
Presumably, this will set events into motion that will result in an open platform like Linux becoming lucrative and wouldn't that make everyone happy?
Of course, those harpies over at the FSF will not be happy, but shouldn't we see the bigger picture here?
Using a distasteful military analogy, even though we would lose the battle for free software, we will win the war for open platforms.

I disagree with this point of view.
While I don't disagree that this is a viable solution to increasing the Linux user base, I do see this coming at the cost of something we would rather not lose.
I think this is a case where the FSF has unwittingly engineered the debate in such a way that it led to their inevitable marginalization.
Let me explain.

At the center of all this is that cherished document of freedom, the GPL.
By limiting the choice to a yes or a no, the developers are being forced to choose the no option.
Even if they would otherwise be sympathetic towards the cause of software freedom.

There is value in sticking to principles and there is a cost to inflexibility.
In this case, the cost is that the GPL ends up denying the very freedom it was created to protect.
Overwhelmingly, the new games that will arrive on Linux will be entirely closed source because that is what allows the developers to make money.
While the platform remains ostensibly open, the vast majority of developers working on it end up creating closed software.
This is only marginally better than the current situation.
A platform that doesn't promote openness is of very limited value to software freedom in the long run.

# Towards a delayed GPL

I would like to propose an alternative.
As a start, we must recognize that most of the money a program makes, it makes within the first three to five years.
Releasing it open source means the developers cannot make this money, but releasing it closed source means that long after the opportunity to monetize their work has passed, the software remains closed and unavailable to the users, passive or otherwise.
John Carmack offers an illustrative example of following the middle ground here.
In the past, he has released the source code for several of his games under the GPL about three to five years after their original release.
These games, from Wolfenstein 3D to Doom3 have been very popular among gamers and their engines have been reused by multiple free software games.
On the whole, this is an example of work that generated revenue for its developers and yet didn't get locked up and got thrown away forever after it ceased making money.

Wouldn't it be interesting to have this be the default state of things?
My proposal is that there be a variant of the GPL with a built-in delay clause.
Let's call it the dGPL (delayed GPL).
At release, the developer releasing a program under the dGPL agrees that the program will remain closed source for an initial period.
Even if the program uses libraries that are currently protected by the GPL, the dGPL still covers the program during this initial period.
This period could extend from a minimum of one year to a maximum of, say, five years and is up to the developer to choose.
Like the GPL, any patches released to the game will be covered by the same dGPL clause and at the end of the closed time period, all of the original and patch source code will become regular available as free and open source software under the GPL.

The question of how the dGPL exists and works alongside existing GPL source code is a particularly tricky area to navigate.
Even though it directly contravenes the original authors' intentions, I favor allowing the dGPL software to link to existing GPL'd libraries.
The original libraries will still be freely available, but the new work will remain closed source for the initial time period.
I recognize that this might be distasteful to some, or all of the existing free software developers, but I also firmly believe that it will lead to greater and more widespread use of GPL'd libraries in the long run.
No longer, for instance, would a developer need to avoid a GPL'd library in favor of an LGPL'd one if they intend to make money from an application.

Perhaps not everyone would want to jump on to this license overnight.
Most may well choose to stick to proprietary licenses for their work.
However, I do see this as a much more amenable alternative to the existing black-and-white approach to software freedom.
For starters, it makes an effort to recognize the primary motivation of a typical developer, which is to monetize their work, not make political statements.
This, I think, represents a giant leap towards a more realistic approach to achieving software freedom.
Even if one developer chooses to release their work under the dGPL instead of a proprietary license, this ends up as a net benefit rather than a loss.

# The role of the FSF

So, why not call this license something else, instead of evoking (and besmirching!) the hallowed GPL, you say?
Also, what stops the evil, money-grubbing developer (as opposed to the honest and hard-working free software developers, of course) from never releasing the source as they promised?
Why they could just claim it was all a bad joke or something!

Well, that's where the FSF would come in.
When someone releases a program under the dGPL, they turn over the source code to the FSF.
The FSF then fulfills its part of the bargain by locking up the code (how ironic) and will release it only when the dGPL time delay is up.

One of the nice things this does is that it pushes the FSF into the fore front to actively participate with people who write and make a living off code, rather than just limit their impact to activism on the sidelines.
If the FSF is ready to take on this responsibility, I think it has the potential to transform it from a nearly unheard of organization to taking on the public awareness level of something like Wikipedia.
Everybody wins.

