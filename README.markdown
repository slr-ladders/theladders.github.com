## How to write a blog post

### Prereqs

First!  Ask Sean or John for to add you to the blog team with write access.

If this is the first time you're using ruby to do anything, go and do yourself a favor and install rvm.  https://rvm.io/

And obviously make sure you've got git installed.

### Initial setup

Clone this repo.

```
git clone git@github.com:TheLadders/theladders.github.com.git
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

It's okay.  I'm not hacking you.  You'll be okay.

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

Do some initial repo naming/git configuration and directory creation.  When prompted, give it the repo url you used to clone it, git@github.com:TheLadders/theladders.github.com.git

```
rake setup_github_pages
```

Now you're ready to start writing up your blogpost.

### Creating a blog post.

Create a new post and give it your desired title

```
rake new_post["I think OOP is awesome and so can you"]
```

You'll see this:

```
To eliminate this warning, please install libyaml and reinstall your ruby.
mkdir -p source/_posts
Creating new post: source/_posts/2013-03-07-i-think-oop-is-awesome-and-so-can-you.markdown
```

Open up your favorite text editor and edit source/_posts/2013-03-07-i-think-oop-is-awesome-and-so-can-you.markdown.  You will see:

```
---                                                                                                                                                                                                                                     
layout: post
title: "I think OOP is awesome and so can you"
date: 2013-03-07 11:05
comments: true
categories: 
---
```

If you plan to post this at a later date, do yourself a kindness and rename the file now to that date, and modify the date in the markdown.  Also, give it a 

```
author: My Name
categories: Category1, Category2, Category3
published: false
```

Make sure My Name is *exactly* the name you have in your http://dev.theladders.com/ourteam profile.  At the end of the post it'll link your byline to your profile page automagically.  Don't break it.
Take a look at the existing categories of other posts and see if yours fits.  If not, ask Sean or John about approriate categorization.
Lastly, put it in published: false.  You'll still be able to see it in preview mode, but you'll ensure you don't accidentally publish it by doing so.

Got that?  Good, moving on to content.


### Adding content to your post
Start adding all your fabulous content, start with an image if it's appropriate, and a quote as is our custom:
```
---
author: Matt Jankowski
layout: post                                                                                                                                                                                                                            
title: "Riders on the Storm: Take a long holiday, Let your children play"
date: 2013-03-04 13:52
comments: true
categories: Storm
published: false
---
{% img center /images/lightning_storm.gif 'Lightning Storm' %}

{% blockquote --Charles Dickens %}
It was the age of wisdom, it was the age of foolishness
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

### Protips

1. Make the first sentence count.  Shocking statistic, bombastic claim, etc.  
2. Use # for h2, ## for h3.  Mostly stick to h2s.  
3. Separate your sections with a ****.  It gives it a nice horizontal rule that segments the page.
4. If things get wonky and you don't trust compass is watching your changes properly, rm -rf public and rake generate.  That'll rebuild everything.
5. If there's something you can't figure out, it's probably here http://octopress.org/docs/
