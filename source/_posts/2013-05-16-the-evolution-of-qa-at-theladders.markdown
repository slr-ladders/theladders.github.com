---
author: Susanne Abdelrahman
layout: post
title: "The Evolution of QA at TheLadders"
date: 2013-05-16 09:04
comments: true
categories: [How we work] 
published: false
---

{% blockquote --Esther Dyson%}
Change means that what was before wasn't perfect. People want things to be better.
{% endblockquote %}

Looking back on my 6+ years at TheLadders, I realize how much has changed. When I first joined the company at the start of 2007, there were five other people on the QA team supporting a team of 12 software developers. We followed a strict waterfall process. Product ideas were generated, researched and solidified before any conversation with the development or QA teams. Product managers would spend a large portion of their time hunkered down at their desks writing specification documents, complete with statements on purpose and scope, workflows, wireframes and interaction rules. 

After these documents were approved by business owners, the development, QA, and design teams would meet to walk through the document with the goal of estimating the implementation time. QA played the role of a customer advocate and tried to ensure that there was as little uncertainty in the documentation as possible. Instead of walking out of the meeting with estimates, the Product Manager would usually leave with a list of missing workflows and use cases that they would need to add to the spec before development began.

Eventually a release date would be set. Spec and design mocks in hand, the development team would start building the feature.  The QA team would write test cases. We created long lists of actions and expected outcomes that we would use to manually test the development team’s work. Test automation - unit, integration, functional, load, et al - was a distant dream. Our primary interaction with the development team was proving the existence of bugs that they couldn’t reproduce.

{% img center /images/the-evolution-of-qa-at-theladders/it-works-on-my-machine.png %}

Even though both the development and QA teams worked off of the same documents, the software never matched the expected behavior according to the test case. Preparing for a release was a never-ending cycle of testing, bug-finding, bug-fixing, and retesting. Fixed release dates and not testing until the end of the development cycle led to releases that were huge events with late, stressful nights leading up to release and late, stressful nights spent cleaning up after it was over! 

Between major releases, QA was either responding to customer issues, estimating how long it would take to test an upcoming project, or maintaining our set of regression test case documents in Excel.

##Fast forward to 2009. 

The development team had grown to 35. The QA team had shrunk to 4. We’d transitioned to Scrum a few months previous and shuffled the production teams around to form 4 cross-functional ones. Each team consisted of developers, a QA lead, a designer, a copy editor, and a product manager. The move to Scrum was bumpy as we molded the framework into a process that worked for us but teams had started to find a groove. Ideas were generated and defined within each team, we were checking in with each other often, and delivering value to our customers faster. The teams were working like well-oiled machines... almost.

Selecting user stories to be undertaken during an iteration had become a team decision, however then the Product Manager and QA rep would work together, without the rest of the team, to define the requirements for each story and flesh them out into use case documents. QA still played the role of customer advocate: working to clearly define expected behavior of each user story in terms of the use case document.

The developers would use these documents to build each user story. Sometimes, they'd also write unit tests to cover a few of the more important use case scenarios. Before a story was considered "done", a code review would need to be completed by at least two developers. In order to make sure that each story met customer expectations, QA would need to manually test the feature. The need for manual testing didn’t end there. At the end of each iteration, QA would run through the entire regression suite before releasing. 

We had made some improvements, but it was clear that we could improve the process if we increased communication of requirements and lessened the amount of manual testing that needed to be done. 

We were releasing every two weeks. They were smaller and less stressful than in the past. QA still spent a lot of time manually testing, but it was done throughout the iteration instead of being squeezed in at the end. This meant that QA had a lot more downtime than before. While some of this time was spent doing the work we had always done, we also made sure to spend time learning about new tools and best practices. Over time, we learned a lot about automated functional testing. We experimented with different frameworks, starting with a simple record-and-playback tool, until we learned more about what we needed and which tools might best fit that need. I’ll write a post later to shed some light on what that journey was like, but suffice it to say that it took quite a bit of trial and error! 

##Fast forward to now.

We've moved beyond Scrum to an adapted Agile process that emphasises cross-functional, independent, and highly collaborative teams. Each team is free to adopt practices that work for them. They have free reign to define the way that they work amongst themselves. There are certain commonalities that hold true across all our teams:

**QA plays the role of customer advocate**. We know our customers well and our applications even better. This gives us a unique perspective when defining new user stories that helps our teams deliver better products for our users. 

**The teams define user stories together**. QA still helps flesh out requirements and acceptance criteria, but with the participation of the rest of the team. Defining requirements as a team helps us make sure that we're all on the same page which in turn helps us work better and faster.

**We aren't heavy-handed with the documentation**. We've found that most of our previous attempts at documentation were wasteful - and often not as useful to the developers as we thought. Instead, after each team conversation around story requirements QA either writes notes and acceptance criteria on the back of the story card (if the team uses a whiteboard to manage their backlog) or in comments attached to the story in Trello.

**We automate tests when it's the smart thing to do**. Manually testing everything definitely was not the best thing for us to do, but [neither is automating every test](http://xkcd.com/1205/). Instead, QA and the developers have frequent conversations around how to appropriately test each user scenario: Can it be sufficiently covered in a unit or integration test? Does it make sense to write an expensive automated functional test that checks the functionality through the browser? How important is this functionality? What's the risk of it breaking? We also keep test coverage at the front of our minds and use different [strategies](http://dev.theladders.com/2013/02/mutation-testing-with-pit-a-step-beyond-normal-code-coverage/) to make sure that we can trust the tests that we do automate.

**Developers write most of our automated tests**. Whether unit, integration, functional, or load tests, usually it's a developer that's going to write it. QA does pitch in when they can but with one QA lead per team, it's not feasible for them to write all of the automated tests without becoming a bottleneck. 

**We peer review code** with QA actively participating.

**We've set up continuous integration builds**. All of our unit-level tests run after each commit and all of our automated functional regression tests must pass before each deployment. If a test fails, we fix it. 

And of course, QA is still responsible for investigating and responding to customer issues. Some things will never change.

We've come a long way! But that doesn't mean that we can't get better. As a wise man* once said, consistency requires you to be as ignorant today as you were a year ago. Here at TheLadders, we're always learning.  

*Bernard Berenson





