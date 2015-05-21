---
author: Kyle Winter 
layout: post
title: "Design Principles and Goals (Part 2) - A Trip Back to OO"
date: 2015-05-21 12:02
comments: true
categories: 
published: false
---

It’s no great secret that today’s world is full of procedural Java code and engineers that have been taught that encapsulation means having getters and setters to hide properties (hey...I used to be one of em once upon a time).

In the past we’ve blogged about our onboarding process, which involves an Object Calisthenics exercise and Uncle Bob’s SOLID videos.  What good would all that be if we left it at exercises and discussions?  We put a lot of that to work in our newer customer facing web services.

## Use Polymorphic classes instead of conditionals
Rather than relying on conditionals and asking data related questions of our models, we try to rely more on interfaces and subtypes for behavior and “tell don’t ask.”  Hidden “type checks” are the worst offenders, and usually a prime candidate for polymorphic models that expose better meaning.  What do I mean by a hidden type check?  Things like customer.isGoldLevelMember(), vehicle.hasFourWheels(), person.isChild().  Those are really asking about what “type” of thing we’re talking about.  We’ll get into more about exposing meaning over type checks in the “Making implicit concepts explicit” section.  Along with polymorphism comes the good ole…

## Visitor Pattern
This is something that pops up quite a bit throughout our use cases.  We often have mixed collections of an abstraction, where each item may be a different subclass.  Perhaps a collection of activity between you and a Recruiter, or interesting notifications for you to see.  
Most of the time, this boils down to just creating different representations of each object to serialize and send back to the client, so we’ve taken to calling them Presenters.

The visitor pattern has been around for a long time, and allows us to let the compiler do the dirty work of telling us where we need to make code changes when adding a new type.

The textbook example of a Visitor relies directly on compiler type checks, something like:

```
public interface ShapeVisitor 
{
  void visit(Circle circle);
  void visit(Square square);
}

public interface VisitableShape
{
  void accept(ShapeVisitor visitor);
}

public class Circle implements VisitableShape
{
  @Override
  public void accept(ShapeVisitor visitor) 
  {
    visitor.visit(this);
  }
}
```
```
VisitableShape shape = …
shape.accept(visitor);
```

A lot of times we take this a little bit further, and our Visitor will also be a data contract of what’s expected for each case, and also return something.  In the case of displaying someone’s activity feed, we have something like:
```
public interface Presenter<T>
{
  T profileSaveOn(DateTime eventDate);

  T profileViewOn(DateTime eventDate);

  T jobApplyRating(DateTime eventDate,
                   JobApplyRatingType type,
                   DateTime jobApplyDate,
                   JobSummary jobSummary);

  T hiringAlert(DateTime eventDate,
                JobSummary jobSummary,
                String message);

  T directMessage(DateTime eventDate,
                  String message);

  T resumeDownload(DateTime eventDate);

  T resumeShare(DateTime eventDate);
}

public abstract class RecruiterEvent
{
  …
  public abstract <T> T presentedWith(Presenter<T> presenter);
}

public class ResumeDownload extends RecruiterEvent
  @Override
  public <T> T presentedWith(Presenter<T> presenter)
  {
    return presenter.resumeDownload(eventDate());
  }
}
```

So if we add a new type of activity, we add another method to our Presenter, and the compiler tells us all the places we need to account for, no guesswork!  We’ve also created a data contract between our models and concrete presenters, so that we can maintain data encapsulation in our models and be explicit about what data is needed for each type of activity.

### Presenters for business rules

We also frequently use a flavor of the visitor pattern to enforce business rules, even if we may not have explicit types for each case.  While not your textbook implementation, it still takes advantage of double dispatch to realize different scenarios (rather than types).

So what might that look like?  We have an interface that represents the possible states of a Recruiter that we care about:

```
public interface Presenter<T>
{
  T validRecruiter(RecruiterData recruiterData);
  T invalidRecruiter(RecruiterData recruiterData);
}
```

RecruiterData is just a Data Transfer Object that contains the recruiter’s data.  This Presenter interface allows us to contain the rules for what “valid” means within the Recruiter class itself, while allowing(and forcing) applications to consider what happens when a Recruiter is invalid.

Recruiter:
```
  public <T> T presentedWith(Presenter<T> presenter)
  {
    if (isVisible())
    {
      return presenter.validRecruiter(asData());
    }
    return presenter.invalidRecruiter(asData());
  }

  private boolean isVisible()
  {
    return subscription.allowsRecruiterToBeVisible() && profile.isVisible();
  }
```
This allows our Recruiter class to be more about behavior and enforcing our business rules, and less about what data properties a recruiter has.

