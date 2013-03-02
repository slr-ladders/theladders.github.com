---
author: Kyle Winter
comments: true
date: 2013-02-20 08:15:15
layout: post
slug: mutation-testing-with-pit-a-step-beyond-normal-code-coverage
title: 'Mutation testing with PIT: A step beyond normal code coverage'
wordpress_id: 844
categories:
- Testing
- PIT
---
{% blockquote --Edsger W. Dijkstra %}
"Program testing can be used to show the presence of bugs, but never to show their absence!"
{% endblockquote %}


When we started out building our [Signature program](http://www.cenedella.com/job-search/job-offer-guaranteed-signature/), we had a goal in mind - test the &lt;insert expletive of choice here&gt; out of it.  We also wanted to make sure that not only did we test it, but we tested it right.  Regular code line coverage tools like [Clover](http://www.atlassian.com/software/clover/overview) are great, but typically only tell you that a line of code was executed - not necessarily that it was verified.  Many developers often see them as a way to determine what's been tested, but in reality they are better at_ highlighting code that hasn't been tested at all_.

Our interest in mutation testing stemmed from a talk about how occasionally we see bad/ineffective tests, ones that give the impression of testing the code but in reality don't do a great job.  [Sean T Allen](https://twitter.com/SeanTAllen) and I had apparently both already been looking into a new tool, because once the discussion came up we were already on the same page.  Enter [PIT](http://pitest.org/), a mutation testing tool under active development.  We decided to try it out in combination with Clover, and the results were:

![tim_and_eric_mind_blown](/images/tim_and_eric_mind_blown.gif)


# 


# But first, what is mutation testing?


For those unfamiliar with how mutation testing works, I'll offer a brief summary.  After your sources and tests are compiled and run, a mutation test framework like PIT will alter the program code and insert ‘mutations’, such as changing != to == or completely removing a line.  It will then run the tests that exercise that chunk of code again, with the expectation that at least one of them should now fail.  If your tests are well written, or more importantly, _complete_, then at least one assertion should have been broken by PIT’s change.  (For more, [Jeremy Jarrell’s introduction](http://www.simple-talk.com/dotnet/.net-tools/mutation-testing/) (first 2 sections) sums it up pretty well)


# 




# Your 100% coverage?  It’s a lie.


You write a test - it's green and all is well.  But are you _certain_ that it will fail if someone mistakenly alters the code?  “Yea, I have tons-o-coverage” you say?  Typical line coverage tools like Clover can lull you into a false sense of security by showing 100% coverage without really delivering on that promise.  And that’s probably fine - heck, a lot of teams/projects would be happy to break 90% overall line coverage (or 50%...or 20%).  But there are a few of us here that border on insane and try to push the envelope - more, more, more!


# So what's so great/different about mutation testing?




## Testing your tests:


One of the most important long-term benefits of a test is not knowing that it passes, but rather knowing that it will fail if the code is broken.  When not TDDing, I tend to alter the code or comment out blocks and ensure that the test fails as expected.  Sometimes we write tests that don't fail correctly with the code they test: maybe because of a mistaken assumption, or maybe because of a slight oversight - it happens.  Mutation testing is an effective, automated way of enforcing that tests fail correctly.


## Code is verified:


PIT provides a way of ensuring that you've written complete tests that verify the results of executing a piece of code.  The core concept of mutation testing is a powerful one - if you botch a line of code, a test should break somewhere.  If a test doesn't break, it means your tests aren't complete, the test may be wrong, or the line of code just flat out isn't doing anything.  In one case, we discovered dead code that was identified by PIT when switching our storage model.

Depending on how far you believe in test coverage in general and mutation testing itself, it can be a great ally.  We decided to aim high - test everything.  PIT was vital in ensuring that we were actually verifying each line of code that we set out to.


# 




# An Example:


To illustrate an example of what PIT does, consider the below (very basic) class and test:


``` java PersonFactory https://github.com/TheLadders/pit-example/blob/master/src/main/java/com/theladders/PersonFactory.java Source
public class PersonFactory
{
  public Person createPerson()
  {
    Person person = new Person();
    person.setFirstName("First");
    person.setLastName("Last");
    return person;
  }
}
```
``` java Person https://github.com/TheLadders/pit-example/blob/master/src/main/java/com/theladders/Person.java Source
public class Person
{
  private String firstName;
  private String lastName;

  public String getFirstName()
  {
    return firstName;
  }

  public void setFirstName(String firstName)
  {
    this.firstName = firstName;
  }

  public String getLastName()
  {
    return lastName;
  }

  public void setLastName(String lastName)
  {
    this.lastName = lastName;
  }
}
```
``` java PersonFactoryTest https://github.com/TheLadders/pit-example/blob/master/src/test/java/com/theladders/PersonFactoryTest.java Source
public class PersonFactoryTest
{
  @Test
  public void test()
  {
    Person person = new PersonFactory().createPerson();
    String firstName = person.getFirstName();
    String lastName = person.getLastName();
    assertEquals("First", firstName);
    // forgot test for last name
  }
}
```

Clover (and PIT) will say that the _**line**_ coverage is 100%.  But at a close glance - how many untested pieces of code do you see?  PIT _**mutation**_ coverage will point out that there are 2 - the call to person.setLastName("Last") and the getLastName() method.  Both were executed as part of the test, but neither are actually verified for correctness.


## Clover Results:




## ![clover results](/images/clover.png)




## PIT Results:




## ![pit failure](/images/pit-failure.png)




## ![PersonFactory class](/images/person-factory.png)


(Person report excluded for brevity)

You’ll notice that the setLastName method in the PersonFactory is highlighted in red, with an explanation below:
removed call to com/theladders/Person::setLastName : SURVIVED

What this means is that PIT altered the code and removed the call to setLastName() completely, ran the tests again, and they all still passed - meaning that the mutation survived.  You’ll also notice that it tried the same thing for setFirstName(), but it was successfully killed by our test (it failed, as it should).

Once we add a test for last name, we’ll see that PIT will now report that all mutations are killed.  Essentially what it means, is that PIT couldn’t find a way to screw with the code without breaking a test.

``` java PersonFactoryTest https://github.com/TheLadders/pit-example/blob/master/src/test/java/com/theladders/PersonFactoryTest.java Source
public class PersonFactoryTest
{
  @Test
  public void test()
  {
    Person person = new PersonFactory().createPerson();
    String firstName = person.getFirstName();
    String lastName = person.getLastName();
    assertEquals("First", firstName);
    assertEquals("Last", lastName);
  }
}
```


## PIT Results afterwards:




## ![Pit success](/images/pit-success.png)


This was a very trivial example, and PIT supports much more than what I've shown you here.  As you may have noticed, I skipped over one of the killed mutations: if (x != null) null else throw new RuntimeException.  This is another type of fault that PIT will try to introduce for return objects.  The full list of mutations can be found [here](http://pitest.org/quickstart/mutators/).


# 




# Our Experience with PIT:


We started using it last year on a new project with some really great success.  As part of it, we were building a RESTful web service with Jersey.  It was a green field project with no legacy code - everything written from scratch except for small internal libraries.  We tested almost every meaningful thing we could about the server (web interfaces, security XML configs, null validation rules, etc).  It was very heavy on integration tests - some just verified all the business components working together and some deployed the server on embedded Jetty and hit the web endpoints.  Towards the end we were maintaining around 98% in both Clover and PIT (excluding Data Transfer Object classes), and ended up around 95%.

While we also used Clover for basic code coverage, as we got our PIT mutation coverage up into the 90s I stopped paying much attention to Clover.  Our use of PIT was to ensure that we were actually testing and verifying all the parts of the code that we thought we were, and to find the places where we needed to fill in more tests or assertions.  We would add/modify tests so that each line of code we wrote (almost) was also backed by an assertion somewhere.  Essentially, "Hey PIT, where do I need to add more tests and assertions?"

This gave us extreme confidence in our tests - if the code was modified incorrectly (with some small exceptions), a test would break and we knew it.  The effects of that confidence were outstanding.  At TheLadders we place a lot of value in code quality and "doing things right," so refactoring is a large part of our process.  It enabled us to refactor at will with little fear of breaking anything, which happened quite frequently in many different ways, especially as a new project growing from the ground up.

The best example of a big win was a refactoring to shift how we stored and tracked state.  When we first started out, we were creating and updating rows in the database (update in place).  We decided to switch to an [Event Sourcing](http://martinfowler.com/eaaDev/EventSourcing.html) approach - instead of storing/retrieving state in the database, we instead stored 'actions' and inputs in the database and then rebuilt the state in memory from those actions.  This was a large change to how a lot of the internals operated, and would normally carry a big risk factor in breaking existing functionality.  In this case, that risk factor was minimal and hardly played a part in our decision.  Because of the confidence we had in our tests thanks to PIT (and the fact that the majority of them were high level integration tests), all we did was start switching over and making changes until the tests were green again, and we were done.  The tests were the ultimate source of how the server needed to act, and PIT helped ensure that those tests covered everything the server was expected to do.

If you want to try it out yourself, the above example in code is available here: [https://github.com/TheLadders/pit-example](https://github.com/TheLadders/pit-example)
