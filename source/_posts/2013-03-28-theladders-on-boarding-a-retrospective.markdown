---
author: Thomas Symborski 
layout: post
title: "TheLadders Onboarding: A Retrospective"
date: 2013-03-28 12:00
comments: true
categories: How we work
published: true
---

{% blockquote --Johann Wolfgang von Goethe %}
Whatever you do or dream you can do – begin it. Boldness has genius and power and magic in it.
{% endblockquote %}

{% img center /images/dilbert-onboarding.gif 'Onboarding' %}

Just before joining TheLadders, I read a post on their dev blog detailing a new onboarding process for incoming engineers. I was very interested in what I'd soon learn about its execution. If you've not had the chance to read through this post, you can find it [here](http://dev.theladders.com/2013/02/onboarding/).

The onboarding process could be broken into two main sections. The first started when we were given a few user stories and were asked to build a corresponding system while following some fairly restrictive [guidelines](https://github.com/TheLadders/object-calisthenics#the-rules). These restrictions challenged us to reevaluate our normal architecting techniques and develop less-than-obvious solutions to this problem. The rules allowed us to implement our solution in the language of our own choosing, and I chose Ruby. The chance to showcase my skills for the first time at a new company excited me.

The second section spanned the next eight days. We dove into Robert Martin’s SOLID principles video series. After watching, learning, and discussing each one of the the five principles, we proceeded to work on code with real-world [examples](https://github.com/TheLadders/solid-exercises) of principle violations. Between these videos and exercises, we met with established engineers at TheLadders to discuss the subject matter and our own philosophies on software craftsmanship.

This was the first time I'd ever had a formal onboarding. I've worked for agencies and other product companies, both larger and smaller, before joining TheLadders. This was brand new. I'd encourage every software company to seriously consider a process like this for their new engineers. Why? Here are a few reasons:

* I was allowed access to the top engineers in the company, learning not only about the way software was written at the TheLadders but also where and how the team was looking to grow. 
* I was able to get a strong feeling for the culture and technologies used as well as prevailing opinions on languages, practices and history. This was also a great opportunity for engineers at TheLadders to learn more about me and get a good picture of my experience and viewpoints. 
* It also served as a vacation from production code, deadlines and the stress of the everyday that we encounter wherever we go. We were encouraged to stretch our solutions and see where they took us.

You may have heard of Rich Hickey’s [Hammock Driven Development](http://blip.tv/clojure/hammock-driven-development-4475586), the idea that spending time away from your code produces unexpected benefits. IN the same vein, I'll call what we did for these two weeks Garbage Driven Development. What do I mean when I say garbage? The code written while practicing GDD is never going into production. It’ll never really do anything beyond providing a learning experience and proving a point you’d like to make. You don’t feel pressure to make sure the code fits within a particular context, that it’s easily readable by others, or that it’ll be maintainable going forward. In the end, the code may be quite eloquent or look like garbage, but it doesn't really matter. Try that idea you’ve always thought about but never had time to implement. Buck best practices to see if you can find better ones. When you’re done, it’s garbage. Developers would be well served to routinely make time to focus less on product and more on process.

Most of all, this process woke me up from the monotony of just pushing out code and inspired me to learn and pursue more of my own side projects. I've wanted to read more, explore new languages, and try new ways of doing things. It was an excellent way to frame the start of a new chapter in my life as an engineer.
