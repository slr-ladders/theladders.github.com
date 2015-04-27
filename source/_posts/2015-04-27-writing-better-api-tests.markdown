---
author: Matt Jankowski 
layout: post
title: "Writing better API tests"
date: 2015-04-27 17:41
comments: true
categories: Storm
published: true
---

{% blockquote --Theodore Roosevelt %}
It is only through labor and painful effort, by grim energy and resolute courage, that we move on to better things.
{% endblockquote %}

# The problem
When I was first tasked with writing the web service for our [jobseeker iOS app](http://www.theladders.com/mobile/), I wanted to be able to write tests against the API without diving into the world of iOS automated functional testing.  I really didn’t see a need to fire up an iOS client just so I could make calls to a service that was under heavy development and in a constant state of change.  So how could I write tests that would exercise the API in a way similar to an iOS client? 

Fortunately for me, engineers at TheLadders have always emphasized testing in one form or another.  Sometimes this means a unit test for a particular method on a class.  Other times it means an automated functional test (AFT) verifying client/service interactions for a particular feature.  And in some instances it may even mean, f**k it, ship it and see if it blows up in production (a rare occurrence of course).

It turns out that before I even started working on the mobile service, people before me were asking similar questions about testing their APIs, and they had come up with a slightly different type of test that we now call "web tests".  A "web test" is basically a way to fire up an instance of the service for each test and, using a Jersey client, programmatically make calls to that service within the test itself.  This was great because it allowed us to write tests against our APIs without needing to fire up an external tool such as a web browser.  The following code is an example of such a test: 

``` java Basic web test
TestRestClient client = createTestRestClient();
Response response = client.get(“api/jobs”);
assertEquals(200, response.getStatus());
```

This code makes a call to retrieve a list of jobs and verifies the response status code is 200.

The idea of the “web” or “API test” was exactly what I needed.  This gave me a starting point.  But I knew these web tests could be improved upon, making it easier to test our APIs.  So I set about trying to figure out what I wanted for testing the mobile service and came up with a list of requirements.

# The requirements
There were some requirements I wanted to establish that would help guide my decision-making process when writing web tests.  These requirements included the following:

* The tests should mimic how an iOS client would navigate the API
* Anyone reading the test code should be able to easily understand what is being tested
* The code should be easy to reuse, reducing duplication where possible

These really aren’t groundbreaking ideas, but they were helpful to keep in mind at all times.  They served as guideposts throughout my decision-making process.  With these requirements defined, I'm going to give you a quick rundown of some key elements of the API before diving into implementation details.

# The API
The API for the mobile service is a RESTful API that uses [hypermedia as the engine of application state (HATEOAS)](http://en.wikipedia.org/wiki/HATEOAS).  We use the HTTP methods GET, DELETE, POST, and PUT against URLs representing resources.  Everything is stateless and we leverage headers for things such as authorization and versioning.  The following figure illustrates sample request and response against this API:

{% img center medium /images/api-tests/api-request-response.png %}

The above example illustrates a request for the details of an individual job.  One important thing to note here is the “links” element in the JSON.  This is the HATEOAS piece I mentioned earlier. If a user taps the “like” button on the app for this particular job, the client code would send a request to the URL associated with the “like” action.  If the job was already liked when it was retrieved, then an “unlike” link would have been present instead.

We use hypermedia links extensively in the API.  In fact, the only URL that is hard-coded in the iOS application is what we call a “bootstrap” URL.  This URL gives the client all of the hypermedia links needed to get started with the app, and would look something like the following:

``` json Bootstrap JSON response
{
  "links" : [{
    "action" : "authenticate",
    "method" : "POST",
    "uri" : "https://localhost:54837/authenticate",
  }, {
    "action" : "lookupIndustries",
    "method" : "GET",
    "uri" : "https://localhost:54837/api/lookup/industries",
  }, {
    "action" : "autocompleteTitle",
    "method" : "GET",
    "uri" : "https://localhost:54837/api/autocomplete/title?q={toMatch}",
  }, {
    "action" : "register",
    "method" : "POST",
    "uri" : "https://localhost:54837/register",
  }]
}
```

From here, the client has the links for retrieving some lookup lists, maybe a URL for auto-completing the job title field, a link for logging in an existing user, and a link for registering a new user.  If the link to login is invoked, then new response JSON will be returned containing “links” for valid actions that user can perform, and so on and so forth.

There is more to the API and I’ve glossed over some details.  But this should give you enough of an idea of how things work to understand the implementation.

# The implementation
It’s important to keep in mind that the following implementation has evolved over time.  What I present to you here is an example that identifies the key components of the current state.  I was always going back-and-forth with different ideas, trying out various implementations.  And I’m pretty certain the team will continue to iterate on what we have today.

But in its current state, the implementation has the following four components:

1. Class representing request/response JSON
2. Class for performing asserts against a body of JSON
3. Class representing the actions that can be taken on a body of JSON (such as calling hypermedia links or accessing an item in a list)
4. Class representing a user, their state, and their “connection” to the API.

These four components and how they relate to the API can be seen in the following figure:

{% img center medium /images/api-tests/api-implementation-components.png %}

In addition to these four components, I did my  best to provide some “syntactic sugar” for allowing us to write tests in the given/when/then style.  So let’s dive into each of the four components and give you some concrete examples to work with.

## Class representing request/response JSON
We have what are called “representation” classes whose sole purpose is to “represent” incoming or outgoing JSON.  These classes are annotated with JAXB annotations for serialization/deserialization purposes.  These classes also have methods for accessing the hypermedia links (some of which may be optional).  So the following JSON:

``` json Job JSON
{ 
  "details" : { 
    "title" : "Software Engineer", 
    "company" : "TheLadders", 
    "location" : "New York, NY", 
    "postedOn" : "2015-04-17", 
    "salary" : "$100k", 
    "description" : "Work with us!" 
  }, 
  "links" : [ { 
    "action" : "like",
    "method" : "POST", 
    "uri" : "https://localhost:54837/api/jobs/e-1/like" 
  }, { 
    "action" : "get",
    "method" : "GET", 
    "uri" : "https://localhost:54837/api/jobs/e-1" 
  } ] 
}
```

Would be represented by a class that looks like:

``` java JobRepresentation.java
@XmlRootElement
@XmlAccessorType(XmlAccessType.FIELD)
public class JobRepresentation
{
  public JobDetailRepresentation details;
  public HypermediaLinks links;

  ...

  public Optional<HypermediaLink> likeLink()
  {
    return Optional.ofNullable(links.forAction(“like”));
  }

  public Optional<HypermediaLink> unlikeLink()
  {
    return Optional.ofNullable(links.forAction(“unlike”));
  }

  public HypermediaLink getLink()
  {
    return links.forAction(“get”);
  }
}
```

The methods for the links are particularly useful when navigating the API in a way an actual client would in tests.  Having defined a class representing a body of JSON, let's move on to the class for performing assertions against this body of JSON.

## Class for performing asserts against a body of JSON
Having a class for performing assertions against a particular body of JSON helps us achieve two goals:  1) write more expressive test code and 2) have assertions that can be reused across tests.  For example, there may be several tests that require asserting the title for a particular job returned by the API.  We may also want to verify the presence or absence of certain hypermedia links.  The following code illustrates an “asserts” class for a job representation.

