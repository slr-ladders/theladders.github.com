---
author: Chris Schillinger
layout: post
title: "Visual State Testing With Mock Data"
date: 2015-07-31 10:00
comments: true
categories: Testing Architecture
published: false
---
{% blockquote --James Bach %}
Testing is organized skepticism.
{% endblockquote %}

# The problem

[{% img right /images/visual-state-testing-with-mock-data/companies-production-small.jpg Companies Pages %}](https://www.theladders.com/companies/TheLadders/)

Here at TheLadders we’ve been working on building new pages designed to provide job seekers access to data we’ve been able to collect over the years in new and interesting ways. These pages are static in design, but the amount of data available for each page can vary widely. This means we have a wide range of visual states for every element on these pages. Compounding the problem are occasional elements which impact the layout of their neighbors depending on their own state. All this brought us to a very clear need to test these visual states in an automated way.

## Requirements

We wanted to cover all of our visual states. This meant we needed to make creating state combinations easy. Covering all of our states lets us add new elements to existing pages without worrying about breaking existing layouts. It also lets us modify shared styles and scripts without worrying about breaking layouts already using them.

We wanted to make sure these tests were automated and reproducible. They needed to integrate into our development, QA and release process. Developers shouldn’t have to worry about remembering to run tests. We’ve written about how we accomplish this before with our friendly testing framework.

We wanted to minimize dependencies on services or data outside of our code. Tests shouldn’t force developers to jump through additional hoops in order for the tests to run. We can’t let internal network or DB issues stop development. And we can’t let code and data get out of sync for automated tests.
  
  
****
  
# Our Solution

## URL Parameters 

To meet all of these requirements we use a set of optional URL parameters to force our server to generate mock data to exercise all of the UI elements on a given page. This lets us quickly define full page tests with different combinations of parameters to generate any and all possible states. These parameters are only respected in local and QA environments to keep our production site clean.

#### Example URLs:

For our companies pages, we expose the following parameters:
```
mockData : should the server return real or mock data?
detailLevel : controls the mock basic details data (description, location, details, etc)
salaryPoints : controls how many mock salary points to return
similarCompanies : controls how many mock similar company entries to return
```

Parameters generally limit their options to meaningful data densities. E.G. “full”, “minimal”, “empty”. This decouples the test code from the page layout details.

To force a layout where we have only limited data for a page, the company URL would look something like:
```
https://qa-1/companies/company-name/?mockData=true&detailLevel=sparse&salaryPoints=none&similarCompanies=minimal
```

And results in a page which looks like:
[{% img center /images/visual-state-testing-with-mock-data/sparse-mock-data-small.jpg Sparse Data %}](/images/visual-state-testing-with-mock-data/sparse-mock-data.jpg)

And to force a layout with lots of details and available data:
```
https://qa-1/companies/company-name/?mockData=true&detailLevel=verbose&salaryPoints=full&similarCompanies=extra
```

Resulting in a page like:
[{% img center /images/visual-state-testing-with-mock-data/full-mock-data-small.jpg Sparse Data %}](/images/visual-state-testing-with-mock-data/full-mock-data.jpg)

In order to test as much of the stack as we can and increase our test coverage for free, these parameters are passed all the way to the point in the code where we query our data stores, at which point the code simply has to check the flags to determine which data store, real or mock, to retrieve data from. This also means that the only code which has to change is the data retrieval code. No other server code and no client code has to worry about where the data is coming from. As long as it’s in the same format, they handle it just like real data from our data stores.

## The Mock Data

Once we had defined how we were going to request mock data, we had to decide how to define it. The brute force approach of forcing developers to hand-code all desired variations wasn’t acceptable. This would have been a burden on developers and the end result would have been brittle. Any future updates to the data models would have forced developers to go back and update all of the previously defined mock data.

Our approach is to randomly generate all mock data. This way developers only have to define a generation function once per data point and then simply generate as many instances of those data points as are requested. This makes it much easier to cover all data states and eliminates hand coded data as long as you provide re-usable utility methods for string fields like names and titles.

## The Code

For these newer pages our server code is written entirely in Scala with Spring bindings.

Example entry point code:
``` scala Example entry point code
  @RequestMapping(Array("/companies/{companyName}"))
  def companyPage(@PathVariable companyName: String,
                  @RequestParam(defaultValue = "false") useMockData: Boolean,
                  @RequestParam(defaultValue = "full") mockDetailLevel: String,
                  @RequestParam(defaultValue = "full") mockSalaryPoints: String,
                  @RequestParam(defaultValue = "full") mockSimilarCompanies: String ): Any = {

    val request = CompanyRequest(companyName,
                                 useMockData && Environment.current != Prod,
                                 mockDetailLevel,
                                 mockSalaryPoints,
                                 mockSimilarCompanies)

    val result = doCompanyQuery(request)
    
    buildView(result)
  }
```

Example data query code:
``` scala Example data query code
  def querySimilarCompanies(request: CompanyRequest): Seq[SimilarCompany] = {
      if (request.useMockData) MockData.similarCompanies(request.mockSimilarCompanies)
      else realSearchGateway.similarCompanies(request.companyName)
  }
  
  def similarCompanies(switch: String): Seq[SimilarCompany] = match switch {
    case "minimal"  => buildSimilarCompanies(5)
    case "full"     => buildSimilarCompanies(24)
    case "extra"    => buildSimilarCompanies(100)
    case _ | "none" => Seq.empty
  }
```

Example mock data generation code:
``` scala Example mock data generation code
  private final val BUILD_SIMILAR_SEED = 9284756

  def buildSimilarCompanies(count: Int): Seq[SimilarCompany] = {
    val rng = new Random(BUILD_SIMILAR_SEED)
    for (i <- 1 to count) yield {
      SimilarCompany(name = getRandomCompanyName(rng),
                     similarity = rng.nextFloat,
                     openJobs = rng.nextInt(50))
    }
  }
```
  
  
****
  
# Gotchas

There are a few things to look out for with this approach. The first is to make sure the mock data generated is the same every time you run the test. This is as simple as seeding your random number generators and making sure to create them fresh for every request batch. If you don’t seed your random number generator you’ll get different results ever time, and if you don’t create a new seeded generator for each request batch the order of your tests will change what data is actually generated.

With all of this great UI test coverage it’s important not to neglect the code which actually queries the real data stores. Now that most tests never have to hit the data stores, it’s especially important to cover the data query code with their own unit and integration tests.

And finally we’ve found it’s best to have as many query switches as you have stateful elements on your page. This makes it easy to compose and maintain any number of tests from the individual mock data pieces. Most of our mock data generation is extended by our technical QA to help cover all of the UI states. It also lets us easily test components in isolation where necessary.
  
  
****
  
# Conclusion

This approach to testing our visual states with mock data has proven invaluable as we build out more and more information-centric pages. I hope this approach finds a useful place in your arsenal of testing strategies on your current or future projects.