### Presenters for hiding dependencies
This same concept is how we keep Jersey isolated to the web components.  Our business tier depends on a JobPresenter interface, and the Jersey resource passes in an implementation that happens to use Jersey classes:

```
public interface JobPresenter<T>
{
  T success(JobRepresentation jobRepresentation);
  T forbidden(JobRepresentation jobRepresentation);
}

public class JerseyJobPresenter implements JobPresenter<Response>
{
  @Override
  public Response success(JobRepresentation jobRepresentation)
  {
    return buildResponse(Response.Status.OK, jobRepresentation);
  }

  @Override
  public Response forbidden(JobRepresentation jobRepresentation)
  {
    return buildResponse(Response.Status.FORBIDDEN, paywallFor(jobRepresentation));
  }

```
we then have code in the Workflow that looks like:
```
    JobRepresentation jobRepresentation = job.representationFor(jobseeker);

    if (PayWall.isHitFor(jobseeker, job))
    {
      return presenter.forbidden(jobRepresentation);
    }

    return presenter.success(jobRepresentation);
```

## Enums
Ahh enums.  Yes enums get their own special little blurb, because enums are special.  Enums let you do bad bad things, without you ever noticing.  The problem with enums is...us.   Developers tend to allow the entire application to know that a class is an enum, and pepper instance checks throughout it.  This ends up leaking more information then it needs to, and can make it hard to switch a class from being an enum to a real class.  Our rule is that only two kinds of places should know that it’s an enum at all - the enum itself, and the classes that pick an enum value.

### No public type checking
The fact that a class is an enum should be an implementation detail, not a contract.  It also makes it hard to add new enum values, and violates the Open Closed Principle.  Therefore, the only class that should compare enum instance equality is the enum class.  That means that other classes should not do something like:

