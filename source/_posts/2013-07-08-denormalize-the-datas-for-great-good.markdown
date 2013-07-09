---
author: John Connolly 
layout: post
title: "Denormalize the Datas for Great Good"
date: 2013-07-08 10:00 
categories: 
published: false
---
{% blockquote --Jodie Foster %}
Normal is not something to aspire to, it's something to get away from.
{% endblockquote %}

##Scout reads go slow

A few weeks ago, as we were about to launch our [iPhone app](http://app.appsflyer.com/id654867487?pid=TLC_organic), we discovered that one of its core features, Scout, frequently took seconds to render.  

<center>
{% imgcap small /images/denormalize-the-datas-for-great-good/scout-screenshot.png Scout %} 
</center>

For a little background as to what Scout is, at TheLadders one of our missions is to provide jobseekers information about jobs they’ll find nowhere else. Serving that mission is Scout, which in a nutshell allows jobseekers to view anonymized information about applicants who have applied to the job they are viewing. Salary, education, career history: we present a lot of useful information to jobseekers about their competition for any given job.

Over time, some attractive jobs accumulate on the order of 30 to 60 applicants, yielding response times of over 1 second (due to multiple synchronous requests, done serially, just to serve _one_ Scout view request).  In cases of higher load, sometimes request times well over that.

<center>
{% imgcap small /images/denormalize-the-datas-for-great-good/scout-screenshot-many-applies.png Scout view of a job with many applicants %} 
</center>

That brings Scout into unusably slow country, as the graphite chart below indicates:

<center>
{% imgcap medium /images/denormalize-the-datas-for-great-good/before-graphite.png 95th percentile of response times for Scout in seconds %}
</center>

The graph shows the time it takes to form a response to a view-job request issued by our iPhone app. It’s the 95th percentile, which means that 5% of requests had times of the lines in the graph or higher for any given date.  One in twenty requests took this long or longer. There are many lines because we have a horizontally scalable architecture, so there are many backend app nodes.

We managed to bring those seconds down to milliseconds, with about a 1000x decrease in times of high load.  Below I’ll describe the changes in our architecture that enabled us to make such a huge improvement.

-------------

##Architecture

In its initial implementation, Scout’s applicant information was gathered and assembled on the fly for each and every request. Driving the iPhone app, we have a backend app server, which is essentially just a number of RESTful endpoints against which our iPhone app issues requests.  Below is a quick rundown of the architecture before I trace a request through our architecture.

{%imgcap center medium /images/denormalize-the-datas-for-great-good/front-end-orchestration.png iPhone app talks to the backend app server %}

Below this backend server there are a number of RESTful entity servers with which the app server is interacting via HTTP. 

{%imgcap center medium /images/denormalize-the-datas-for-great-good/front-end-orchestration-entity.png Backend app server relies on entity servers %}

These entity servers in turn query each other and the canonical data store, in our case Clustrix, and that’s that.

{%imgcap center medium /images/denormalize-the-datas-for-great-good/front-end-orchestration-entity-clustrix.png Entity servers query the db %}

So when a user of our iPhone app taps on a job, a request is sent to the backend app server...

{%img center medium /images/denormalize-the-datas-for-great-good/mobile-orchestration-request.png iPhone app makes a request %}

...which then issues a request to our job application service for all job applications for that job. The response contains a number of links to the where those job applications may be retrieved.

{%img center medium /images/denormalize-the-datas-for-great-good/mobile-orchestration-service-request.png backend server queries the job application service for all applications to a job %}

The backend server iterates over those links, requesting the job applications themselves one at a time. Just as before, adhering to hypermedia design, the response contains a link to the jobseeker who applied to the job. For your sanity, I’ve simplified the response to contain only the job seeker link:

{%img center medium /images/denormalize-the-datas-for-great-good/mobile-orchestration-service-request2.png backend retrieves each application %}

Finally with that result set, the orchestration service then issues a number of requests to the job seeker service for information about the job seekers who have applied to the job being viewed.  In its initial implementation all of the requests were synchronous and in series as I mentioned earlier. We eventually parallelized them, as you can see in the graphite chart where the big spikes left diminish towards the right.  

{%img center medium /images/denormalize-the-datas-for-great-good/mobile-orchestration-service-request3.png backend retrieves each application %}

The iPhone app backend server then extracts the relevant information from those job seekers’ profiles, and returns them as a JSON array of applicants to the mobile app.

{%img center medium /images/denormalize-the-datas-for-great-good/mobile-orchestration-response.png backend retrieves each application %}

That is not just a lot of words and diagrams, that is a lot of work!  

The workflow includes multiple objects serializing and deserializing, HTTP transfers, hitting the canonical store etc. Why does each request need to assemble this data itself? Why bother hitting the database? Is there an alternative? It seems like a natural fit for a document-oriented database, as the data we are passing back to the client is just a JSON object containing an array of applicants.  We could stand a [Varnish cache](http://dev.theladders.com/2013/05/varnish-in-five-acts/) in front of the Scout endpoints on the orchestration service, but then we’d be trading freshness for speed. On the platform team we like to deliver data fast and fresh (and furious).

{%img center /images/denormalize-the-datas-for-great-good/tokyo-drift-o.gif how we roll at the Democratic Republic of Platformia %}

-----------
##Scout reads go fast

Principal Architect [Sean T Allen](http://twitter.com/SeanTAllen) set [Andy Turley](http://twitter.com/casio_juarez) and me to improving Scout’s performance. The architecture was surprisingly simple: stick the data in Couchbase and have the iPhone app backend query that instead. How would we keep this data up to date? The first step is to have the job application entity service emit a RabbitMQ event when it receives an application from a job seeker to a particular job (a PUT returning a 201).  On the other end of that message queue there is a  [Storm](http://dev.theladders.com/2013/03/riders-on-the-storm-take-a-long-holiday-let-your-children-play/) topology would be listening for that message. The RabbitMQ message would be the entry point into the spout. 


The message contains a link to the job seeker who applied to the job, as well as the ID for the job to which she applied.   The message isn’t actually encoded as JSON and transmitted over the wire, but for clarity I’ve displayed the RabbitMQ message as JSON.

{%img center /images/denormalize-the-datas-for-great-good/rabbitmq-storm.png RabbitMQ passes along a job-application message to a listening Storm topology %}

The second step, after having received the RabbitMQ message, fetches the job seeker profile from the jobseeker service, and passes that information to the next step.

{%img center /images/denormalize-the-datas-for-great-good/rabbitmq-storm-jobseeker.png The Storm topology extracts the job seeker link from the messages and retrieves information about the job seeker who just applied to the job. %}

This third step is responsible for persisting the applicant information to a Couchbase bucket. It uses the job ID as the key, and it does a create or update operation on the document corresponding to that key depending on whether there are applicants already in the bucket for that job. 

{%img center /images/denormalize-the-datas-for-great-good/rabbitmq-storm-couchbase.png The final step is that the topology persists the relevant job %}

That last diagram is a bit of a simplification. We had hoped that since Couchbase is not just a key-value store, but a key-document store, JSON-aware, that it would have a sophisticated append (put item at the back of the Array). Alas, we weren’t so fortunate and had to implement our own append operation by reading the document (if it exists), adding an item to a list if it’s not already there, and then writing the document.  So it’s more like two operations than one.

_Now_ when TheLadders mobile service gets a request for Scout information for a job, all it does is a lookup in Couchbase with that job ID and returns the applicants associated with that key. 

{%img center /images/denormalize-the-datas-for-great-good/mobile-orchestration-couchbase.png iPhone issues a request for Scout information, backend just retrieves it from couchbase %}

{%imgcap center /images/denormalize-the-datas-for-great-good/before-couchbase-after-no-lines.png 95th percentile response time for Scout data, before and after moving to the read view %}

Dramatically faster, even at the 95th percentile.

-----------

SOA is no panacea. There are many instances where querying a number of backend servers to assemble and aggregate data returned from a database simply doesn't make sense. In those cases, you may do well to denormalize that data and put it in a store that's more efficient for retrieval.  

If you find this post interesting, join the dicussion over on Hacker News. 
