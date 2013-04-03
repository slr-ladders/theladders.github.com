---
author: Christina Kung
layout: post
title: "Responsive Design: Keeping our thick client skinny"
date: 2013-04-08 15:43
comments: true
categories: responsive design, frontend, media query, mobile, mobile first
published: false
---

_An article describing TheLadders approach to responsive design._

You may or may not have noticed, but TheLadders.com just got a huge make over. We rewrote the website in six months, putting it through a diet and a facelift. The team cut out excess network calories, trimmed DOM fat, and ironed out sloppy CSS wrinkles. We started 2013 with a shiny new single-page thick web client that is not only faster and cleaner, but uses some pretty provocative polishes like backbone.js, require.js, and SASS with Compass. But my favorite part: it’s responsive and looks great no matter where it goes.    
iPhone? Check. iPad? Check. MacBook Air? Check. Ginormous iMac screen? Check. 

Making TheLadders.com responsive is a driving practice to keep our thick client light and looking good.

{% imgcap left small /images/responsive/ladders-wide.jpeg New theladders.com on a desktop screen with the wide experience %}

{% imgcap left small /images/responsive/ladders-skinny.png New theladders.com on mobile with the skinny experience. Left: main content screen, right: [off canvas](http://jasonweaver.name/lab/offcanvas/) sidebar%}

  
##Adapt to survive
<p style="color:#666666; font-size:.85em">>> A lot of times you hear “adaptive design” instead of “responsive design” because the screen actually adapts to the screen size and magnification level. It has nothing to do with browser performance.</p>

{% imgcap left small /images/responsive/messy-windows.jpg Look familiar? Users will squish, stretch, enlarge, and shrink their windows. Responsive design is not just for mobile devices, it’s for the wild jungle of user behavior out there.%} 
Mobile is here, and has been for years. It is only a matter of time before we are forced to adapt the frontend code design in order to survive on all screens. To me, responsive design is not an option; it’s mandatory.

Its not just about fitting inside of a phone screen either. Our site should be flexible and sturdy enough to undergo all sorts crazy behavior: windows shrinking, windows expanding, zoom in, zoom out, so forth. It’s a wilderness of user actions with legions of new mobile devices to support ... how the heck do we keep up?

##One size fits most
TheLadders’ responsive support subscribes to the majority rule. We prioritize the user experience for the majority, and the edge cases are “overlooked.” This means the website is not tested on every phone and tablet - even newer ones - because there isn’t enough site traffic. We sacrificed this level of precision hoping to concentrate instead on improving the experience for the majority.   
{% imgcap right extra-small /images/responsive/device-breakdown.jpeg Google Analytics device breakdown. Blue - iPhone, Green - iPad, Gray - undetermined. Other slivers are mostly Samsung android devices. %}

**First**, we decided what we were going to support - devices and screen size ranges.  

* Devices 
  * iPhone 4S and up (incl. iPad mini)
  * iPad 2 and up  
* Screen size ranges
  * 20em(320px) to 48em(768px) for skinny experience support
  * 50em(800px) and up for wide experience support

Together these apple devices compose approximately 17% of our total page visits (includes hits from both browsers and devices). Of course you should look at your own device and browser breakdowns before deciding on a strategy. But do it early, otherwise you will be spending a lot of time debugging for ~1% of your users.

**Second**, we decided our limitations. I think this saved hours of designer/developer time by acknowledging that not everything will interact exactly as it would on a 1024px desktop screen.

* Can’t support every mobile device and every screen width.
* Can’t have 100% feature parity between a mobile device and a desktop browser.  (For example, no file upload on mobile)
* Support for hand gesture motions (like swipe) costs extra code.
* Modals are not small screen friendly. (Especially certain date pickers)
* Hover states will be awkward on a touch screen. (If there is a hover state, the first tap is hover and the second tap is click)
* Performance will suffer on mobile connections.

**Third**, we decided what techniques to use. Truthfully, each of these points needs it’s own blog topic, but here’s a quick list for now.

* [Off canvas](http://jasonweaver.name/lab/offcanvas) layout for our “skinny” experience
* [Media queries](https://developer.mozilla.org/en-US/docs/CSS/Media_queries) to trigger the skinny vs wide experience. Used SASS to implement [reusable media query break points](http://thesassway.com/intermediate/responsive-web-design-in-sass-using-media-queries-in-sass-32), making our lives MUCH easier.
* Set [width=device-width](https://developer.mozilla.org/en-US/docs/Mobile/Viewport_meta_tag) in viewport metatag.
* [Elastic layout](http://css-tricks.com/examples/PerfectFluidWidthLayout) for widths.  Use % widths to create a fluid main content area, and a fixed width for the sidebar area.
* Use em. First [understand](http://css-tricks.com/css-font-size) what measurement units are out there. There are many reasons to use em, but [this article](http://blog.cloudfour.com/the-ems-have-it-proportional-media-queries-ftw) made the best case.
* SVG for responsive images.  We choose to use SVG logos and icons that fall back to a png sprite if SVG is not supported.

Now we should never, ever see a horizontal scroll bar. Scrollbars mean users can’t easily see precious content and get a unfulfilling experience.

{% imgcap center medium /images/responsive/sad-scrollbar.png Ewww horizontal scrollbar %}

##Mobile First?
<p style="color:#666666; font-size:.85em">>> Mobile first means to implement your website for mobile devices first, and desktop etc second. It helps set boundaries for page weight and complicated layouts that are unfriendly to handhelds.</p>

In theory, mobile first for design and development process is a good idea.  It’s a surefire way to keep your pages as lightweight as possible. But in practice, our designer created mobile designs simultaneously with desktop designs remembering to remove superfluous visual elements, ensuring a similar design would work for a small screen. As for development, we coded for the desktop first because we still support IE8 (IE8 doesn’t support media queries).  We built a desktop version first and used media queries to adjust for the mobile version. This way, IE8 screens work without extra media queries. Only mobile and latest browsers are responsible for triggering media queries. 

So we aren’t really mobile first, but it heavily influences how we design the site. This practice works well if the designs are clean, and you are innately stingy with markup.

##Anyway …
{% imgcap right extra-small /images/responsive/rabbit-pair.jpg Collaborating like arctic hares %}
My favorite side effect of going responsive is the close collaboration between designers and developers. It’s hard to articulate screen reactions and device behavior through design comps. During this rewrite our front-end team and design team were pairing regularly throughout the day to determine what responsive meant for TheLadders.

Also, it is important to recognize a responsive website is NOT a substitute for a native phone application.  A browser page and native phone application have completely different rules of conduct, so just because your website is responsive doesn’t mean you don’t need a native application.

##Results
Our new responsive website is still young, it was only released earlier this year. We’ve just begun to throw serious traffic at it, but I’m confident that it performs and looks better than the old, non-responsive site. We are closely monitoring customer satisfaction and page visits from mobile devices. Hopefully in a couple months we’ll have flattering statistics and feedback to post.

Until then, check it out for yourself: www.theladders.com. Hopefully you get funneled into the new responsive layout and have fun watching the site adapt to different window sizes. fREE TRIAL PLACEHOLDER