```
if (status == Status.APPROVED) {
  // do something
}
```
but instead ask the enum the question directly via status.isApproved(), or even better tell it to do something (tell don't ask).

Two enum checks is a sign that there’s a more meaningful concept hiding there
if (day == Day.SATURDAY || day == Day.SUNDAY) {
  // do something
}
the above is hiding a very important concept, something like day.isOnTheWeekend();

Who says enums have to be void of logic?  Logic belongs where it belongs, regardless of whether the class is a typical class or an enum.  Enums should be viewed as just a way to restrict input values, and possibly make the internal implementation of the class easier.  Here’s an example of one of our enums:
```
public enum ProfileStatus
{
  NO_PROFILE(0),
  INCOMPLETE(1),
  PENDING(2),
  DECLINED(3),
  PERMANENTLY_DECLINED(4),
  APPROVED(5),
  DELETED(6),
  SUSPENDED(7),
  PENDING_ESCALATED(8),
  REMOVED(9);

  private static final Collection<ProfileStatus> CAN_BE_EXPEDITED = Arrays.asList(INCOMPLETE,
                                                                                  PENDING,
                                                                                  PENDING_ESCALATED);

  private final int                              id;

  private ProfileStatus(int id)
  {
    this.id = id;
  }

  public boolean isApproved()
  {
    return APPROVED == this;
  }

  public boolean isExpeditedBy(ProfileStatus expeditedProfileStatus)
  {
    return canBeExpedited() && expeditedProfileStatus.isApproved();
  }

  private boolean canBeExpedited()
  {
    return CAN_BE_EXPEDITED.contains(this);
  }
```
Once upon a time the INCOMPLETE, PENDING, and PENDING_ESCALATED were checked against with == by another class, and it was hard to figure out what was really going on.  Now we’ve introduced names for what that grouping is - something that can be expedited - and contained that within this class.  This leaves the calling code more expressive:

Profile:
```
  private boolean statusAllowsVisibility()
  {
    return profileStatus.isApproved() || profileStatus.isExpeditedBy(expeditedProfileStatus);
  }
```
## Making implicit concepts explicit
One of the things that became hard to manage in our old system is the difference between Basic and Premium accounts.  We were switching on basic/premium for almost everything that acted differently in each scenario, which becomes a problem in many ways:
 
If we want to add another type (which we did, called Freemium), we now have to go find all those conditional statements and add another part to handle Freemium accounts.
 
Meaning – What does it mean to have a Basic, Premium, or Freemium account?  In order to answer that in our old system, you have to go find the 100s of conditionals that do something different in each case.  The meaning was held implicitly in the code that called methods like isBasic(), crippling our ability to meaningfully describe the difference between the accounts.
 
The answer?  Model the behavior of each type of account, and make the meaning explicit.  Instead of
```
If (user.isBasic()) {
 	.. can’t apply ..
} else {
	.. can apply ...
}
```
just ask the question of a polymorphic object – can they apply?
```
if (permissions.canApply()) {
    .. can apply ..
} else {
    .. can’t apply ..
}
 
BasicPermissions
canApply() { return false; }
canUpgrade() { return true; }
 
PremiumPermissions
canApply() { return true; }
canUpgrade() { return false; }
```
This encapsulates the meaning of Basic vs. Premium in type specific models, and also alleviates problems that the Open Closed Principle highlights.  Determining whether or not users can apply to a job has now become an explicit part of our domain model.  If we need to add another type (like Freemium), all we have to do is create a new FreemiumPermissions class and describe what it means to be Freemium.
```
FreemiumPermissions
canApply() {
    return numberOfApplicationsThisWeek() < 3;
}
canUpgrade() { return true; }
```
We have an explicit rule that we are only allowed to ask if a user is basic/premium/freemium/etc for two reasons:

* copy and branding, since it might say the word “Basic” or “Premium”
* a factory is creating a polymorphic model

other than that, we must ask a behavioral question instead.
 
## Return null, get shot
One of our rules in the new code is to never publicly return or pass null to another class.  Never.  You can try, but people are clumsy...stairs are slippery...accidents are bound to happen.  Null can be used in classes internally and must be accounted for at system boundaries, but is considered a true error anywhere else.  These are also the only places that defensive null checks are considered appropriate.   So how do we accomplish that?  We stole code.
 
### Call me Maybe
We created our our Maybe class, based off of Nat Pryce’s https://github.com/npryce/maybe-java. Maybe is similar to Scala’s Option and Java 8’s Optional.  Anywhere we expose a value that is optional and could be null, we expose a Maybe.  This clearly demarcates when and where a value may or may not be present, and forces us to be more explicit about what happens if it’s not there.
 
The Null Object pattern is also valuable, but is really only useful for behavioral classes that can provide sensible implementations for methods.  It doesn’t work as well for data driven classes – what do you return if someone calls firstName() or id() for Recruiter data that doesn’t exist?  That’s when Maybe becomes a better choice.
 
So in light of returning things that might not exist, either return a Maybe, Null Object, or throw an exception.  Keep null checking at the system boundaries, and we never have to wonder where along the line something is or isn’t null.
 
Example for jobseeker salary:
``` 
Salary salary = serviceJobseeker.getSalary();
 
if (salary == null)
	return false;
 
return salary < limit;
``` 
compared to
```
return serviceJobseeker.getSalary().query(isBelow(limit)).otherwise(false);
```
or even better:
```
return serviceJobseeker.salary(isBelow(limit)).otherwise(false);
``` 
There is a tradeoff though, particularly for Java 7 and below - we have to create a Google Guava function, which is ugly.  We're willing to accept this little bit of ugliness and tuck it away at the bottom of the class, or in its own class itself (much less of a problem in Java 8).
SalaryPredicates:
```
public static Predicate<Salary> isBelow(final int limit)
{
 return new Predicate<Salary>()
  {
    @Override
    public boolean apply(Salary salary)
    {
      return salary.isBelow(limit);
    }
  };
}
```

When talking about being expressive in code, readability, and separating mechanics from meaning – we’ve made a nice improvement.  There are some mechanics in the first example, mixed in between the code that enforces the business rules.  The last example is short and sweet, and only contains the parts we really care about.  This really starts to become beneficial when you have to manipulate optional data more than once as it passes through the system.

### JDK8
Some of our web services are running on JDK8, which introduces its own Optional class, first class functions, and lambda expressions.  This makes conforming to this rule much much easier.  Jackson also has a JDK8 module that understands Optional, so our representation/serialization classes can use them directly, and much of our code has no reason to use nulls whatsoever from end to end.

## Wrapping up
We've talked a little bit about how we use polymorphism and OO fundamentals to enforce the rules of our system, and how we can model behavior and meaning in order to be more extensible and accepting of change.  Relying on abstraction for important parts of our system is central in our code, and in strong object oriented design in general.  In tomorrow's post, we'll dig a little deeper into being expressive in code, and how we like to write our code line by line.
