---
author: Eric Feder
layout: post
title: "Speeding Up R"
date: 2014-10-02 14:51:51 -0400
categories: [Data Science]  
published: true
---
If you ever speak to a data scientist about what tools they use, you’re sure to hear a whole slew of complaints about how slow R can be. R is a programming language used for data processing, analysis, model building, and data visualization. It isn’t really designed for speed and most statistics courses don’t spend much time teaching students how to make their code run quicker.

A few months ago, we encountered this issue directly. We started working on an algorithm that would analyze any one of our six million jobseekers and find other jobseekers that they’re most similar to. To come up with this list, we’d look through several of the data points we had about the jobseeker, such as their career history and which jobs on our site they had been interested in, and looked for other members who had a similar set of data points. Our first pass at this algorithm in R took about thirty seconds to run for each jobseeker. If we wanted to run it for all six million of our users… well, we couldn’t really wait until 2019 to see the results. We’ve spent the subsequent few weeks speeding up the process so that it now takes less than half a second per jobseeker, and we’ve learned a bunch of helpful tips along the way.

(Note: Whenever I need to speed up my code, I look back at Hadley Wickham’s [Advanced R](http://adv-r.had.co.nz/Performance.html) which is where a lot of these ideas come from and is a fantastic resource.)

### 1. Use lineprof to find the bottleneck
Hadley Wickham created a [useful and easy to use package](https://github.com/hadley/lineprof) that you can use to figure out which part of your code is causing the biggest issues and drill down to the specific lines that are taking up most of the runtime. Figuring out which parts of your code are problematic is the first step towards fixing that problem.

### 2. Attack the slowest cases, but don’t forget about the rest
After making some improvements, we found that our algorithm could take anywhere between 0.5 and 6 seconds to run on a jobseeker. For the next iteration, we focused on the slowest 10% and tried to speed each of them up by 1-2 seconds. We repeated this process a few more times, taking a look at the slowest cases and seeing if we could make some big improvements there. However, we also stumbled on an easier but equally effective approach: making small improvements that impact all cases. Speeding up the process by 0.2 seconds for all jobseekers has the same impact of cutting off 2 seconds from just 10% of jobseekers and may be easier to do.

### 3. Using data.table can speed up almost any merge or aggregation
Our algorithm requires merging together a bunch of big data frames (for example, ones covering hundreds of thousands of user clicks or job applications) so we quickly searched for a package that could speed things up. We found the [data.table package](http://datatable.r-forge.r-project.org/) which was orders of magnitude quicker than the base merge in some cases. However, we realized that there was no reason to limit our use of data.table as speed improvements could be found even on merges of much smaller data frames. Furthermore, any time we needed to run an aggregation over a data frame (usually done with aggregate or tapply), data.table could cut out valuable milliseconds.

### 4. Use microbenchmark to rigorously test out your code
The [microbenchmark package](http://cran.r-project.org/web/packages/microbenchmark/index.html) is a far better way to test your R code’s speed than the standard system.time function. Microbenchmark runs each line of code you give it 100 times (by default) and computes summary statistics of those runtimes, allowing you to be confident that any speed improvements you find are not merely the result of random variation.

### 5. Don’t overfit to a single case
Good data scientists are cognizant of the tradeoff between training error and test error when building a model. A similar phenomenon can occur when trying to optimize an algorithm for speed. As we were refining our code, we typically tested things out on our own accounts. However, this was a bit dangerous, since we are by no means a representative sample of users of our site. We are unusually active on the site and all have somewhat similar career histories to each other. A change that improves runtime when generating matches for one of us may not have the same impact on users who are less active or belong to a different job function. Make sure to test out any changes on a large, random sample before concluding that your changes have done the trick.

### 6. The clearest code is not always the fastest code
Imagine you have a data frame that’s 100,000 rows long where the head looks like this:
```
> head(my.df, 10)
           a         b         c         d
1         NA        NA 0.4885687        NA
2         NA        NA 0.1666159        NA
3         NA        NA 0.3176160        NA
4         NA 0.9568433 0.4848375        NA
5  0.8441578 0.3022814        NA        NA
6  0.4223605        NA        NA        NA
7         NA 0.7998102        NA        NA
8         NA 0.8183823        NA        NA
9         NA        NA        NA 0.1550433
10 0.1511128 0.4783680        NA        NA
```
Let’s say what you want to do is replace all of the NA’s with 0’s. So a pretty straightforward function to use would be defined as:
```
replaceNA <- function(df){
  df[is.na(df)] <- 0
  return(df)
}
```
That’s concise, easy to understand, and flexible enough to handle most changes that could occur to my.df in the future. Now, take a look at this function:
```
replaceNAUgly <- function(df){
  df$a[is.na(df$a)] <- 0
  df$b[is.na(df$b)] <- 0
  df$c[is.na(df$c)] <- 0
  df$d[is.na(df$d)] <- 0
  return(df)
}
```
It’s not concise, is a little difficult to understand, and is not very flexible, but it’s actually quite a bit quicker:
```
> microbenchmark(
+   replaceNA(my.df),
+   replaceNAUgly(my.df)
+ )
Unit: milliseconds
                           min       lq   median       uq      max neval
     replaceNA(my.df) 219.7503 241.4529 249.8200 271.3922 316.8102   100
 replaceNAUgly(my.df) 148.9356 159.6738 167.7006 178.1716 234.8962   100
```

In the majority of cases, the first function is fine or even preferable. However, if speed is your only concern, you may be able to speed things up if you’re willing to forgo having pretty code.

### 7. Think about applying some filters
We categorize each of our jobseekers into one of fourteen overarching job functions, such as sales, marketing, technology, or finance. If I’m a software engineer, almost all of the jobseekers who are similar to me are likely to belong in technology. Sure, we could think of some cases where someone shares attributes with people in a couple of different job functions, but this is more of an edge case. By comparing each jobseeker with the half-million other jobseekers in their job function instead of the entire set of six million, we could make the algorithm about ten times faster while still capturing the vast majority of the same results, a tradeoff we deemed totally acceptable.

### 8. Preprocess, preprocess, preprocess
One of the steps in our algorithm is to compare the set of titles a jobseeker has had in his/her career with the sets for all other jobseekers. However, sometimes two jobseekers will have had the same title but used different punctuation or capitalization when entering their title (not to mention misspellings or synonyms). As a result, we needed to remove the case and punctuation from each title before a comparison could be done. Our initial instinct was to run this text cleaning process right before doing the comparison, but this meant that we would end up cleaning the same text hundreds of times. Instead, we cleaned all the titles once, stored the results, and did the comparisons on these cleaned titles. You should constantly be on the lookout for places where the algorithm repeats a step multiple times and see if there’s a way to do so just once and then just look up those results when needed.

### 9. Rcpp for when you’re really stuck
If you’ve narrowed down your issue to a single operation and you can’t find a way around it, the [Rcpp package](http://dirk.eddelbuettel.com/code/rcpp.html) may be able to help. With Rcpp, you can run parts of your code in C++ without interrupting the flow of the rest of your code. There’s a bit of a learning curve if you’re not familiar with C++, but the improvements could be massive enough to justify the effort. Alternatively, with some diligent Googling, you may be able to find someone who’s already solved your problem using Rcpp.

### 10. Parallelize!
For R users who have never done any sort of parallel computing before, this may seem a bit daunting. However, depending on how your code is structured, it can actually be quite trivial to run tasks on all the cores of your machine in parallel. For instance, if you’re using Linux or a Mac and part of your code is run using lapply, forcing it to run in parallel is as simple as loading the parallel package and replacing lapply with mclapply (i.e. multicore lapply). Parallelization doesn’t guarantee speed improvements, but testing it out shouldn’t require too much effort and is worth considering.

Along the same lines, you can force R to utilize all the cores of your machine when doing any linear algebra operations by using OpenBLAS or ATLAS, though the process of getting it up and running is not as easy. [Nathan VanHoudnos' blog post on the topic](http://www.stat.cmu.edu/~nmv/2013/07/09/for-faster-r-use-openblas-instead-better-than-atlas-trivial-to-switch-to-on-ubuntu/) is a good place to start.

### 11. Make sure this is all worth it
While speeding things up is always a good idea, make sure you’re not spending hours of work to just speed things up by a few minutes total. Your time is better spent doing some actual analysis or model building. If this means that you need to let something run in the background of your computer while you do other stuff (or even that it needs to run overnight), so be it.