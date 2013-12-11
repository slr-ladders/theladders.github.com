---
author: Kyri Sarantakos
layout: post
title: "A Brewing Storm"
date: 2013-12-11 10:31
comments: true
categories: 
published: true
---
{% blockquote --Toni Morrison %}
If there's a book that you want to read, but it hasn't been written yet, then you must write it
{% endblockquote %}
Once upon a time there was a script. Each morning it sent new jobs to our job seeking customers. It was simple and the data it operated on was relatively small.  As the months turned into years this script grew in complexity and the data grew in size.  And more scripts came to the party and they had data of their own and these new scripts beget data for other scripts, and this small group of scripts extracted and transformed, processed and prepared, working tirelessly every night.

Some worked alone while others fed each other, all growing increasingly more complex.  Occasionally at first and more frequently over time, the scripts started to interfere with each other by competing for resources or not finishing in time for a child script to consume it’s parents data, or worst of all, deadlocking for no apparent reason.  

Let’s bring some order we said and used cron to wrangle them at first, then moving to more complex “enterprise” scheduling systems to try and tame the beast, and keep the scripts from clobbering each other or grinding themselves to a crawl.

But the data grew and grew and with it came longer and longer run times.  At this same time our script was getting slower, our users’ expectations and our own ambitions grew.  Could we alert a job seeker the minute a new relevant job entered our system?  Could we alert an employer as soon as job seeker they were interested in updated their profile?

The network of interactions/activity/entities we wanted to grow, monitor and react to and then extract value from was exploding in complexity.  You can picture all of our job seekers, employers and jobs as nodes in a graph, and imagine our teams are furiously trying to connect them in new and interesting ways.  They are using machine learning to light up edges between these nodes, indicating which jobs a particular job seeker might be interested in and which job seekers an employer might like.  Or clustering these entities into similar groups.

Doing all of this between 12am and 6am was getting hard. Hadoop was an option, but processing speed alone wasn’t just the issue.  Some things we wanted to do had to be done in real time, not batch.  A user isn’t going to wait until the nightly run for us to calculate what jobs are appropriate for them.  In addtion, as TheLadders moves into mobile and speed becomes more and more a concern we want the Graph of our Ecosystem to be as current as possible not something that gets updated once a day.

There comes this thing. Storm. It fits into our infrastructure; working nicely with RabbitMQ and interop’ing well with our existing code base.  

However, Storm is young and fresh out of Twitter.  Getting it to work, quickly and reliably can be painful as can figuring out the best practices to manage it.  All of this took us some time and some hard lessons had to be learnt.  A lot of late nights and head scratching, time spent hanging out in irc channels, reading blog posts, watching conference talks and just plain ole trial and error and occassionally grabbing Nathan Marz when he was speaking to ask “How do we deal with X?” brought us to our current place. 

Today Storm runs most of the backend at TheLadders, keeping that graph of our ecosystem fresh so our experience teams can ship great new features to our customers.  And we hope you can find a use for Storm and maybe get there quicker than we did.  Manning publications reached out to us and I’m incredibly excited and very proud to announce that three of our top engineers, Sean Allen, Matt Jankowski and Peter Pathirana produced a book, Storm Applied, a book designed to help you leverage some of the hard earned knowledge we’ve acquired here at TheLadders. Storm Applied will be available in the [Manning Early Access Program](http://www.manning.com/about/meap) any day now.  We hope you find it useful and we look forward to your feedback on the book.
