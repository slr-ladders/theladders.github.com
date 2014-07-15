---
author: Matt Chesler
layout: post
title: "Thunder and Lightning"
date: 2014-07-24 10:00
comments: true
categories: Storm DevOps
published: false
---
{% blockquote --Occam's Razor %}
The simplest of explanations is more likely to be correct than any other.
{% endblockquote %}

## Braving the Storm

At TheLadders, we operate a fully virtualized environment consisting of slightly less than a thousand virtual machines across our Development, QA, and Production environments.  We manage these systems with [Puppet](http://puppetlabs.com) and [Foreman](http://theforeman.org), which enables us to rapidly deploy new systems when necessary, as well as maintain our systems predictably throughout their lifecycles.

One of the tools we [rely on heavily](http://dev.theladders.com/categories/storm/) is [Storm](https://storm.incubator.apache.org), a distributed, real-time computation system.  Storm provides us with a framework that we use to constantly crunch data about the millions of job seekers and jobs in our environment.  This enables us to provide our job seekers with relevant information about the best jobs available to them at any given time.  When we build new Storm nodes, Puppet takes a very minimal OS install, lays down our standard configuration, then installs Storm, starts the Storm process and ensures it will start after reboot.

## Dark Skies Ahead

We operate several Storm clusters across QA and Production spanning Storm versions 0.8 and 0.9.  Over the past several months, we've experienced intermittent issues within the clusters where individual nodes stopped behaving properly.  The issues occur more frequently in our Production environment, which we attribute to the orders of magnitude higher volumes of traffic traversing Production.  We've also seen this particular issue in both our 0.8 and 0.9 clusters.  Until recently, the problem has occurred so infrequently that it was much quicker and easier to shut down and rebuild the problem nodes than invest significant time nailing down the root cause.

Last month, we rebuilt our 0.9 Production cluster from the ground up and immediately began seeing topologies fail to start on multiple workers.  The issue was clouded by the fact that we saw several different errors occurring, including too many files open, DNS resolution failures, Java class not found errors, heartbeat file not found, etc.

{%imgcap center medium /images/thunder-and-lightning/stormy-city.jpg [Photo](https://www.flickr.com/photos/29311691@N05/7653430352) by [H.L.I.T.](https://www.flickr.com/photos/29311691@N05/) / [CC BY 2.0](http://creativecommons.org/licenses/by/2.0/) %}

## When it Rains, it Pours

Since we were seeing multiple errors occurring without any obviously predictable pattern, we started the investigation by trying to reproduce or verify the individual errors on the nodes where we saw the issues in the Nimbus interface.  Despite complaints from Storm of DNS resolution issues, we were unable to find any issues with our DNS system or name resolution on any of the nodes in the cluster, even when performing many lookups in rapid succession.

After eliminating DNS as a root cause, we surmised that the real problem was limits on open file handles and that the other errors -- Java class not found, heartbeat file not found and DNS resolution failure -- were just different manifestations of the process’ inability to open a file handle or socket.  One change that Puppet makes to our systems is to increase the open file handle limits for the storm user/process from the default of 1024 to 256k.  We do this by setting the `nofile` option in `/etc/security/limits.conf`.  We verified on every host that the Storm user had properly set file handle limits.  Observing the workers when they were experiencing the issue proved difficult because Storm dynamically assigns workers to nodes at process startup and processes are not sticky.  This means that in our situation, where processes were starting and dying very quickly, it was extremely challenging to be logged into the host watching the process and gathering useful data in the few seconds between startup and death.  One approach to avoid this problem was to shut down workers to eliminate unused worker slots, thus limiting the potential destinations for new processes.  After a prolonged struggle with observing a process as it died, we were finally able to see that the worker process itself was limited to the default 1024 file handles.  We confirmed this suspicion by watching `/proc/<PID>/limits` to confirm that all Storm related processes were limited to 1024 open file handles on the affected hosts.

## Every Cloud has a Silver Lining

Now that we had observed a worker process with a 1024 open file handle limit, we moved on to determining how this could happen and why it seemed to occur only on certain nodes.  We noted that rebooting a host did not resolve the issue and further that rebooting a working node caused it to cease functioning properly.  After quite a bit of experimentation, we found that manually restarting the Storm supervisor on an affected host allowed the node to function properly again, at least until the next reboot.

We recently altered our new machine deployment to reboot the host between running Puppet and putting the machine in service.  Whereas previously the Storm supervisor would be started by Puppet and function normally, the supervisor is now being started by init on boot.

We ultimately determined that the root cause of this issue is that processes started by init don't go through pam, so limits set in `/etc/security/limits.conf`, which is utilized by `pam_limits.so`, are not applied to processes started on boot.

We chose to solve this issue by following the RHEL convention of configuration in /etc/sysconfig and modifying the storm supervisor init script to load `/etc/sysconfig/storm` if it exists.  Our `/etc/sysconfig/storm` contains a single line for the time being, increasing the `nofile` limit to 256k.  This method provides us with the flexibility to augment the configuration in the future with minimal impact.

Once Puppet deployed this change to our entire environment, we verified via `/proc/<PID>/limits` that the Storm supervisors had picked up the changes both when started by hand/Puppet and when started on boot.
