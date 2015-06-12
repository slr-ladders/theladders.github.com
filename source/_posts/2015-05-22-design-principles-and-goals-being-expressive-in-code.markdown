---
author: Kyle Winter
layout: post
title: "Design Principles and Goals (Part 3) - Being Expressive in Code"
date: 2015-05-22 12:26
comments: true
categories: 
published: true
---

{% blockquote -- Michael Feathers %}
Clean code always looks like it was written by someone who cares
{% endblockquote %}

Welcome back to the last post in our series on our design goals and principles.  We've talked about our [High Level Architecture](/2015/05/design-principles-and-goals-high-level-architecture) and [Our Trip Back to OO](/2015/05/design-principles-and-goals-a-trip-back-to-oo), and now we're going to dig into how we write and compose our code, and how we try to be expressive in what our code says.


# Don’t write code, write sentences that tell a story
You should have to think hard to write code, not read it.  One of the things we focus on a lot is how the code reads.  Is the code full of programmer terms like ‘build’ and ‘create’ or does it read like a fluent paragraph?  Some might consider it a small detail and fluffy, but it can directly impact how maintainable code is.  A lot of times we write code in ways that only programmers understand, and while we speak the language, it can still add a small mental overhead that really isn’t needed. 
 
JavaBeans is great as a naming convention if you’re relying on reflective frameworks to read properties out of data structures, but inappropriate for true domain models.
 
Even the small things – this isn’t a direct example, but similar to what we run into a lot.  Why do we have to write:

```java
return buildJobseeker(premiumSubscription.getStatus());
```
When you read it out loud, you get “return build Jobseeker premium Subscription get status.”  Huh?  Why can’t we write:
```java
return jobseekerWith(premiumSubscription.status());
```
When you read that out loud, you get “return Jobseeker with premium Subscription status.”  Makes a little more sense – and anyone, developer or not, should be able to understand it just by reading words.

We do this sort of thing on both a small and large scale - we name things for their calling context and intent.  We might rename something just so it reads better in the code that is calling it.  It’s important to note that we’re talking about our end application - code that one project owns and consumes - so we can make assumptions about how the code will be called and see it easily.  The same ideas don’t necessarily apply to things like reusable libraries.

Some other examples from our code:
```java
currentUser.refer(someoneElse).forThe(post);
user.like(job);
user.unlike(job);
jobseeker.print(paymentHistory.includingOnly(selectedPaymentIds)).to(outputStream, asPdf);
```

# Separating mechanics from meaning
There are a lot of times we have to do things that are “mechanical” that don’t really have any inherent meaning to the task at hand, but are really just supporting code.  Things like constructing specific Date instances, interfacing with other library/framework components, or looping over collections.  This supporting code serves a purpose, but lacing it within the more expressive code of business logic only serves as clutter.  Separating mechanical code from business code leaves the important code cleaner and simpler, highlighting what’s really happening.
 
A real world example for retrieving the jobs that a Jobseeker has applied to:

Old Code:
```java
public Iterable<JobRepresentation> getAppliedJobsFor(final Jobseeker jobseeker)
{
  Iterable<ProcessedApplication> applications = jobApplicationSystem.getApplicationsFor(jobseeker);

  // Filter to only include succeeded applications
  Iterable<ProcessedApplication> succeededApplications = Iterables.filter(applications, new Predicate<ProcessedApplication>()
  {
        @Override
        public boolean apply(@Nullable ProcessedApplication application)
        {
          return application.succeeded();
        }
  });
	
  return Iterables.transform(succeededApplications, new Function<ProcessedApplication, JobRepresentation>()
      {
        @Override
        public JobRepresentation apply(@Nullable ProcessedApplication application)
        {
          return get(application.getJobLocationId(), jobseeker);
        }
   });
}
 
public Iterable<JobRepresentation> get(Iterable<JobLocationId> ids,
                                      Jobseeker jobseeker)
{
  return repository.getJobsFor(ids).toRepresentationsFor(jobseeker);
}
```
In 5 seconds – can you tell me what’s going on?  Probably not – there are a lot of mechanics clouding the way.  We have some meaningful things buried in anonymous functions and a lot of lines that are just compiler syntax.  We make a pretty liberal use of Google’s Guava library to implement functions and transforms, but when left to roam free in our application code they can wreak havoc.  With a few small changes: the addition of a ProcessedApplications wrapper class and a class just to create our Guava transform from ProcessedApplication to Job, we can make our high level application code much more expressive.
 
What we ended up with:
```java
public Iterable<JobRepresentation> getAppliedJobsFor(Jobseeker jobseeker)
{
   ProcessedApplications applications = jobApplicationSystem.getApplicationsFor(jobseeker);
   return applications.thatAreSuccessful().transformed(toJobs()).toRepresentationsFor(jobseeker);
}
 
private Function<ProcessedApplications, Jobs> toJobs()
{
   return processedApplicationsToJobs.toJobs();
}
```
Now all the mechanics of looping over applications and creating Guava functions are hidden away in lower components, and we’re left with the quick makings of a sentence, “Return applications that are successful, transformed to jobs, to representations for the jobseeker.”  We could probably have gone one step further to:

“Return applications that are successful, transformed to job representations for the jobseeker”
```java
return applications.thatAreSuccessful().transformed(toJobRepresentationsFor(jobseeker));
```

