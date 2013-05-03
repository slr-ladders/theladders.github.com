---
author: Sean T Allen
comments: true
date: 2013-02-01 11:34:00
layout: post
slug: onboarding
title: The Catechism of Code
wordpress_id: 807
categories:
- How we work
---
{% blockquote --Horace %}
"Begin, be bold, and venture to be wise."
{% endblockquote %}


All things have a beginning, some cosmologists may disagree, but for our purposes we will assume the universe had a start. How things start sets the tone for how they will continue and ultimately how they will end. So it is with employment at TheLadders.

If you ask the most recent developers to join TheLadders, [@johnconnolly](http://twitter.com/johnconnolly) and [@casio_juarez](http://twitter.com/casio_juarez), they probably can point to more than a few bumps in the road. But learn, iterate, repeat. Starting today, we are introducing a new onboarding plan...


## **Day Zero**


Once the usual HR paperwork is out of the way, get this:


![15 inch retina macbook](/images/floating_flaming_retina_imac_15_inch.JPG)



Install your favorite IDE and tools and [make that MacBook your own](https://github.com/SeanTAllen/OS-X-Customizations).


## ****Day One****


We’ll start you off working on a modified version of the Thoughtworks "Object Calisthenics" exercise. You can find our version on [our github.](https://github.com/TheLadders/object-calisthenics)

Why? We've found that most programmers still have a very procedural mindset when it comes to code. They favor if statements over the use of polymorphic objects, tend towards code that spreads knowledge about domain objects across a wide range of classes (usually a wide range of controllers in most web apps)  and a variety of other potentially problematic tendencies. We originally did the Thoughtworks "Object Calisthenics" exercise as a team at TheLadders in September of 2012 to start a conversation about a variety of OO techniques that we rarely saw in our existing codebase. Each of the rules that the exercise lays down might seem silly in a production codebase, but they aren't meant as hard and fast rules during day to day work. They are meant to guide the exercise and force you into thinking about coding in a way that you perhaps haven't before. Things like:



	
  * favoring polymorphic objects over conditionals

	
  * observing the law of demeter

	
  * not overloading classes with multiple responsibilities


These rules are then applied to a kata that introduces new developers to a core part of TheLadders domain: applying to a job, and some of the key concepts: jobs, job seekers, recruiters, and resumes.

Each new developer spends their first day working through the exercise with an existing member of our team. Discussing why you might want to follow a particular rule in production code, why you might not. Pairing through blockages where how to continue without violating the rules of exercise aren't obvious. The overarching idea is to start a conversation about ideas that we think are valuable. The rules and the exercise are just a means to start that conversation in a concrete setting. I'm renowned in the office for getting very hand wavey while discussing complicated programming topics and having these conversation while working on code is much more effective.

So great, that's day 1, but we have a full 2 week onboarding so, what else do we do?


## **Days Two to Six**


Start watching the SOLID series videos from Clean Coders, doing [exercises we have designed around them](https://github.com/TheLadders/solid-exercises) and talking through the issues raised in the videos. Uncle Bob does an excellent job in the series of presenting engineering concepts in a way that firmly expresses that everything is a tradeoff. It has been said that "programmers know the value of everything and the tradeoffs of nothing". I've always taken that to mean that many programmers need black and white rules for what to do and what not to do and have a hard time understanding the tradeoffs involved with a particular practice or design. All best practices need to be broken sometime, all good design patterns eventually become bad ones when put in certain contexts. Uncle Bob's SOLID videos do an excellent job of both presenting the SOLID principles and discussing tradeoffs involved.

That's all well and good, but what does this really mean? Let's jump into Day 2 and walk through what we do.



	
  1. Start by watching "[Clean Code Episode 9: The Single Responsibility Principle](http://cleancoders.com/codecast/clean-code-episode-9/show)"

	
  2. Stop at key points during the episode to discuss salient points

	
  3. Talk more in general about the single responsibility principle, why you would want to apply it, etc. at the end

	
  4. Crack open some legacy Ladders' code that violates the single responsibility principle for a concrete example of the mess violating it can get you into

	
  5. Work together to refactor said code so that it no longer violates the single responsibility principle


Not bad for Day 2. Hands on exposure to some of hairy areas of our legacy codebase and a chance to talk about the values we hope everyone on the development team shares.


## **Day Seven and Beyond**


If you’re doing the math, you might notice that with 5 SOLID episodes that only gets us up to the end of Day 6 and two weeks is ten work days. What do we do with the other 4 days? Good question. We don't know. We'll never know because it will vary from person to person. We expect that over the course of the first six days, we'll see areas that we should address. Perhaps we will go back over some concepts from the object calisthenics exercise that were confusing or problematic. Perhaps a crash course on domain modeling. Perhaps an overview of how we want to use hypermedia to drive our RESTful services. Maybe they need more time with the SOLID exercises. The possibilities are endless and driven by the individual we are seeking to bring on board.

How have you been on-boarded at other companies?  We’d love to hear ideas for improving our own process, and don’t forget [we’re hiring](http://careers.theladders.com), so join TheLadders today and we will work hard to make your transition to our team as smooth as possible.
