title: How to Build a Web Crawler
date: "2020-03-06T16:51:00.000Z"
layout: post
draft: false
path: "/posts/how-to-build-a-web-crawler/"
category: "Personal"
tags:
  - "Software"
description: 
---


In an interview I had, I was asked how I would build a web crawler.  I think that this is a really fascinating problem!  There's a lot that goes into it.  How do you build a system that is capable of analyzing millions (if not billions) of web pages?  How do you build something that can not get trapped in bot traps (https://en.wikipedia.org/wiki/Spider_trap).  How do you ensure that the pages you've crawled need to be refreshed?  How do you prioritize which pages to crawl first?  And how do you articulate all of this in 45 minutes with a job offer on the line?

I took some time playing around and built a simple web crawler in Rails.  I will post the link to the Repo once I am done so you can look at it.  Although it is worth noting that my toy crawler is just that; a toy.  I didn't put in considerations to a lot of the issues around scalability that I will talk about in this blog post.  Over time I'd love to improve it to handle scalabiity better (and have unit tests!).  But for now, take it for what it's worth.  Ok, getting started!

When designing a system, or in a systems design interview, I like to fall back on an acronym called RASHDE.  This stands for:

- R: Requirements - What does this system need to do in order for it to be considered working?
- A: API - What are the public interfaces to this system?
- S: Scalability - What is the scale of this problem?  Both in size and time.
- H: High level diagram - Can you draw out a high level architecture of how this system works?
- D: Data Model - What data are we storing?  What type of Database (SQL/NoSQL?).  What would the schema look like?
- E: Expain a component - Can you dive into a specific component and talk about it in more details?

### Requirements
A web crawler can be used for various purposes.  For example, you might want to store all of the MP3s on the internet.  Or maybe you want to crawl through pages to find out of anyone plagarized an essay you wrote.  Or maybe you want to store metadata about various webpages about dogs?

In this example, our goal will be to store text versions of a website in a database.  We want to ensure that all of our webpages are no more than a month stale.  That is, at the most, we want to make sure that we check each website stored in our database at least once a month to see if anything has changed.

We also want to make sure that we're being polite and not hitting a single domain over and over and over.  

### API
In this system design, we won't really be using a public API (will explain below).

### Scalability
There's definitely a few metrics we need to estimate to keep scalability in mind.  According to Internet Live Stats (https://www.internetlivestats.com/), as of 2/28/20, there are 1.7 billion websites.  We can estmate that each of those websites contains say, 100 pages.  And each page contains 100kb.  This means, our goal is to archive 170 billion pages, requiring 20400 terabytes of storage.  As we can see, there is a lot of volume that this system needs to account for!

### High Level Diagram
This is where we get to the fun stuff!  We can now start talking about how we would implement our web crawler.  You can see my high level diagram below:

![alt text](https://i.ibb.co/MpXXQkL/Screen-Shot-2020-02-28-at-9-40-41-AM.png "Crawler Diagram")


Let's go over how this is working.  How our web crawler works is that it visits a webpage and then stores its content to persistent memory.  It then needs to find all of the URL paths on the web page and recursively visit those web pages, store the content, and find all of the other URLs.  And so on and so on.

We need a place to start.  For us to have a starting point, we pass in a seeds file.  This file contains a list of websites that we want to start the crawler off to.  It could contain, say, `http://en.wikipedia.org/` or any other website that would have a lot of other links to other websites.

We store these initial seed URLS into our URL queue.  This URL queue contains the URLs that we want to visit, download, and parse.  We will want to continue our process of web scraping until this queue is done.  We will want our Queue to implement some sort of priority - that is, we want to visit websites that are more often updated first.  This will be discussed further down the line as we examine a specific component.

We have another component called a Crawler Service.  A Crawler Service is doing all of the magic of:
- Making a GET request to a web page
- Storing the content of the webpage in persistent storage.
- Finding all of the other URLs in that web page.
- Persist the URL and time processed in the cache.

The Web Crawler interfaces with the DNS Resolver to visit web pages.  We use a custom DNS resolver so that we're not having to go through multiple layers of DNS resolving (e.g. looking at the machine's cache, looking at the internet provider's resolver, etc).  Since we are going to be visiting a lot of websites, this makes it much faster.

You can see that in the diagram, there are multiple squares stacked up on top of each other.  This is representing the fact that each of the services are operating in a paralell manner.  Since we have so many web pages, it simply would not be feasable for us to have one process doing all of these operations.

The crawler service publishes a list of URLs that were found on the page (if there were any) to the response queue.  Our URL processor service is constantly reading off of this queue.

The URL Processor Service reads off collections of URLs.  It does a few things with these URLs.  First, it formats it in a uniform manner (e.g. adding `http://` to the beginning of the url, adding a `/` to the end of a URL).  This will be important so that we are treating say, `google.com` the same way as `www.google.com` and `http://www.google.com/` and so on and so on.

As we talked about, one of the things that we have to worry about is falling into a spider trap.  This would mean that say, if our crawler visited page A, and page A had a link to page B.  Then our crawler visits page B, which has a link back to page A.  This would put us in an endless loop.  That's not good!

To help resolve his, our URL Processor Service checks the cache to see if the URL is in there.  If the URL is in the cache, and it was put in the cache recently (say, within the last 2 hours?), then we don't need to visit it.  Thus, we don't put it in the URL Queue.  Otherwise, we put that URL back in the URL Queue!

The final component is our Refresher Service.  Our refresher service is a worker that is constantly searching through our persistent storage database.  It looks to find webpages in the database that have not been crawled for a while (say, a month).  If it needs to be refreshed, it is pulls the URL out of the record and stores it back in the URL queue.

### Data Model
In our system, we are storing the processed web pages in a persistent storage database.  The way I best imagine doing this is having a Webpage model with a `content` field (storing the HTML of the page), a `url` field, and an `updated_at` field.  In our cache, we are just storing the URL and the time added at.

### Explain a Component
The component that I'll jump into explaining is the URL queue.  You can see a high level diagram below:

![alt text](https://i.ibb.co/9G5rDMy/2-D12-BC66-292-B-4919-9842-2-C4-AE5-EC5135-1.jpg "Crawler Diagram 2")


The goal of the Queue is to add in priority so that we're not just grabbing the first URL that was put into the queue.  We want to do two things.  First, we want to determine which URLs we want to visit first.  There's a few metrics that we can do here.  Google, for example, ranks pages by how many other pages link to it.  That would require building a graph where websites ae nodes, and edges are links to other websites.  We could look in the graph to determine which node in the queue has the most edges to it.  But that's a bit out of the scope of the project.  Instead, what we do is make a HEAD request to each URL and look at the `Last-Modified` header of each response.  We prioritize websites that have been modified earlier than others.  To do this, we can create a series of queues, each representing a time frame.  In this diagram, for example, if a website was last modified two days ago, it would go in the first queue.  

We then have a Backend Queue Service that is responsible for picking the correct queue.  It sends the URL to a Heap.  A heap, also known as a priority queue, is a data structure that ranks objects when added to it.  In this case, our Heap orders URLs by how frequently a specific domain has been processed.  For example, if we had a hundred websites being pushed into our queue from `http://facebook.com`, Facebook URLs would get a lower priority.  The heap would accomplish this by keeping a record of what URls have been hit using a cache.  When a URL is added to the queue, it checks to see if that URL has been processed before.  If it has not, it gets a normal ranking.  However, if it has been processed, it will be given a ranking of how long ago it was visited, and how many times it has been visited.  We can clear out this cache on a regular basis.

So there we have it!  Did I miss anything?  Feel free to contact me if so!
