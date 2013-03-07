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

Make sure My Name is *exactly* the name you have in your /ourteam profile.  At the end of the post it'll link your byline to your profile page automagically.  Don't break it.
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

That's about it.  You're off and running.  

### Protips

1.Make the first sentence count.  Shocking statistic, bombastic claim, etc.  
2.use # for h2, ## for h3.  Mostly stick to h2s.  
3.Separate your sections with a ****.  It gives it a nice horizontal rule that segments the page.
