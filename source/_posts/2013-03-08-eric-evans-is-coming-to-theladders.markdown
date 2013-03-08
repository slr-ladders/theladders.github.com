---
author: Daniel Wislocki
layout: post
title: "Eric Evans Is Coming to TheLadders"
date: 2013-03-08 10:09
comments: true
categories: [DDD, Legacy]
published: true 
---
{% blockquote --Johnny Cash %}
... when the Man comes around.
{% endblockquote %}

We are happy to announce that on April 10th, TheLadders will be hosting
[Eric Evans](http://domainlanguage.com/about/), the codifier of
[Domain Driven Design](http://domainlanguage.com/ddd/), for the New
York City DDD Meetup group. Engineers at TheLadders have long been
following developments in the DDD community. [Some](/ourteam/kyrisarantakos/) of
[us](/ourteam/danielwislocki/) have already attended the DDD immersion course,
[more](/ourteam/kylewinter/) of [us](/ourteam/mattjankowski/) will be attending it shortly, and
our developers are regular participants in the [NYC DDD Meetup](http://www.dddnyc.org/).

For those of you who might be unfamiliar with DDD, its goal is the
design of software that creates business value. DDD guides technical
and domain experts to collaboratively create a mental model of the
central business concepts. This model is then used to drive
design. This sounds like common sense: developers work with people who
know about the business to make software that works to solve its
problems. What could be more straightforward?  And yet, the complexity
inherent in the business world and software engineering make it
difficult to create software that is supple and adaptable to changing
needs. DDD provides a framework for thinking about, creating, and
communicating mental models. And that requires the learning of new
skills and ideas. It isn’t an easy process, but we have found that it
is rewarding for both the business and developers.

# A Little of Our Experience with DDD

While creating our new website, we’ve tried to remain focused on
“communicating mental models”. One way this can be done is through
DDD’s “Intention-Revealing Interfaces”: interfaces that clearly
communicate the contract between the domain model and its
users. Judging from the vast amount of code out there, this simple
idea is counterintuitive. Our own legacy codebase is no exception. For
example:

``` java
public class Subscription
{
  ...
  
  public AutoRenewFlags getAutoRenewFlag()
  {
    return autoRenewFlag;
  }

  public void setAutoRenewFlag(AutoRenewFlags autoRenewFlag)
  {
    this.autoRenewFlag = autoRenewFlag;
  }

  public int getUnsubscribeReason()
  {
    return unsubscribeReason;
  }

  public void setUnsubscribeReason(int unsubscribeReason)
  {
    this.unsubscribeReason = unsubscribeReason;
  }
}
```

This is an example of what in DDD is called an “anemic domain
model”. The Subscription class is a key part of the domain, yet not
only does it communicate nothing to the user about its usage, it in
fact does nothing. Values can be retrieved and set, but what then? How
do I actually unsubscribe someone? What prevents me from using any
arbitrary integer for the “unsubscribe reason”? What about changing
auto-renewal to null? There is no explicit contract here, and the user
of this object is given no guidance or constraints. By contrast, we’ve
worked hard in our newer code to avoid creating anemic domain models
and instead create objects that are not only useful, but clear in
their usage. Here is another example, this time from the new
Subscription class:

``` java
public abstract class Subscription
{
   ...
 
   public abstract Subscription withAutoRenewOn();

   public abstract Subscription withAutoRenewOff();

   public abstract CanceledSubscription unsubscribe(UnsubscribeReason unsubscribeReason);
}
```

In this case we’ve attempted to make the contract clear. Calling the
unsubscribe method actually unsubscribes the customer, returning a
CanceledSubscription. The “unsubscribe reason” is now strongly typed,
clearly communicating which values are allowed. Auto-renewal changes
yield a new immutable Subscription object, and can be chained together
with other "with*" methods to produce new subscriptions with appropriate
settings.

Another example of an anemic domain model, lacking an
intention-revealing interface, comes from the old Payment class in our
legacy codebase:

``` java
public Payment(int paymentId,
               int paymentActionType,
               BigDecimal amount,
               String approvalCode,
               String transactionReference,
               int creditCardId)
{
  this.paymentId = paymentId;
  this.paymentActionType = paymentActionType;
  this.amount = amount;
  this.approvalCode = approvalCode;
  this.creditCardId = creditCardId;
  this.transactionReference = transactionReference;
}
```

This class contains only the constructor you see here, and getters for
each of the fields created. It turns out that it’s used as a parameter
object, and nothing more. There’s no guidance as to it’s valid
construction, and no hint about its usage. Yet obviously handling
subscription payments is an important part of the subscription domain,
and we want the contracts around the model of that domain clear and
easy to understand. Here’s our attempt at accomplishing those goals in
the new codebase:

``` java
public Payment(PaymentAmount paymentAmount,
               JobseekerId jobseekerId,
               PaymentActionType paymentActionType,
               ReportGroup reportGroup)
```

The first difference is actually one that’s not visible from the code
itself. As we’ve developed the new site, we’ve agreed that all
arguments to methods or constructors are required; no passing of
nulls. If an argument is truly optional, a separate method or
constructor is added that excludes it. We want our code to be
confident, and this contract means that methods and constructors “say
what they mean and mean what they say”. In the legacy codebase, nulls
were passed liberally to and fro, and you could never be quite sure
which arguments were truly required.

Another change is the promotion of this class from a mere parameter
object to an active participant in the domain model:

``` java
public Receipt makeWith(PaymentMethod method)
{
  method.make(this);
  return new Receipt(paymentAmount.asAmountPaid());
}

public void recordWith(PaymentRecorder paymentRecorder)
{
  paymentRecorder.record(paymentAmount);
}
```

Instead of being passed around to “manager” objects and DAOs, a
Payment object can actually make a payment and create records of
itself. It seems only natural.

There’s much more qto Domain Driven Design than I’ve shown here --
this post barely scratches the surface. And as a team we know we still
have much farther to go in its mastery, but the time we’ve spent in
study and practice have been well worth the effort so far.

[We hope you’ll join us April 10th](http://www.dddnyc.org/events/80390502/) for an illuminating evening of
presentation and discussion.