# Speaking the domain language in code
One of the things I like to do when looking at code is to ask where I would expect to find something.  “What happens when ABC does XYZ?”  “Where do I start looking for code related to ABC?”  A lot of times these are questions you either have to already know the answer to, hunt for, or ask someone who knows the system.  We’re gunning for a better answer - start by looking for class ABC and a method called XYZ.
 
So asking the questions – “What happens when a Jobseeker upgrades” and “Where do I start looking for code related to upgrades?”  Did anyone immediately say to themselves, “well it would be in UpgradeService or UpgradeManager?”  It’s a common paradigm, and one we’ve used extensively in the past.
 
Sometimes we have to take a step back and think about how we’re modeling and interacting.  An example is our transition from a stateless service for completing upgrades to domain models that complete the upgrade and reflect a language we can relate to.   Originally, there was an UpgradeService that had a method accepting a Jobseeker, ProductOption, and PaymentMethod.  It then went on to organize the interactions of these together to complete the upgrade.  This left the higher level application(client of the domain) code less expressive.

UpgradeWorkflow (Use Case):
```java
Jobseeker jobseeker = allJobseekers.jobseekerWith(jobseekerId);
NewCreditCard card = creditCard(newCreditCardRepresentation, jobseeker);
ProductOption productOption = allProductOptions.optionFor(productOptionId);

upgradeService.upgrade(jobseeker, productOption, creditCard);
```
UpgradeService:
```java
public UpgradeReceipt upgrade(Jobseeker jobseeker,
                            	ProductOption productOption,
                            	PaymentMethod paymentMethod)
{
	Receipt receipt = makePayment(productOption, paymentMethod, jobseeker);
	Subscription subscription = upgrade(jobseeker, productOption);
	return upgradeReceiptOf(subscription, receipt);
}
 
private Receipt makePayment(ProductOption productOption,
                              PaymentMethod paymentMethod,
                              Jobseeker jobseeker)
{
  Payment payment = upgradeOptionFactory.optionFor(productOption, jobseeker).asPayment();
  return payment.makeWith(paymentMethod);
}
```
 
After some refactoring to allow the models to complete the work on their own, we were still left with a question – what does the interaction look like?
```java
productOption.upgradeToWith(jobseeker, creditCard);  // ?
productOption.upgradeFor(jobseeker).payingWith(creditCard); // ?
```
Taking a step back, the important question is – how would we have a conversation about this?  How would a Product Manager explain this use case?  They would probably say “the Jobseeker is upgrading to the selected product option, and paying by credit card.”  So that’s what the code looks like – a sentence (or close to it) that says just that.  So in the end, the application code looks like:
 
UpgradeWorkflow (Use Case):
```java
Jobseeker jobseeker = allJobseekers.jobseekerWith(jobseekerId);
NewCreditCard card = creditCard(newCreditCardRepresentation, jobseeker);
ProductOption productOption = allProductOptions.optionFor(productOptionId);

jobseeker.upgradingTo(productOption).payBy(creditCard);
```
upgradingTo returns an Upgrade with a payBy method that has meaningful steps within it:
```java
public UpgradeReceipt payBy(CreditCard card)
{
  charge(card);
  upgradeSubscription();
  return upgradeReceipt();
}
```
So back to our questions:

What happens when a Jobseeker upgrades?  Open the Jobseeker class and find the method for upgrading.
 
Where do I start looking for code related to upgrades?”  Open the Upgrade class.


# First class collections
Rather than passing around Collection<Model>, we frequently create meaningful classes to encapsulate the collection.  This provides a natural home for many operations like sorting, transforming, filtering, etc.  This reduces clutter in calling code and makes it more expressive (noticing a pattern yet?), hiding away the mechanical details of iterating over collections in order to do something.

If we take a look at an earlier example, we have a Users class that handles things like filtering and sorting:

some methods from our Users class:
```java
public Users sorted(Comparator<User> comparator)
{
  List<User> sorted = new ArrayList<>(users);
  sorted.sort(comparator);
  return new Users(sorted);
}

public Users without(Users otherUsers)
{
  return without(otherUsers.users);
}

public Users without(User... otherUsers)
{
  return without(asList(otherUsers));
}

private Users without(Collection<User> otherUsers)
{
  Collection<User> trimmedDown = new LinkedHashSet<>(users);
  trimmedDown.removeAll(otherUsers);
  return new Users(trimmedDown);
}
```
our SearchWorkflow:
```java
Users matchingUsers = allUsers.matching(query).without(currentUser).sorted(by(Name.lastThenFirst()));
```

to do the same thing with regular collections, our calling code would probably look something more like:
```java
Iterable<User> matchingUsers = allUsers.matching(query);
  
List<User> withoutCurrentUser = new ArrayList<>();
for (User user : matchingUsers) {
  if (!user.equals(currentUser)) {
    withoutCurrentUser.add(user);
  }
}
    
Collections.sort(withoutCurrentUser, by(Name.lastThenFirst()));
```
and who wants to read that??  By using first class collections, we can write more declarative high level code that almost reads like English.

# In Closing
Code that reads well and overall quality are things that we highly value.  We want our code to express itself to the next developer that has to come and make changes - and that’s at the heart of our principles: change.  If code never changed, we wouldn’t need any of these values.  But that’s the point of software - it’s soft. And that's what this series is really about - high level architecture, OO principles, expressive code - all working together to embrace change and make it easier, because that’s where the value really is.
