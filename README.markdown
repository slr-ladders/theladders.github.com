# How to write a blog post

## Overview

Development, testing and review of new blog content should be done on `blogdev.laddersoffice.net`

We publish your posts after we merge your pull request.  Talk to [Sean](http://dev.theladders.com/ourteam/seantallen) about getting your change posted (careful, he'll probably make you do it yourself).

## Initial setup

Fork this repo.

https://github.com/TheLadders/theladders.github.com

After it's forked, ssh to `blogdev.laddersoffice.net` and clone your fork:

```
git clone git@github.com:YourGithubName/theladders.github.com.git ~/theladders.github.com
```

NOTE: You will have to make sure your SSH **private** key is installed in `~/.ssh/id_rsa` on blogdev.laddersoffice.net before being able to clone the repository. This must be the private key associated with the public key that GitHub is aware of, which may not necessarily be the private key that you use to log into machines on our network. If you have more than one set of keys, make sure you're using the right one.

cd into the repository:

```
cd theladders.github.com
```

Switch to the source branch.

```
git checkout source
```

Update octopress's dependencies (probably will not do anything):

```
bundle install
```

Now you're ready to start writing up your blogpost.

## Creating a blog post.

Create a new post and give it your desired title

```
bundle exec rake new_post["Bob Loblaws Law Blog Post"]
```

You'll see this:

```
mkdir -p source/_posts
Creating new post: source/_posts/2013-03-07-bob-loblaws-law-blog-post.markdown
```

Open up your favorite text editor and edit `source/_posts/2013-03-07-bob-loblaws-law-blog-post.markdown`.  You will see:

```
---
author:
layout: post
title: "Bob Loblaws Law Blog Post"
date: 2013-03-07 11:05
comments: true
categories:
published: false
---
```

If you plan to post this at a later date, do yourself a kindness and rename the file now to that date, and modify the date in the markdown.  Also, give it an author and category while you're at it.

```
author: Bob Loblaw
categories: Category1, Category2, Category3
published: false
```

Make sure Bob Loblaw is *exactly* the name you have in your http://dev.theladders.com/ourteam profile.  At the end of the post it'll link your byline to your profile page automagically.  Don't break it.

Take a look at the existing categories of other posts and see if yours fits.  If not, ask [Sean](http://dev.theladders.com/ourteam/seantallen) or [Andy](http://dev.theladders.com/ourteam/andrewturley) about approriate categorization.

Lastly, leave the `published: false`.  You'll still be able to see it in preview mode, but you'll ensure you don't accidentally publish it by doing so.

Got that?  Good, moving on to content.

## Adding content to your post

Start adding all your fabulous content, start with an image if it's appropriate, and a quote as is our custom:
```
---
author: Bob Loblaw
layout: post
title: "Bob Loblaws Law Blog Post"
date: 2013-03-07 11:05
comments: true
categories: Category1, Category2, Category3
published: false
---
{% img center /images/bob_loblaw.gif 'Law Blog' %}

{% blockquote --Bob Loblaw %}
I thought that maybe I would stay in and work on my law blog.
{% endblockquote %}
```

Note that you'll want to drop your image into /source/images for this to work.

Code snippets are a snap.  They're of the form:

<pre>
``` [language] [title] [url] [link text]
code snippet
```
</pre>

<pre>
``` ruby Discover if a number is prime http://www.noulakaz.net/weblog/2007/03/18/a-regular-expression-to-check-for-prime-numbers/ Source Article
class Fixnum
  def prime?
      ('1' * self) !~ /^1?$|^(11+?)\1+$/
	    end
		end
```
</pre>

That's about it.  You're off and running.

## Preview mode

In a second terminal window, ssh to `blogdev.laddersoffice.net`, cd into the repository and run:

```
bundle exec rake watch
```

It'll watch for changes and update every time you save.  Very handy.  When in preview mode it will also render `published: false` pages, so don't freak out.

You'll be able to view your version of the blog at `http://[YOUR_QA_USER_NAME].blogdev.laddersoffice.net`

## It's all ready to go

Make sure you've added the new file to be tracked by git:

```
git add source/_posts/2013-03-07-bob-loblaws-law-blog-post.markdown
```

and any other resources your post depends on:

```
git add source/images/bob_loblaw.gif
```

Still not sure if you've added everything?

```
git status
```

Commit it.

```
git commit -m source/images/bob_loblaw.gif source/_posts/2013-03-07-bob-loblaws-law-blog.post.markdown "new post on bob loblaws law blog"
```

Push it.

```
git push origin source
```

Remember to specify source.  Everything we're doing here is in the source branch.  *Not master.*

Now you're ready to issue a pull request.  If you're new to doing pull requests, ask any member of the platform team.  You'll do it once and never forget.  It's like riding a bike.  But I'm not documenting how to ride a bike here.

## Social

After it's live, put a link to your post up over on http://news.ycombinator.com/ and http://reddit.com/r/programming if appropriate.  After it's up, let [Sean](http://dev.theladders.com/ourteam/seantallen) know and he'll add it to your post for further discussion.

## Protips

1. Make the first sentence count.  Shocking statistic, bombastic claim, etc.
2. Use # for h2, ## for h3.  Mostly stick to h2s.
3. Separate your sections with a ****.  It gives it a nice horizontal rule that segments the page.
4. If things get wonky and you don't trust compass is watching your changes properly, rm -rf public and rake generate.  That'll rebuild everything.
5. If there's something you can't figure out, it's probably here http://octopress.org/docs/
6. Syntax errors will silently fail for a post with publish set to false.  If your post isn't being updated or not appearing at all, try setting publish to true and regenerate.  You should see then see the syntax errors.

## Editing Our Team

### New faces

When a new engineer starts at TheLadders, inform them as soon as possible that they're on the hook to put together their own bio to be added to the [Our Team](http://dev.theladders.com/ourteam/) page.

1. Make sure the new engineer has a gravatar account and that they've added their @theladders.com email address to gravatar.
2. Put the new engineer's bio in `source/_includes/ourteam/newengineer.markdown` (replace `newengineer` in this and all following instructions with the new engineer's name). Bios should be written in HTML using the following format:
   
    ```
    
    <div class="profile-container">
        <div class="profile-thumb">
            {% gravatar newengineer@theladders.com %}
        </div>
        <div class="profile-content">
            <strong>New Engineer</strong> has a bio. It goes here.
        </div>
    </div>
```
3. Create a directory for the new engineer under `source/ourteam`
4. Create `source/ourteam/[NEW_ENGINEER]/index.markdown` with content based on:

    ```
---
layout: page
title: "New Engineer"
comments: false
sharing: false
footer: false
---
{% include ourteam/newengineer.markdown %}
```
5. Add a new entry for the engineer in `source/ourteam/index.markdown` like:

    ```
{% include ourteam/newengineer.markdown %}
****
```

*NOTE* Entries are alphabetized by last name.

### Someone left

When a member of the engineering staff leaves the company, their profile should be removed from the site and references to them should be updated.

#### Our Team

1. Remove the departed engineer's profile in `source/_includes/ourteam`
2. Remove the departed engineer's directory under `source/ourteam`
3. Remove the section of `source/ourteam/index.markdown` for that person

#### Blog posts

Any blog posts authored by the departed engineer should be have the `author` line in the post header removed to prevent auto-linking to their Our Team profile as shown below:

##### Before

```
---
author: Bob Loblaw
layout: post
title: "Bob Loblaws Law Blog Post"
date: 2013-03-07 11:05
comments: true
categories: Category1, Category2, Category3
published: false
---
```

##### After

```
---
layout: post
title: "Bob Loblaws Law Blog Post"
date: 2013-03-07 11:05
comments: true
categories: Category1, Category2, Category3
published: false
---
```

References to the author's profile should be updated throughout the blog posts to prevent broken links.  Our rule of thumb for updating references is to replace links to their Our Team page with links to their twitter profile as shown below:

##### Before

```
My team mate [Matt Chesler](http://dev.theladders.com/ourteam/mattchesler/)
```

##### After

```
My team mate [@CheslerMatt](http://twitter.com/cheslermatt)
```

## Deploying

If you're one of the cursed few burdened with the responsibility of merging and deploying blog posts, you could google something like ["deploying octopress to github pages"](http://lmgtfy.com/?q=deploying+octopress+to+github+pages&l=1), or you could follow the steps below:

1. Confirm that you have push/pull privileges for this repository
2. Clone the repository: ```git clone git@github.com:TheLadders/theladders.github.com.git```
3. ```cd theladders.github.com```
4. Change to the source branch: ```git checkout source```
5. Ensure you're working with head (this is more relevant if you already had the repo cloned locally): ```git pull```
6. If it hasn't already been done, edit the new post, set published to true, push to source
7. Create a ```_deploy``` subdirectory: ```mkdir -p _deploy```
8. Clone the repository's master branch to ```_deploy```: 

	```shell
	cd _deploy
	git clone git@github.com:TheLadders/theladders.github.com.git .
	```
	
9. Regenerate the blog contents: ```bundle exec rake generate```
10. Deploy the blog (includes an automated commit on master): ```bundle exec rake deploy```
