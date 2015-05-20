---
author: Kyle Winter
layout: post
title: "Design Principles and Goals (Part 1) - High Level Architecture"
date: 2015-05-20 15:47
comments: true
categories: Architecture
published: true 
---

{% blockquote --Robin Longstride %}
If you're building for the future, you need to keep your foundations strong
{% endblockquote %}

# Rebuilding for the Future

A few years ago, we began rebuilding the member experience on theladders.com from almost the ground up.  It was previously a typical Spring MVC/JSP request based application, but it was decided that we would start over with a different client/server model.  The end result is a Single Page Application - a JavaScript thick(er) client and a RESTful web service.  It went fully live in September of 2012 (which means this post is long overdue), and set the stage for how we would build our customer facing web services to come.  The architecture, design goals, and principles we’ve held in rebuilding our server also came to light in the web services we build for our mobile applications, and have matured and come full circle since the rebuild was first launched.  We’re going to post a small series over the next few days sharing some of those details.

### A look at the past
As we’ve built our new servers, we’ve kept in mind our existing code bases and some of the pain points we felt there.  Our legacy code had fallen prey to many of the typical symptoms that long living code bases fall into: business logic in JSPs, logic scattered throughout the application requiring [shotgun surgery](https://sourcemaking.com/refactoring/shotgun-surgery) to fix, difficulty trying new business models, dependency nightmares.  Just looking up the data for a user required a massive dependency tree, in large part due to the lookup class also mixing in unrelated functionality for performing actions for many different use cases.  Broad sweeping projects were frequently estimated on the scale of months, and our code was fighting back against change.  We wanted to paint a better picture for the future, so these pain points were at the forefront of our minds as we wrote new code.

### General Approach
Our approach has been heavily influenced by Domain Driven Design and Robert Martin’s [SOLID principles](http://butunclebob.com/ArticleS.UncleBob.PrinciplesOfOod).  We wanted to build an application that would be accepting of change (and in fact embrace it) and be maintainable into the future.  At the top of the list are things like readability, expressive code, extensive test coverage, flexible domain code, and separation of concerns like web/API vs. business rules.  Much of what we will discuss isn’t new or of our own creation, but has been around for a while, just waiting to be put to use.  We won't get into all the nitty gritty details, but hopefully give a good explanation of the principles that guide us and why we value them.

As a technical team, we frequently watch Uncle Bob’s Clean Code episodes, covering a range of topics from things like class and method design/implementation, to high level concepts like application architecture and component/module/library design.  We’ve specifically pulled the SOLID principles into our [onboarding bootcamp](http://dev.theladders.com/2013/02/onboarding/), as they provide a great foundation for object oriented design.  We wanted to keep these principles at heart when moving forward with our new member site.

### Client and Server Overview
Our client is a Single Page Application leveraging Backbone.js.  There are only a few HTML pages rendered by the server, one of which loads up the client application.  I mentioned that we have a thick(er) client, because I wouldn’t quite call it a full blown thick client.  Making requests to the server is still central to the client working, but it is a stateful GUI in its own right, handling problems like caching, history, and emulating a local “session.”

The server is a stateless RESTful web service, utilizing Jersey as our web layer framework, Spring for Dependency Injection, and a variety of things for data access (we read/write data from different kinds of stores).  The bulk of our business rules and data processing lives here, with business decisions typically communicated to the client via Hypermedia links.  It frequently talks to other “core domain” web services and applies processing on top, so we typically refer to it as an orchestration service.  It was written in Java 7, which brought up several challenges in trying to conform to our principles that we’ll cover later on.

****
## High Level Architecture
We’ll start with a high level view of our general application architecture.  It’s a typical N-tier application, where we view the business tier as being further subdivided in half.  We’ll call the three major layers Presentation, Business, and Storage, with the Business Layer also distinguishing between Application and Domain.  Presentation usually refers to a layer dealing with UI concerns, but in the case of a RESTful service it’s our web/API layer.

{% img center /images/new-lw-design/nlw-application-architecture.png 'High Level Architecture' %}

**Presentation**

Key Components

* Resource
  * The web/presentation component. We use Jersey, so we’ve taken to calling them Resources.  Spring MVC would call them Controllers.  These should handle pulling/pushing data from/to a request/response, possibly user facing validation, etc.  This component (and related friends) is the only place that web framework imports may be used, such as Jersey classes.  And that’s it - ideally methods on these components are one liners calling out to a Workflow.  Any logic not dealing with web specifics should live in the workflow/domain/service components.
* Representation
  * The web layer’s version of the model.  It “represents” the JSON contract between the client and server, which is handled by JAXB/Jackson.  Technically this crosses into the business tier as well, as it’s there that these are typically instantiated and then returned to the Resource.  It is acting as both a DTO across the web/application boundary and the presentation model.  While this is not a pure separation of concerns, it’s a tradeoff that we’re willing to make in order to keep things simple.

**Business**

Key Components

* Workflow
  * Also called Application Layer, Use Case, or Service Facade - this represents the entry point of a business task/use-case. Most of the time, these should not directly implement solutions, but rather be a high level coordinator of other objects (it can be viewed as a facade over finer grained models/services). This is a great candidate for a business level acceptance/integration test.  A workflow shouldn’t be reused by any other business components.  Reusing them from other resources is okay if the use-case is really the same. Should never be used by lower components. These ultimately answer to their use-case.
* Domain Models
  * The heart of our application.  When we say Domain Model, we don’t mean a class with a bunch of getters and setters.  Quite the opposite - we shun getters and setters in these classes, and make exceptions where practical.  These classes hold most of the logic and decisions of our application.  Instead of exposing getters and being about data, they expose meaningful methods about behavior.
* Services (Domain or Infrastructure)
  * These are meant to be highly reusable components - building blocks for other parts of the system. They are meant to encapsulate logic/actions that don't necessarily belong in the domain, or to any single domain model. These ultimately answer to re-usability and/or the domain.

**Storage**

Key Components

* Repository (typically called AllSomethings)
  * Represents a store for an entity (an 'aggregate root' in DDD terms). The store could be whatever (relational DB, file, in memory, backed by a RESTful web service). This may handle reads/writes/queries directly and/or delegate them to internal members (like if it needed 2 DAOs to create an entity). Think of it as a slightly higher level concept of a DAO. The repository might execute SQL queries itself, it might coordinate another DAO or 2 to execute SQL queries, or it might not even use a database at all - maybe it hits another web service. What's important about a repository is what it represents - a store for a particular model.  Repositories are really viewed as a collection of models that happens to persist between restarts.  An object returned from a Repository should be fully instantiated with everything it needs.
  * We follow the “collection of models” mentality when naming repositories and their methods as well.  Where you might typically see something like jobseekerDao.insert(jobseeker), we would write either allJobseekers.add(jobseeker) or jobseeker.addTo(allJobseekers).
  * The naming convention of AllSomethings allows for some really interesting method names that read more naturally in high level code, like our workflow for searching users:
    * Users matchingUsers = allUsers.matching(query).except(currentUser).sorted(by(Name.lastThenFirst()));
* DAO
  * Pretty much anything else dealing with reading/writing data that doesn’t represent a store for a model.  

## Model things with…Models
Many software engineers are familiar with the Controller/Service/DAO pattern, complete with a “model” that travels between the layers.  A lot of times, it may just be Controller/DAO.  If you’re lucky, you may even have been on a project that split the Service tier into Use Case services and building block services.  And if you were really lucky, you might have even had different models at different layers when things didn't fit quite right.  Unfortunately, that’s usually not the case.  More than likely, the “model” is a JavaBean that is full of getters and setters, and void of business logic – leaving the rules up to the services.  That's not to say that these things are wrong, there are certainly cases where they are beneficial - it's just not for us.  There is rarely ever a golden "right" way, there are only different options with tradeoffs.
 
In our new systems, we’re using the models as the heart of our design.  They own the rules, the domain, and the logic.  That doesn’t mean that we don’t have stateless service classes – we do – but they play a much different role.  Instead of a Controller/Service/DAO pattern, we end up with something more like Controller/Use Case/Repository, with the typical steps being:
 
1.     Controller reads (unmarshals) the request, and hands it off to the Use Case
2.     The Use Case either creates a model via a factory, or looks one up from a repository
3.     The Use Case tells the model to do something
 
An example is how we unsubscribe a subscription.  There is no manager or service like
 
    subscriptionService.unsubscribe(jobseekerId, exitSurvey.unsubscribeReason());
 
Instead, inside the Use Case we get a Subscription model, and tell it to unsubscribe:

``` 
Subscription subscription = allSubscriptions.subscriptionFor(jobseekerId);
subscription.unsubscribeWith(exitSurvey.unsubscribeReason());
```

It might not seem like much, but now we have stateful models that use our terms – we talk about “Subscriptions” in meetings, not a “Subscription Service.”  It also gives us a better home to determine things like – what happens when we try to unsubscribe a Basic Subscription?  What happens when we try to unsubscribe a Premium subscription?  If we only had a SubscriptionService, we’d probably be looking for a switch statement in there somewhere, something like isPremium or isBasic.  Instead, we have 2 different Subscription model implementations – BasicSubscription and PremiumSubscription, each which house their own rules for what should happen in their particular case.

This was a fairly simple example, but we can also take a look at some of the methods on one of our User models:
```
  public Connection connectWith(User anotherUser)
  public void accept(Connection connection)
  public void ignore(Connection connection)
  public void disconnect(Connection connection)
  public void reconnect(Connection connection)
  public NewMessage send(NewMessageRepresentation message)
  public void receive(NewMessage newMessage)
  public void like(Job job)
  public void unlike(Job job)
```

These methods are all about the User doing something rather than just returning data to a caller.  Sending a message looks like:
```
@Component
public class SendMessageWorkflow
{
  @Inject
  private AllUsers allUsers;

  public void send(NewMessageRepresentation message,
                   UserId currentUserId,
                   UserId recipientId)
  {
    User currentUser = allUsers.findBy(currentUserId);
    User anotherUser = allUsers.findBy(recipientId);

    currentUser.send(message).to(anotherUser);
  }

}
```

## Enabling domain models with dependencies
This is a topic of debate within the scope of models that “do things” rather than anemic models.  We’ve decided to go down the route of having models that contain their dependencies, enabling them to complete their tasks on their own, with method arguments only requiring things that are related to the domain.
 
This is similar to the approach that many frameworks like Rails/Grails take, you can just call model.save().  While the basic crud operations are nice to have completely encapsulated within the model, the advantage comes in higher level concepts.  We can write code like user.like(job) or currentUser.connectWith(anotherUser).

### Mapping models to storage
Because our models are behavior driven (and often polymorphic), they frequently don’t map to storage frameworks very well.  We’re ok with that - most of the time we’ll have a separate set of storage layer classes that are more suitable for that type of thing.  Those classes might have public final variables or a bunch of getters/setters on them: they’re meant to expose their data, it’s their purpose.  Our domain models should be free from having to worry about the persistence layer.  A question we like to ask a lot is: Database?  What database?  Who said anything about a database?  And who said it was relational?

We want our application code to make sense regardless of whether or not there’s a database.  We read data from a variety of different stores: relational DB tables, key/value stores like Riak/Couchbase/Memcached, other web services, etc.  In some applications, we have a “standalone” mode where everything is just held in memory.  We like to avoid having the storage layer mechanism leaking out and affecting our other code - we want to be able to swap different implementations in/out at will, with minimal impact.

It's common to find something similar to:

```
public interface AllSomethings
{
  void add(Something something):
  void remove(Something something);
  Somethings createdBy(UserId userId);
  Somethings postedBefore(Date date);
}
 
@Repository
@Profile("standalone")
public class AllSomethingsInMemory implements AllSomethings
{
  private Set<Something> somethings;
  ...
}
 
@Repository
@Profile("default")
public class AllSomethingsInMySql implements AllSomethings
{
  @Inject
  private SomethingsSql sql;
  ...
}
```

### Presenting models
This is a RESTful web API, so at some point we've got to expose data.  But we said we're anti-getters on our domain models, so how do we do it?  One of the responsibilities of a model is not to expose each property individual, but rather present itself in some fashion.  Many times this is just a represention() or toRepresentation() method that returns the presentation layer class, and sometimes we introduce an interface if we want to decouple the model from the presentation class or response being sent back.  We'll dig a little more into our Presenter interfaces in our next post.

## Typical Usage Scenario
The handling of a GET request typically looks like this:

* The request comes in and gets picked up by a Jersey resource.  This handles the unmarshalling of any data, request parameter extraction, and/or retrieval of the “current user” identification if necessary.  It then immediately passes control to a Workflow for the specific use case at hand.
* The Workflow looks up one or more models from the Repositories
* The Workflow coordinates the model(s) to complete the task at hand
* A Representation is generated (sometimes by a model, sometimes by the Workflow) and returned to the Resource
* The Resource adds any necessary hypermedia links and returns the representation to be marshaled.
  * Technically we use a Jersey Resource filter to add the links after returning from our Resource class, but it’s still ultimately viewed as a responsibility of the Resource
```
@Component
@Produces(MediaType.APPLICATION_JSON)
@Path(“path/to/matches”)
@Scope(Scopes.REQUEST)
public class JobMatchResource
{
  @Inject
  private JobMatchesWorkflow jobMatchesWorkflow;

  @GET
  public JobRepresentations getMatches(@For JobseekerId jobseekerId)
  {
    return jobMatchesWorkflow.matchesFor(jobseekerId);
  }
}

@Component
public class JobMatchesWorkflow
{
  @Inject
  private Recommender recommender;
  @Inject
  private AllJobs     allJobs;
  @Inject
  private AllJobseekers allJobseekers;

  public JobRepresentations matchesFor(JobseekerId jobseekerId)
  {
    JobIds recommendedJobIds = recommender.jobMatchesFor(jobseekerId);
    Jobs jobs = allJobs.forThe(recommendedJobIds);
    Jobseeker jobseeker = allJobseekers.jobseekerWith(jobseekerId);

    return jobs.thatArentBad().toRepresentationsFor(jobseeker);
  }
}
```

****
## Wrapping up
That about sums up some of our high level philosophies, architecture, and control flow.  We’ve set up an environment where layer responsibilities are clearly separated, the workflow steps of completing a task are managed in one place and separate from the details of how those steps are carried out, and placed our domain models at the heart of our system.  Our next post will share some details of our trip back to OO and how we implement the logic behind those steps.
