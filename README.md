# deKonvoluted

This is my blog.
It's a static site generated by jekyll and sticks to being very simple (and probably ugly).
Most blog posts here are things I learned on my own, so are only as accurate as I understood them when writing them down.
I do think I'm getting better at both understanding and writing about things, though.

## Layouts

There are three main layouts.
The default layout forms the basis for all of them and the page layout is pretty much the same as the default layout minus the title.
The post layout is used by blog posts and supports `series`, `subtitle`, and `repo` keys.
The `series` string identifies the post as being part of a series.
The `subtitle` lets multiple blog posts have the same main title, particularly when they are part of a series.
The `repo` key lets one specify a repository for associated code.
Finally, the archive layout is used for listing all the posts in the blog and sorting them by year, category, or tag.

## Code

The code included is syntax-highlighted using rouge.
There's a nice bit of CSS that makes line numbers (if present) not selectable by mouse so that code blocks can be easily copied.

## Comments

I haven't implemented comments yet and that's probably okay for now.
I intend to set things up so that someone with a comment can either email me or submit a pull/merge request adding their comments to the post in question.
It's a small enough thing and I'll get around to it one of these days.

## Reuse

I think it's quite easy to fork and reuse this, so feel free to.
Throw out the contents of the `_posts` directory and change some keys in `_config.yml` and that should do it.

