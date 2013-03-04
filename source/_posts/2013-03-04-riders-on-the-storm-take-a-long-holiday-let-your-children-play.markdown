---
author: Matt Jankowski
layout: post
title: "Riders on the Storm: Take a long holiday, Let your children play"
date: 2013-03-04 13:52
comments: true
categories: Storm
published: true
---
{% img center /images/lightning_storm.gif 'Lightning Storm' %}

{% blockquote --Charles Dickens %}
It was the age of wisdom, it was the age of foolishness
{% endblockquote %}
****
# Introduction

I’ve decided to split this blog post up into three different sections as we have gone through three different phases with our usage of Storm.  The first describes how we used to use Storm at TheLadders.  This is followed by our “wake up call”, forcing us to the realization that how we had been using Storm was not sufficient.  The “wake up call” has led us to our current state of how we now use Storm at TheLadders. But first for those of you who aren’t familiar with Storm, a quick explanation straight from the horse’s mouth:

{% blockquote Nathan Marz https://github.com/nathanmarz/storm storm readme %}
Storm is a distributed real-time computation system. Similar to how Hadoop provides a set of general primitives for doing batch processing, Storm provides a set of general primitives for doing real-time computation. Storm is simple, can be used with any programming language, is used by many companies, and is a lot of fun to use!
{% endblockquote %}
****
# The Past

We were early users of Storm, starting out with the Storm 0.5.x releases and later upgrading to 0.6.2.  Our Storm cluster was very basic: Nimbus, Zookeeper with 2 Worker nodes;   5 topologies deployed, but only 3 of them really being exercised.  Many of these topologies were for non-critical portions of our application, as such we weren’t paying much attention to the cluster. The topologies we wrote had well-tested individual components; each of the Spouts and Bolts were written with testability in mind.  However we struggled when it came to end-to-end tests for an entire topology.

Other areas of our Storm related pain were:

* Very limited visibility into the overall health of the Storm cluster.  We lacked any monitoring and had very few metrics regarding our cluster.  We relied a lot on tailing the logs of the worker nodes to see how things were behaving.
* We naively configured the topology resources, not really being aware of what resources were being used across the worker nodes.
* A majority of our topologies used RabbitMQ as the entry-point and we had a very basic AMQP Spout implementation.  In fact, the initial AMQP Spout increased CPU usage on our RabbitMQ nodes from 4-10% to 40-45% with very little message throughput.
* Guaranteed message processing was not always enforced (more due to lack of knowledge on the subject than anything).

That list looks bad and one might wonder how we got along at all given those shortcomings.  To be honest, everything just “worked”, which was all we needed at that point.  The combination of Nimbus and Zookeeper did a great job of re-deploying topologies anytime “something” happened.  While we would occasionally open up the Storm web admin to see how things were doing, we really didn’t pay much attention to it; everything just worked.  Even the increase in RabbitMQ CPU usage was not considered overly serious because everything continued to work and was fairly stable.  This behavior continued for about a year or so.
****
# The "Wake Up Call"

Then came the day when we needed to deploy a new feature in one of our topologies.  We ran the standard release script to deploy a topology through Nimbus, and … nothing…  After some digging, we found that Nimbus had run out of disk space and our topologies had not been pulling messages off of RabbitMQ for an estimated 3 – 7 days.  

In addition, shortly after this initial wake up call, we had some one-off topologies that needed to be run for a 24-hour period.  These topologies required a decent number of resources.  They quickly starved the existing topologies of resources and did a good job of bringing Storm to a screeching halt.  It was like watching a caged death match between all of our topologies that left everyone unconscious on the mat.

If something like the 7-10 day outage can go unnoticed for so long, and if we could starve topologies at the drop of a hat, how could we expect to successfully expand our usage of Storm to more critical portions of the application?

We needed to change, and fast!
****
# The Present

We immediately started figuring out what we didn’t know about Storm and which bits were the most important for immediate success.  Some members of the development team got together with our operations team and worked out monitoring of cluster components. While Operations beefed up what they could, the development team:

* Enforced guaranteed message processing in all of our topologies.  This has mainly been done through the use of the BaseBasicBolt, which provides emitting anchored tuples and acking for free. [(http://nathanmarz.github.com/storm/doc/backtype/storm/topology/base/BaseBasicBolt.html)](http://nathanmarz.github.com/storm/doc/backtype/storm/topology/base/BaseBasicBolt.html)
* Refactored our AMQP Spout implementation to subscribe to a queue instead of using individual “gets”.  This has resulted in pre-Storm 0.6.2 levels of CPU usage on our RabbitMQ nodes (below 10% again).
* Added an additional three worker nodes with more memory and CPU so we don’t have to constantly worry about resource starvation (although this should always be something to consider really).
* Improved our unit testing of configured topologies using the simulated time cluster testing feature in Storm 0.8.1  [(https://github.com/xumingming/storm-lib/blob/master/src/jvm/storm/TestingApiDemo.java)](https://github.com/xumingming/storm-lib/blob/master/src/jvm/storm/TestingApiDemo.java):
****
# The Future
Okay, so I lied.  There is a fourth phase: the future; where we plan to go with Storm. 

We plan on upgrading to Storm 0.8.2 very soon.  It has a much-improved web admin that allows for deployment and rebalancing of topologies on the fly.  We hope this simplifies the process of deploying and rebalancing (if needed) of our topologies.

Upgrade to Storm 0.9.x as soon as possible once released.  We hear good things about this release; mainly the metric collecting which will be a huge win in terms of improving visibility into the streams and flow of tuples between Spouts and Bolts.

Finally, we are plan on expanding our topologies to be more than simple queue-to-spout designs.  We are experimenting with using Storm for scheduled batch processes, hoping to have something in production within the next week.

Hopefully this blog gave you a nice overview of how Storm can be used by a company.  I think one of the take-aways can be how easy Storm is to use.  Storm served us for over a year with very little intervention and minimal knowledge on our part; I believe this speaks volumes of Storm’s ease-of-use and reliability.

Stay tuned for some more detailed technical blogs on some of the things we did to improve our Storm usage. 

Join the discussion over at [reddit](http://www.reddit.com/r/programming/comments/19noko/how_we_use_twitters_storm_part_one/).
