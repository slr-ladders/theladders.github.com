---
author: Jon Ruttenberg
layout: post
title: "Monitoring RabbitMQ at TheLadders"
date: 2014-07-15 10:24
categories: RabbitMQ
published: true
---
{% blockquote --Lewis Carroll, Alice in Wonderland %}
Alice:        “How long is forever?”

White Rabbit:     “Sometimes, just one second."
{% endblockquote %}

*Motivation*
------------
TheLadders makes heavy use of [RabbitMQ](http://www.rabbitmq.com) in its operations. RabbitMQ is a messaging broker that we use to connect our applications. Sending and receiving are separate, so the messaging is asynchronous. The asynchronous messaging decouples one application from another. We use RabbitMQ to publish events to multiple subscribers and to queue up work.

 - In some cases, events in our systems are ad hoc, driven by the various activities of our users. Examples of such events include the addition of a job seeker or a job to the system. These events are realized as RabbitMQ messages posted to exchanges. Systems interested in these events read them from queues bound to the exchanges.
 - In other cases, a scheduled process posts RabbitMQ messages to an exchange so that a specific system (say, a [Storm](https://storm.incubator.apache.org) topology) can process them. An example of this is a system that calculates matches between jobs and job seekers and puts those matches on a queue. A Storm topology reads those matches from the queue and transforms them into emails to be sent by an external email service.

In the first scenario above, we are mostly interested in making sure that the queue of ad hoc events has not grown too large, which would indicate a problem with the system that is consuming the messages.

In the second scenario, we want to be sure that messages are being published to the queue at a suitable rate, and that the topology that consumes the messages is processing them quickly enough to get the emails out by a particular time.

We did not find a suitable ready-to-use solution for this need. As you will see below, we eventually arrived at a solution that combined a [Clojure](http://clojure.org/) library for accessing RabbitMQ queue metrics with a [Riemann](http://riemann.io) server to process events produced by the library.

*First Attempts*
-------------------
Our first attempts at a monitoring solution revolved around an assortment of shell scripts that made HTTP requests to the RabbitMQ Management API to discover the lengths of important queues at particular times. If certain thresholds were crossed, alerts were sent to on-call personnel. This approach had a number of drawbacks:

 - Brittleness: The times of the Management API queries were controlled by when the script was run by *cron*. The queue length thresholds were often dependent on the sizes of the datasets involved and the speed of the systems which published messages or read them from the queues.
 - Measuring Queue Lengths at a Single Point in Time: Checking the queue length at a particular point in time could not provide the information necessary to answer questions such as "When will this queue be drained?" and "Are messages being placed on the queue at a rate sufficient to meet a particular processing schedule?"


 
 
*How We Solved the Problem*
---------------------------
We created a [Clojure](http://clojure.org/) library called [monitor-rabbitmq](https://github.com/TheLadders/monitor-rabbitmq), available on **GitHub**.
It gathers statistics on RabbitMQ queues and nodes, and packages them as [Riemann](http://riemann.io) events. *monitor-rabbitmq* takes care of acquiring RabbitMQ statistics from the RabbitMQ cluster, using the RabbitMQ’s HTTP based [Management API](http://hg.rabbitmq.com/rabbitmq-management/raw-file/rabbitmq_v3_3_4/priv/www/api/index.html). *Riemann* takes care of aggregating the events and performing the calculations necessary to determine whether an alert should be triggered.


----------


*A Bit More Detail*

**What’s the data flow?**

{% img center /images/monitor-rabbitmq2.png 'Data Flow graphic' %}

**What queue data does** *monitor-rabbitmq* **gather?** [all rates are messages per second]

 - Queue Length: number of messages on the queue
 - Ack rate: messages acknowledged by the client
 - Deliver rate: notifications to the client that there is a message
 - Deliver-get rate: combination of deliver and get rates
 - Deliver-no-ack rate: notifications to the client that there is a message which does not require acknowledgement
 - Get rate: messages synchronously requested by client
 - Get-no-ack rate: messages sent to client with no acknowledgement required
 - Publish rate: messages published to the queue
 - Redeliver rate: messages redelivered to the client after being delivered and not acked

**What node data does** *monitor-rabbitmq* **gather?**

 - fd_used: file descriptors used
 - fd_total: file descriptors total
 - sockets_used
 - sockets_total
 - mem_used
 - mem_limit
 - mem_alarm: memory high water mark alarm
 - disk_free
 - disk_free_limit
 - disk_free_alarm: disk free low water mark alarm
 - proc_used
 - proc_total


 
**What does each** *Riemann* **event look like?**
Here is the Clojure representation (a map):
```clj
{:time 1390593087006,
    :host "our-rabbitmq.super.awesome.queue", 
    :service "publish.rate",
    :metric 0.0,
    :state "ok",
    :tags ["rabbitmq"]}
```
This event, created by the Clojure library, includes a *:host* member which is formed by taking a *rmq-display-name* argument (“our-rabbitmq”) and composing it with the queue (or node) name: “super.awesome.queue”
 
*An Example*
------------
Let's say that we have a queue which is read by a Storm topology. That queue contains messages which hold matches between jobs and job seekers. The topology must process the messages so that emails notifying job seekers of these job opportunities are composed and sent to an external email service. We want to be alerted if the messages are being consumed from the queue at a rate such that the queue will not be cleared by a certain deadline, say 9:00 AM.

We create a simple Clojure application that calls the *send-nodes-stats-to-riemann* function of our library and then exits. We call this application once a minute. Each call results in a full set of queue statistics being sent to our Riemann server.

Meanwhile, on the Riemann side of things, Riemann has been configured to watch the Ack rate of our queue. Riemann accumulates events over a time interval, smoothing out minor variations in the Ack rate, and calculates a projected time for the queue to be emptied. If the Ack rate dips below a certain threshold, it triggers an alert using, in our environment, the [Icinga](https://www.icinga.org) monitoring system.

*Wrapping Up*
-------------

With *monitor-rabbitmq*, we supply a regular flow of events to our *Riemann* server containing data about our RabbitMQ queues and nodes. By choosing a good base set of statistics to request from the RabbitMQ Management API, a change to our monitoring and alerting requirements usually results in only a change to our *Riemann* configuration.


Find this useful? Join the discussion at [Hacker News](https://news.ycombinator.com/item?id=8036593).