``` java JobRepresentationAsserts.java
public class JobRepresentationAsserts
{
  private final JobRepresentation representation;

  ...

  public void hasTitleOf(String title)
  {
    assertEquals(title, representation.details.title);
  }

  ...

  public void hasLikeLink()
  {
    assertTrue(representation.likeLink().isPresent());
  }

  public void doesNotHaveLikeLink()
  {
    assertFalse(representation.likeLink().isPresent());
  }

  public void hasUnlikeLink()
  {
    assertTrue(representation.unlikeLink().isPresent());
  }

  public void doesNotHaveUnlikeLink()
  {
    assertFalse(representation.unlikeLink().isPresent());
  }
}
```

In addition to these “asserts” classes, I created a class with static builder methods to provide some syntactic sugar.  This allows us to write our tests in a given/when/then fashion.  This builder class is as follows:

``` java AssertsBuilder.java
public class AssertsBuilder
{
  ...

  public static JobRepresentationAsserts thenThe(JobRepresentation representation)
  {
    return new JobRepresentationAsserts(representation);
  }

  ...
}
```

This results in something like the following in a test:

``` java Sample job test
import static com.theladders.AssertsBuilder.*;

...

JobRepresentation job = apiCallToGetJob();
thenThe(job).hasTitleOf(“Software Engineer”);
thenThe(job).hasLikeLink();
```

We’re not there yet, but we’re making progress.  So far we have the following:

* Class for representing incoming/outgoing bodies of JSON
* Class for performing assertions against a particular body of JSON
* Some syntactic sugar for creating assert-related objects.

The next piece of the puzzle is a class representing the actions that can be taken on a body of JSON.

## Class representing the actions that can be taken on a body of JSON
What exactly do I mean by "taking actions on a body of JSON".  "Actions" can include anything from selecting an individual item in a list (a job in a list of jobs) to calling a URL associated with a hypermedia link.  So why the need for a separate class encapsulating these "actions" when we already have a representation class for a body of JSON (which includes hypermedia links)?  The reason is rooted in the fact that our representation classes are used in production code for serialization purposes (a topic worthy of its own blog post), and I didn't want to mix in testing concerns with our representation classes for something like calling the API via TestRestClient.  So I decided to create a different type of class for this purpose.  I called this the "actions" class.  

Let's take a look at JSON containing a list of jobs as an example.  If a user is viewing a list of jobs, it's reasonable to expect they might want to "do something" with a particular job.  This would be captured with something like the following:

``` java JobListActions.java
public class JobListActions
{
  public UserAndClient userAndClient; // this class represents a user and their connection to the API and will be discussed next.
  public JobListRepresentation representation;

  ...

  public JobActions actingOnJobAtIndex(int index)
  {
    return new JobActions(userAndClient, representation.jobs.get(index));
  }
}
```

