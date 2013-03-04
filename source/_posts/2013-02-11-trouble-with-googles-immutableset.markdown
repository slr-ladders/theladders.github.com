---
author: Daniel Wislocki
comments: true
date: 2013-02-11 09:30:10
layout: post
published: false
slug: trouble-with-googles-immutableset
title: Trouble with Google's ImmutableSet
wordpress_id: 634
categories:
- Engineering
---

_Note: this post was originally published March, 19, 2012.  We're bringing it back from the dead because we felt it was just that good._

One feature we offer here at TheLadders is the ability for job seekers to "follow" recruiters, sort of how Twitter users can follow other Twitter users. Recruiters can then broadcast information, like announcements about new openings, &c., to their followers.

At start-up, as well as at set times during the night, caches are loaded that contain mappings between followable recruiters and the job seekers who follow them.
Recently we noticed that the time to create one of these caches was gradually increasing. There's a cache that maps recruiters to job seekers, called the "followers cache," which originally took a few minutes to build. We found that the time it was taking to build was steadily increasing over the course of just a few weeks to 30 minutes or more. This wasn't immediately apparent to us because the problem only manifested in production, and not in the day-to-day QA environment used by developers.

Below you can see the times taken to create the cache (in minutes) on four different nodes:

<!-- more -->

[{% img center /images/cache-creation-slowdown1.png 300 171 Cache creation slowdown chart  %}](/images/cache-creation-slowdown1.png)

You'll notice the jump on 1/16 from a gradual increase to a more rapid increase. That day a new release went out that included an increase in the size of a related cache- one that contains all job seekers who have permission to follow recruiters. Intersections of that cache with another are then used to build the followers cache.

At first we thought that the slowdown was a function of the increased cache size. Maybe pulling more data from the database to fill up the larger cache was the culprit. But from the logs we found that wasn't the case. In fact, we found that CPU usage was spiking to 100% while the cache was being built. This was in contrast to the QA machines, where CPU did not spike at all during the process. Further analysis determined the code was spending the vast majority of its time calculating the intersections of caches to produce the followers cache. The code is something along these lines:

``` java 
for (int recruiterId : followersForRecruitersCache.keySet())
{
  Set s = Sets.intersection(followersForRecruitersCache.get(recruiterId),
  canFollowRecruitersCache);
  followersCache.put(recruiterId, new HashSet(s));
}
```

(The method Set.intersection() is from Google Collections.) So was the problem that we had so much more data in production than in our QA environment, and many more iterations were being spent calculating set intersections? We also found another interesting bit of information. The following code, used to build the canFollowRecruitersCache, a simple set of integer IDs, was also taking longer in production than in QA:

``` java
ImmutableSet.Builder builder = ImmutableSet.builder();
for (Integer id : userPrivilegeSystem.getAllJobseekersWhoCanFollowRecruiters())
{
  builder.add(id);
}
canFollowRecruitersCache = builder.build();
```

Actually, all the slowness was in the call to ImmutableSet.Builder.build(), also from Google Collections. In fact, we have a larger canFollowRecruitersCache in QA than in production due to the amount of test data in the QA database. So the problem must be in the data itself and its interaction with ImmutableSet. (For the source code for the ImmutableSet, see [http://code.google.com/p/google-collections/source/browse/trunk/src/com/google/common/collect/ImmutableSet.java](http://code.google.com/p/google-collections/source/browse/trunk/src/com/google/common/collect/ImmutableSet.java).)

Taking a closer look, the distribution of IDs in canFollowRecruitersCache in QA looks like this (X-axis is the array index, Y-axis is the ID):

[{% img center /images/canFollowRecruitersCache-ID-distribution-in-QA.png 300 176 "canFollowRecruitersCache ID Distribution in QA" %}](/images/canFollowRecruitersCache-ID-distribution-in-QA.png)

The standard deviation of this set of IDs is 12,266,077.

The distribution of IDs in canFollowRecruitersCache in production looks like this:

[{% img center /images/canFollowRecruitersCache-ID-distribution-in-production.png 300 173 "canFollowRecruiterCache ID distribution in production" %}](/images/canFollowRecruitersCache-ID-distribution-in-production.png)

The standard deviation of this set of IDs is 642,039.

Opening up the code in ImmutableSet, we find that it uses a linear array of buckets, and when a collision occurs it probes each bucket until it finds an empty one, and puts the element there. It uses a secondary hash function, called smear(), to index into the array. Presumably this is used to augment whatever hash is already supplied by the element to be inserted. Unfortunately this isn't enough to overcome the distribution of IDs in our production data. Since Java a Integer's hash code is just its value, the efficiency of the ImmutableSet ends up being subject to the distribution of the IDs. The number of collisions that occur with production data when building the set is a huge 3,217,789,124, but with our somewhat larger QA dataset, only 3,199,502. If we read in the same production data as Strings instead of Integers, however, the number of collisions drops dramatically, and production performance is equivalent to QA's.

Both our QA and production data cause the same size of array of buckets of 1,048,576 to be used internally by ImmutableSet. Rendering this array into a 1024 x 1024 square, and color-coding by number of collisions at that index, we can have a better idea of what's happening.

The colors in the graphics below have the following meaning:

<table style="border:1px solid black;border-collapse:collapse;margin:auto;">
  <tbody>
    <tr>
      <th style="border:2px solid black;padding:10px;">collision count</th>
      <th style="border:2px solid black;padding:10px;text-align:right">color</th>
    </tr>
    <tr>  
      <td style="border:1px solid black;padding:10px;">0 (no element)</td>
      <td style="border:1px solid black;padding:10px;text-align:right">white</td>
    </tr>
    <tr>
      <td style="border:1px solid black;padding:10px;">0 (has element)</td>
      <td style="border:1px solid black;padding:10px;text-align:right">black</td>
    </tr>
    <tr>
      <td style="border:1px solid black;padding:10px;">&lt; 10</td>
      <td style="border:1px solid black;padding:10px;text-align:right">magenta</td>
    </tr>
    <tr>
      <td style="border:1px solid black;padding:10px;">&lt; 100</td>
      <td style="border:1px solid black;padding:10px;text-align:right">blue</td>
    </tr>
    <tr>
      <td style="border:1px solid black;padding:10px;">&lt; 1000</td>
      <td style="border:1px solid black;padding:10px;text-align:right">green</td>
    </tr>
    <tr>
      <td style="border:1px solid black;padding:10px;">&lt; 10000</td>
      <td style="border:1px solid black;padding:10px;text-align:right">green</td>
    </tr>
    <tr>
      <td style="border:1px solid black;padding:10px;">&lt; 25000</td>
      <td style="border:1px solid black;padding:10px;text-align:right">orange</td>
    </tr>
    <tr>
      <td style="border:1px solid black;padding:10px;">25000+</td>
      <td style="border:1px solid black;padding:10px;text-align:right">red</td>
    </tr>
  </tbody>
</table>

Thus the array produced for QA data looks like this:

[{% img center /images/ImmutableSet-collisions-in-QA.png 300 300 "ImmutableSet collisions in QA" %}](/images/ImmutableSet-collisions-in-QA.png)

Whereas the array produced for production data looks like this:

[{% img center /images/ImmutableSet-collisions-in-production.png 300 300 "ImmutableSet collisions in production" %}](/images/ImmutableSet-collisions-in-production.png)


The same algorithm is used to implement the set's contains() method, so operations such as intersections are also extremely slow with this data. A simple change to Java's built-in HashSet fixes the problem.



