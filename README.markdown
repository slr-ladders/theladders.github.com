## How to write a blog post

### Prereqs

If this is the first time you're using ruby to do anything, go and do yourself a favor and install rvm.  https://rvm.io/

And obviously make sure you've got git installed.

I've not tried any of this on windows.  This is kid tested OSX and Linux approved.

### Overview

We publish your posts after we merge the a pull request.  [@jconnolly](https://github.com/jconnolly) or [@seantallen](https://github.com/seantallen) will deploy it.  

### Initial setup

Fork this repo.

https://github.com/TheLadders/theladders.github.com

After it's forked, clone your fork:
```
git clone git@github.com:YourGithubName/theladders.github.com.git
```

cd into the source directory.
```
cd theladders.github.com
```

If you see this:
```
==============================================================================
= NOTICE                                                                     =
==============================================================================
= RVM has encountered a new or modified .rvmrc file in the current directory =
= This is a shell script and therefore may contain any shell commands.       =
=                                                                            =
= Examine the contents of this file carefully to be sure the contents are    =
= safe before trusting it! ( Choose v[iew] below to view the contents )      =
==============================================================================
```

It's okay.  I'm not hacking you.  You'll be okay.  If you don't see it and this is your first time cding into that directory, you haven't installed rvm.  I'm not kidding, install rvm.  https://rvm.io/

Switch to the source branch.

```
git checkout source
```

Install bundler

```
gem install bundler
```

Install octopress's dependencies:

```
bundler install
```

Now you're ready to start writing up your blogpost.

### Creating a blog post.

Create a new post and give it your desired title

```
rake new_post["Bob Loblaws Law Blog Post"]
```

You'll see this:

```
mkdir -p source/_posts
Creating new post: source/_posts/2013-03-07-bob-loblaws-law-blog-post.markdown
```

Open up your favorite text editor and edit source/_posts/2013-03-07-bob-loblaws-law-blog-post.markdown.  You will see:

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
Take a look at the existing categories of other posts and see if yours fits.  If not, ask [@seantallen](https://github.com/seantallen) or [@jconnolly](https://github.com/jconnolly) about approriate categorization.
Lastly, leave the published: false.  You'll still be able to see it in preview mode, but you'll ensure you don't accidentally publish it by doing so.

Got that?  Good, moving on to content.


### Adding content to your post
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

### Preview mode

Work locally.  run
```rake preview```
and it'll watch for changes and update every time you save.  Very handy.  When in preview mode it will also render published: false pages, so don't freak out.

### It's all ready to go
Make sure you've added the new file to be tracked by git:

```
git add source/_posts/2013-03-07-bob-loblaws-law-blog-post.markdown
```
and any other resources your post depends on:

```
git add /images/bob_loblaw.gif
```

Still not sure if you've added everything?  

```
git status
```

Commit it.
```
git commit -m "new post on bob loblaws law blog"
```

Push it.

```
git push origin source
```

Remember to specify source.  Everything we're doing here is in the source branch.  *Not master.*

Now you're ready to issue a pull request.  If you're new to doing pull requests, ask [@jconnolly](https://github.com/jconnolly).  You'll do it once and never forget.  It's like riding a bike.  But I'm not documenting how to ride a bike here.

### Protips

1. Make the first sentence count.  Shocking statistic, bombastic claim, etc.  
2. Use # for h2, ## for h3.  Mostly stick to h2s.  
3. Separate your sections with a ****.  It gives it a nice horizontal rule that segments the page.
4. If things get wonky and you don't trust compass is watching your changes properly, rm -rf public and rake generate.  That'll rebuild everything.
5. If there's something you can't figure out, it's probably here http://octopress.org/docs/