JobListActions by itself isn’t necessarily interesting, but it does provide a nice way for indicating what job a user is acting upon in a test.  The next code listing is more interesting, providing methods for performing various “actions” an individual job.  

``` java JobActions.java
public class JobActions
{
  private final UserAndClient userAndClient; // this class represents a user and their connection to the API and will be discussed next
  private final JobRepresentation representation;

  ...

  public Response<JobRepresentation> like()
  {
    Optional<HypermediaLink> link = representation.likeLink();
    return new Response<>(userAndClient.client.post(link.get()), JobRepresentation.class);
  }

  public Response<JobRepresentation> unlike()
  {
    Optional<HypermediaLink> link = representation.unlikeLink();
    return new Response<>(userAndClient.client.post(link.get()), JobRepresentation.class);
  }
}
```

This class contains methods for liking and un-liking a job.  This is done by using the TestRestClient found in UserAndClient (more on this next) to make calls to the API via the hypermedia links.  The Response class that is returned from these methods is a simple wrapper class for a JAX-RS response and looks like the following:

``` java Response.java
public class Response<T>
{
  private final javax.ws.rs.core.Response response;
  private final Class<T> responseBodyType;

  ...

  public int status()
  {
    return response.getStatus();
  }

  public T body()
  {
    return response.readEntity(responseBodyType);
  }
}
```

So we have all of these separate pieces:  1) representation class, 2) representation asserts class, and 3) class for performing actions against a representation.  By themselves, these three pieces really aren’t that useful.  We need something to pull them together.  This is where the UserAndClient alluded to earlier comes in. 

## Class representing a user, their state, and their “connection” to the API
This class is used for encapsulating a user and how they make calls to the API.  State for a particular user is kept here.  This class acts as the launching point for navigating through the API.  The code in the following listing provides methods for viewing job matches and being able to act upon the viewed job matches.

``` java UserAndClient.java
public class UserAndClient
{
  public AuthenticatedUserRepresentation user;
  public TestRestClient client;

  ...

  public JobListRepresentation jobMatches;

  ...

  public JobListRepresentation viewsJobMatches()
  {
    HypermediaLink link = user.jobMatchesLink();
    jobMatches = client.post(link).readEntity(JobListRepresentation.class);
    return jobMatches;
  }

  public JobListActions actingOn(JobListRepresentation representation)
  {
    return new JobListAction(this, representation);
  }

  ...
}
```

With some additional syntactic sugar, we are able to use UserAndClient to write very expressive tests with decoupled and reusable components.  Our base test class provides this syntactic sugar:

``` java RegisteredUserWebTest.java
public class RegisteredUserWebTest extends WebTest
{
  protected UserAndClient me;

  @Before
  public void setUp()
  {
    me = createNewUserAndClient();
  }

  ...

  public UserAndClient given(UserAndClient userAndClient)
  {
    return userAndClient;
  }

  public UserAndClient when(UserAndClient userAndClient)
  {
    return userAndClient;
  }
}
```

We are then able to put it all together in a test such as the following:

``` java LikeJobWebTest.java
public class LikeJobWebTest extends RegisteredUserWebTest
{
  @Test
  public void likingJobReturnsResultWithUnlikeLink()
  {
    given(me).viewsJobMatches();
    Response<JobRepresentation> response = when(me).actingOn(me.jobMatches)
                                                   .actingOnJobAtIndex(0)
                                                   .like();
    thenThe(response).hasStatusOfOk();

    JobRepresentation job = response.body();
    thenThe(job).doesNotHaveLikeLink();
    thenThe(job).hasUnlikeLink();
  }
}
```

Looking at the above test, it’s pretty clear what is happening.  A user views their job matches.  From there, they like a single job in the list.  We are then verifying that the response of that like contains JSON without a like link (so they cannot “like” a job two times in a row).

# Conclusion
Overall the results have been positive.  We have fairly reusable test code that minimizes duplication.  At first glance it may seem like a lot of unnecessary classes (representation asserts & a class for encapsulating “actions”).  But creating these classes forces us to really think about the API as we develop.  An “asserts” class forces us to zero in on the needs of the client.  The “actions” class gives us a feel for whether or not we are providing the best API in terms of hypermedia links and navigating between URLs.

At the end of the day, we wanted something that would result in an API that met the needs of it’s customer (the iOS client), and I think we’ve achieved that.  By “eating our own dog food” via navigating the hypermedia links in our web tests, we are putting ourselves in the shoes of the iOS client, and the result has been increased test coverage with tests that are easy to extend and understand.

Hopefully you have found this useful.  I realize I've glossed over some of the finer details, such as "what is actually inside of the TestRestClient" class?  This blog post wasn't meant to give you the exact template for doing what we do here at TheLadders.  It was meant to get you thinking about how you are testing your APIs and possible ways to improve upon how that is done.  I'm sure what we have today will look much different six months for now.  While not perfect, it has resulted in what I think are more stable APIs, and at the end of the day, that's a win in my book.

Now time to go test that new Storm topology of mine in production and see if it works...
