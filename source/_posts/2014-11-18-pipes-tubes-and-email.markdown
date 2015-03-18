---
layout: post
title: "Pipes, Tubes, and Email"
slug: pipes-tubes-and-email
date: 2014-11-18 09:00
comments: true
categories: Email DevOps
published: true
---
{% blockquote --US Senator Ted Stevens (R-Alaska) %}
It's not a big truck.  It's a series of tubes.  And if you don't understand, those tubes can be filled and if they are filled, when you put your message in, it gets in line and it's going to be delayed.
{% endblockquote %}

## Plumbing 101

Sending email is a major part of our business.  Over the years, TheLadders has moved through several iterations of getting emails out to our millions of job seekers and recruiters.  We've both built in-house solutions and utilized [Email Service Providers (ESPs)](http://en.wikipedia.org/wiki/Email_service_provider_(marketing\)).

Recently, we transitioned onto a new ESP, [SendGrid](http://sendgrid.com).  SendGrid offers us the choice of handing off email via their [HTTP](https://sendgrid.com/docs/API_Reference/Web_API/index.html) or [SMTP](https://sendgrid.com/docs/API_Reference/SMTP_API/index.html) APIs.  We selected [SMTP](http://en.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol) as our transport mechanism because it allows us the luxury of inserting a layer in our infrastructure to handle queueing and resilience of mail transport before handing messages across to the ESP.  We are also able to achieve higher overall throughput with SMTP than would be possible with the HTTP API.  We're using [Postfix](http://www.postfix.org) as our mail transport agent because of its scalability properties, the flexibility of its configuration options and our team's familiarity with running and maintaining the application.

To ensure that our subscribers receive the emails we send them, we divide the different types of messages across multiple sub-user accounts at SendGrid.  This spreads our outbound email across different source IPs depending on the chosen sub-user account and allows us to control the reputation of each IP group.  In addition to the usual challenges that go along with deploying any new infrastructure -- monitor it, scale it, make it highly available -- SendGrid's use of SMTP authentication credentials to determine which sub-user account will handle the sending of a particular message created a new and interesting problem to solve.  How could we allow our application to instruct Postfix which sub-user account to use without building a Postfix cluster for each sub-user account?  Moreover, how could we make that process invisible to our end recipient?

## Don't Clog the Tubes!

The majority of our email traffic is created by various [Storm](/categories/storm/) topologies crunching through our data.  Storm provides the ability to parallelize each step in the process, resulting in fairly rapid generation of email traffic.  We utilize our F5 load balancers in front of a pool of Postfix servers to make our mail transport layer both fault-tolerant and scalable.  During our larger sends, we prefer messages to be sent out with minimal queueing.  We've found after tuning that we can sustain roughly 7000 messages per second through a single Postfix server before messages begin to queue.  We can easily scale out to additional Postfix servers behind the load balancer to increase our total throughput.

{%img center medium /images/pipes-tubes-and-email/animated_email_flow.gif %}

## Pick a Tube

Postfix provides the [SASL Password Map](http://www.postfix.org/postconf.5.html#smtp_sasl_password_maps) mechanism to look up SMTP credentials based on remote hostname or domain.  When coupled with [Sender-dependent Authentication](http://www.postfix.org/postconf.5.html#smtp_sender_dependent_authentication), that lookup can be performed based on the sender address.  We leveraged this combination of options along with [plus-sign subaddressing](http://tools.ietf.org/html/rfc5233#page-2) to encode the sub-user account in the message's source address, so an email from `user@example.com` would actually be sent from `user+account@example.com`.

We utilize a regular expression map for the password selection that matches the subaddress portion of the sender address and returns the appropriate sub-user account credentials to postfix, with a default for messages that come through without a subaddress.

``` plain SASL Password Map
/^.*\+user1@example.com$/   user1:password1
/^.*\+user2@example.com$/   user2:password2
/^.*$/                      defaultuser:defaultpassword
```

{%imgcap center medium /images/pipes-tubes-and-email/pick-a-tube.jpg [Photo](https://www.flickr.com/photos/biscuitsmlp/2431615179) by [smlp.co.uk](https://www.flickr.com/photos/biscuitsmlp/) / [CC BY 2.0](http://creativecommons.org/licenses/by/2.0/) %}

## Keep Your Tubes Straight

While our solution works great for allowing our applications to properly route messages to the correct sub-user account, it doesn't necessarily provide the best customer facing appearance.  Our customers don't care what ESP we use, how we perform our sub-user account selection, or which sub-user account sourced their email.  Furthermore, a sudden change in source email address could cause our messages to be filtered incorrectly on the recipient side.  Perhaps a customer has a filter in place to always drop our messages into a specific folder for them to read later.  Maybe they have a strict policy stating that only mail from known addresses will end up in their inbox.  We periodically have to adjust how our outbound email is processed and we have to make those changes as transparent as possible for our customers.  To that end, we are also utilizing Postfix's address rewriting capabilities to ensure that our email source addresses remain consistent.

Postfix provides several opportunities and methods to transform email envelope information [for a variety of purposes](http://www.postfix.org/ADDRESS_REWRITING_README.html).  Our requirement was to transform messages sent from `user+account@example.com` so that the customer sees the message sourced from `user@example.com`.  [Sender canonical maps](http://www.postfix.org/postconf.5.html#sender_canonical_maps) initially seemed like the ideal solution to this problem.  It worked perfectly to transform the sender address as desired however, the transformation occurred so early in the process that addresses were being rewritten before the subaccount selection was performed.  We finally settled on [SMTP generic maps](http://www.postfix.org/postconf.5.html#smtp_generic_maps) as the correct solution since it performs its transformation when mail leaves the machine via SMTP, after all other processing has taken place.  We again use a regular expression to strip the subaccount information from source addresses.

``` plain SMTP Generic Map
/^(.*)\+(.*)@(.*)$/ ${1}@${3}
```

{%imgcap center medium /images/pipes-tubes-and-email/the-internet.jpg [Photo](https://www.flickr.com/photos/wheresmysocks/205710716) by [Kendrick Erickson](https://www.flickr.com/photos/wheresmysocks/) / [CC BY 2.0](http://creativecommons.org/licenses/by/2.0/) %}

## Pipes or Tubes

Pulling it all together with the [recommended Postfix config](https://sendgrid.com/docs/Integrate/Mail_Servers/postfix.html) from SendGrid, results in `/etc/postfix/main.cf` containing:

``` plain main.cf
smtp_sasl_auth_enable = yes
smtp_sender_dependent_authentication = yes
smtp_sasl_password_maps = pcre:/path/to/sasl_password_map
smtp_generic_maps = pcre:/path/to/smtp_generic_map
smtp_sasl_security_options = noanonymous
smtp_tls_security_level = encrypt
header_size_limit = 4096000
```

Find this post interesting? Join the discussion over on [Hacker News](https://news.ycombinator.com/item?id=8623846).
