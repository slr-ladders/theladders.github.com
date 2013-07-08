---
author: Daniel Wislocki
layout: post
title: "Getting Some Clojure: nREPL in a Spring App"
date: 2013-04-02 16:04
comments: true
categories: Clojure Spring
published: true
---
{% blockquote --Zig Ziglar %}
You don't have to be great to start, but you have to start to be great.
{% endblockquote %}

Despite having read through the
[several](http://www.amazon.com/The-Joy-Clojure-Thinking-Way/dp/1935182641/)
[Clojure](http://www.amazon.com/Clojure-Action-Amit-Rathore/dp/1935182595/)
[books](http://www.amazon.com/Programming-Clojure-Pragmatic-Programmers-Halloway/dp/1934356336/)
on my shelf and having played around with
[4Clojure](http://www.4clojure.com/) (user “wislocki”, ranked 2309th
the last time I checked), I’m not feeling much confidence with the
language yet. We use embedded [Jetty](http://www.eclipse.org/jetty/)
to run the website on personal development machines, and I figured it
would be great to be able to play with it interactively in a Clojure
[REPL](http://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop)
and get some more hands-on experience.

Practically speaking, since the website is a Java application, a Scala
REPL might make more sense, bridging the gap between the
object-oriented and functional styles more smoothly. But this is a
Clojure-learning exercise, after all.

We’re using
[Spring 3.1.x](http://www.springsource.org/spring-framework), and I
initially looked to see if there was any precedence for combining a
Clojure REPL with Spring. The links I found were mostly out of date or
not relevant.

I decided that I would use
[nREPL](https://github.com/clojure/tools.nrepl), since the
alternative, [Swank](https://github.com/technomancy/swank-clojure), is
no longer maintained. As we’re using
[Spring’s Java configuration system](http://static.springsource.org/spring/docs/3.1.x/spring-framework-reference/html/beans.html#beans-java),
it would have to be started up there. That’s actually pretty
straightforward. Using
[code](https://github.com/clojure/tools.nrepl#embedding-nrepl-starting-a-server)
from the nREPL README to start the server, I created the following
Spring configuration class:

``` java
package com.theladders.lw.config;

import java.io.StringReader;

import javax.annotation.PostConstruct;
import javax.inject.Inject;

import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Configuration;

import clojure.lang.Compiler;
import clojure.lang.RT;

@Configuration
public class NReplConfig
{
  // Clojure code to start the server. If you wanted to, you could probably move the port value
  // into a Java properties file, and use the @Value annotation to provide it instead.

  private static final String NREPL_INIT = "(use '[clojure.tools.nrepl.server :only (start-server stop-server)]) " + 
                                           "(start-server :port 7888)";

  @Inject
  private ApplicationContext  context;

  // Annotated with @PostConstruct so that this method is run after the object is instantiated and 
  // any other dependency injection has taken place.

  @PostConstruct
  public void initializeRepl()
  {
    // Load the Clojure Runtime class so that the Compiler can properly use it.

    Class.forName("clojure.lang.RT");

    // Start the nREPL server.

    Compiler.load(new StringReader(NREPL_INIT));

    // Make the Spring context available in the "lw" namespace.

    RT.var("lw", "*context*", context);
  }
}
```

(Thanks to [Laurent Petit](https://twitter.com/petitlaurent) of
[counterclockwise](https://code.google.com/p/counterclockwise/)-fame
for recommending the above class-loading strategy, as well as the the
suggestion to replace the use of `(ns lw)` with `(in-ns 'lw)` in the
REPL example below.)

With this file in place, running `mvn jetty:run` starts up both the
web server and nREPL. While I could have used
[Leiningen](https://github.com/technomancy/leiningen) to connect the
REPL, I decided to use [emacs](http://www.gnu.org/software/emacs/)
instead. If you’re using [Bozhidar Batsov](http://batsov.com/)’s
[Prelude configuration](https://github.com/bbatsov/prelude), you
already have support for nREPL installed, otherwise you can get it
through [MELPA](http://melpa.milkbox.net/) or
[Marmalade](http://marmalade-repo.org/) or directly
[here](https://github.com/kingtim/nrepl.el). After a quick `M-x
nrepl`, I can interact with the running server like so:

```
; nREPL 0.1.7-preview
user> (in-ns 'lw)
#<Namespace lw>
lw> *context*
#<AnnotationConfigWebApplicationContext Root WebApplicationContext: startup date [Thu Mar 28 16:25:12 EDT 2013]; root of context hierarchy>
lw> (def jss (.getBean *context* getBean "jobseekerService"))
#'lw/jss
lw> jss
#<JobseekerService com.theladders.lw.jobseeker.service.JobseekerService@1f4e3b7c>
lw> (def jsid (com.theladders.lw.jobseeker.model.JobseekerId. 7906538))
#'lw/jsid
lw> (.get jss jsid)
#<Jobseeker com.theladders.lw.jobseeker.model.Jobseeker@5dfcb9fd>
lw> (.getFirstName (.get jss jsid))
"Daniel"
lw> 
```

Pretty straightforward!

The additions to the `pom.xml` file that enable nREPL support are below:


``` xml
<repositories>
...
    <!-- The following gives us access to Clojure libraries like clojure-complete. -->
    <repository>
        <id>clojars.org</id>
        <url>http://clojars.org/repo</url>
    </repository>
...
</repositories> 
<dependencies>
...
    <!-- Clojure-complete enables tab-completion in the REPL. -->
    <dependency>
        <groupId>clojure-complete</groupId>
        <artifactId>clojure-complete</artifactId>
        <version>0.2.3</version>
    </dependency>
    <dependency>
        <groupId>org.clojure</groupId>
        <artifactId>clojure</artifactId>
        <version>1.5.0</version>
    </dependency>
    <dependency>
        <groupId>org.clojure</groupId>
        <artifactId>tools.nrepl</artifactId>
        <version>0.2.2</version>
    </dependency>
...
</dependencies>
```

I hope you found this brief write-up useful. I plan on continuing my stumbling exploration, so look for other Clojure-related posts soon.

Join the discussion over on [reddit](http://www.reddit.com/r/programming/comments/1bjh69/getting_some_clojure_nrepl_in_a_spring_app/).

*April 8th, 2013: Edited in response to suggestions from Laurent Petit.*
