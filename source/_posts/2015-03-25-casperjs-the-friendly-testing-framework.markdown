---
author: 
layout: post
title: "CasperJS the Friendly Testing Framework"
date: 2015-03-25 12:47
comments: true
author: Jeremy Block
categories: testing, javascript 
published: false
---
{% blockquote -- Person Who Said this %}
The thing that the person said
{% endblockquote%}

When we started our new [job market guide](http://www.theladders.com/careers/search) 
project (a site where career-minded professionals can check out open positions
and stats such as average compensation), the question of testing came up pretty
quickly. We had used [Jasmine](http://jasmine.github.io/) for 
JavaScript unit testing on a previous project so we kept using it, but it wasn't enough.
Our Jasmine tests could pass, but the site might not actually work. We needed
end-to-end tests.

One of the new tools we found was [CasperJS](http://casperjs.org/). It's a neat
JavaScript project that uses [PhantomJS](http://phantomjs.org/) to open a headless
browser, go to your site, take some actions and then make assertions. We're using
CasperJS for end-to-end testing and we're automating the test runs with 
[Grunt](http://gruntjs.com/).

Here's a snippet of a test for our 'share' feature:
``` javascript
function emailCaptureTopFormTest() {
    casper.then(givenCareersPage);
    casper.then(whenEmailFormIsFilledOut);
    casper.then(thenConfirmationIsShow);
}

function givenCareersPage() {
    casper.open(DOMAIN + 'careers/NY/sales/1');
}

function whenEmailFormIsFilledOut() {
    casper.click('[data-js="email-capture__top-link-test"]');
    casper.sendKeys(topFormInputSelector, 'jblocktest' + new Date().getTime() + '@theladders.net');
    casper.click('[data-js="email-capture__top-submit"]');
}

function thenConfirmationIsShown() {
    casper.waituntilVisible('[data-js="email-capture__confirmation"]', 
            util.success("email confirmation ok"),
            util.failWithScreenshot("email-confirmation-fail", 
                                    "email confirmation didn't appear", 
                                    SCREENSHOT_OPTIONS));
}
```  

The test opens up the page, fills out the form, and makes sure the confirmation 
window appears. If it doesn't appear, the test takes a screenshot and reports a failure.

The tests are generally pretty fast. We use Grunt to kick off the test suites 
so that all you need to do to run them is type `grunt test`. (That's a lot
easier to remember than `casperjs --ssl-protocol=any --ignore-ssl-errors=true
test path/to/tests`!) Simpler tests are typically less than a second to run,
but there are a few slower tests that rely on external services, which can
take as long as 15 seconds to run. This led to concerns about the test run
time. We want to run the whole suite of tests frequently, but we don't want it
to take a couple of minutes each time.

The solution I went with was running them in parallel. They're all independent
so there's no need for any test to wait for any other test to finish. CasperJS
doesn't officially support parallelization so I jury-riggered something together
with a shell script. It gets each test file, runs them all as background processes
and redirects their output to temporary files. Once that's done, it cats all the 
output in order and then uses `grep` to print failures at the end.

Here's some sample output after the test suite has run:
```bash
Test file: /casper/tests/no_search_results_test.js
# search no results test
PASS no-jobs-search-ok: Saw no jobs container
PASS 1 test executed in 2.227s, 1 passed, 0 failed, 0 dubious, 0 skipped.

Done, without errors.
*********************************

FAIL PremiumSignupTestfail:  Expected pricing form. Didn't see it.  
#    file: /casper/tests/premium_signup_test.js
FAIL 1 test executed in 13.195s, 0 passed, 1 failed, 0 dubious, 0 skipped.

real	0m25.646s
user	1m16.980s
sys	0m7.416s
^ Time it took for this task.
```

I used the `time` command to print out how long the suite takes. It's now
around 25s instead of 90s+. That is, the run time is the slowest test's run
time plus some overhead. That's a big improvement over the sum of all the tests'
 run times!

This was great when we only had a few tests, but as the suite grew larger, I 
noticed the server was starting to struggle. It could handle five connections
 opening at once, but a hundred was causing tests to time out. My solution for
this was to split the tests into smaller batches. Instead of running 100 tests 
all at once and bringing the server down, I can run two sets of 50. It's a 
little slower than it would be if they could all run at once, but it's definitely 
faster than having some tests randomly time out and fail.

Now that the casper tests are quick and easy to run, they're being used more 
frequently and catching errors faster. Some developers are writing casper tests 
before they write the actual code, too. 

While CasperJS is a great tool for testing interactions and catching errors (like 
forms not submitting correctly), it doesn't particularly care about how the page 
looks. The casper tests will happily pass even if no CSS loads on the page. A 
human would obviously see something is broke, but the casper tests won't. We 
wanted to be able to catch problems like that without manually looking at 
every page. Fortunately, there's a tool for that: 
[PhantomCSS](https://github.com/Huddle/PhantomCSS).

PhantomCSS builds on top of CasperJS. It takes screenshots of your 
site and then after you've done work, it takes new screenshots. It then compares 
the two and highlights any changes. This can be incredibly useful. For example, 
suppose you're changing the header on one pager to be centered. If this accidentally 
center headers on other pages, that will show up as a failure in PhantomCSS.

Since PhantomCSS tests run the same way as the casper tests, I was able to use the 
same method to run them in parallel. Like with casper tests, individually they're 
pretty quick, but running them all sequentially can be slow. Running them in 
parallel is a big time saver.

Now that we are using CasperJS and PhantomJS, our confidence when releasing has 
gone way up. We no longer need to manually check styles on every page because 
PhantomCSS will show us every change. We don’t need to click through flows because 
CasperJS does that for us. We've been releasing new bug-free features at a consistent 
rate that wouldn't be possible if we were still manually testing.

