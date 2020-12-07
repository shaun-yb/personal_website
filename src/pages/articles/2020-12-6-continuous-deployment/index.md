---
title: From Continuous Integration to Continuous Deployment
date: "2020-12-06"
layout: post
draft: false
path: "/posts/from-continuous-integration-to-continuous-deployment/"
category: "Software Engineering"
tags:
  - "Software Engineering"
description: ""
---

I joke around to my friends that I call the era of YvesBlue before I came on as BS (before Shaun).  ;) Comedy aside, one of the greatest and most rewarding challenges I’ve faced as a lead engineer is smooth lining our deploy and release process.

One of the first things I noticed when I started was several pull requests that had been open for months.  Each feature branch was so far off of the main/master branch that made releases impossible due to some of the nastiest merge conflicts I had seen in my career.  Our database was terribly out of sync with our migrations.  There hadn’t been a release in many weeks.  And to top this all off, my boss was sick from COVID-19.  Talk about a wild first week!

We’ve made tremendous progress since then and are in a much better place.  I give much credit to my colleague Harri (our QA-engineer), and my boss Michael.  Early on, we realized that in order to scale our team and onboard more engineers, we needed to invest time in making sure that there is a well defined and documented set of procedures and workflows that we as developers agree to.

Our goal from all of this was to get from Continuous Integration to Continuous Delivery.  

In respect to Continuous Integration, we set up our Github repository to run our RSpec and Cypress tests whenever a commit is pushed to the corresponding Pull Request.  We also had a solid workflow process of getting code deployed to a staging server for manual QA, and then into production.

But to get to the next step, Continuous Deployment, we had to iterate and recalibrate on our operations.  This was not a democratic process.  Since all of the engineers on our team come from diverse backgrounds, we have many conflicting philosophies to structuring and planning our work.  This created a too-many-cooks-in-the-kitchen scenario.  It became clear that there was no way to make everyone happy with these changes to our processes.

To overcome this, Michael and Harri met 1-1 to write thorough documentation outlining our development operations.  This required a lot of trust in our team - I had to trust that Harri and Micheal have put in the time and due diligence to developing a system that they believed would be the best possible with our limited restraints.


Wikipedia defines “Continuous Deployment” as “a software engineering approach in which teams produce software in short cycles, ensuring that the software can be reliably released at any time and, when releasing the software, doing so manually” (https://en.wikipedia.org/wiki/Continuous_delivery).

Michael and Harri did a great job of analyzing where we have been with Continuous Integration and how we want to get to Continuous Deployment.  Some of the key takeaways were:

### Plan out what work will be in what release

This concept blew my mind away.  In my past engineering environments, we released code whenever we were done with a Pull Request.  There wasn’t much thought about it - you just needed to perform a few manual steps and shabam!  Your code is deployed.

What we are trying to do now at YvesBlue is determine what will be in every release before we start code.  This is helpful for a few reasons:

- It keeps our deploys atomic, cohesive, and self contained.
- It provides a clear set of deliverables to our stakeholders of what they should expect and when.
- We are aware of all of the various simultaneous projects going on at once, so we can address issues where one developer’s code is going to directly interfere with another’s code upfront.

### Optimize pull requests to minimize the amount of time between opening them and merging them into the main (formerly known as master) branch.

A lot goes wrong when pull requests are open for a long time.  Other developers lose context of the work, making reviewing the work difficult.  The code becomes outdated and merge conflicts creep i

A good metric that I like to use is that PR should be reviewed no later than 36 hours from when it is reviewed.  As a lead engineer, one of my biggest responsibilities is getting my team members unstuck.  So this requires me to often put reviewing their work before doing my own work and review PRs in a shorter time frame.  It’s important to not leave your peers waiting.  It is everyone's responsibilities to unblock each other.

### Rebranch often
We have two branches - `main` (which correlates to our development server) and `dev` (which correlates to our staging server).  In June, we began a several month project called Private Equity.  We created a `dev-pe` branch that we used for merging all of our PE work into.

We really messed up with our workflow process here.  We waited several months to merge `dev-pe` into `dev`.  This caused the work between the branches to diverge significantly.  The work in `dev-pe` interfered with the work in `dev` in a manner that we did not anticipate - causing Michael to rewrite a large portion of the system.  Not a fun time at all.  Learn from our mistakes - rebase your branches often and avoid divergent branches like the plague.

Only allow release managers to merge pull requests into the `dev` or `main` branch.
When I first started working at YvesBlue, whenever I got an approval for my code by another developer, I often just merged the code in and closed the pull request.

This made it very challenging for Harri when she would do QA.  She would manually test the site without knowing what was in the `dev` branch that she was testing because I didn’t communicate that with her.

We agreed on a new rule that says only release managers can merge code and close out PRs.  At this point, Harri and Michael are our release managers.  Github has a feature that lets you specifically disable team members’ ability to merge code in.  We don’t use that feature specifically because we trust our developers to respect our defined workflows and we want developers to be able to make hot fixes if a release manager is not available.

### Develop a Git Branching Strategy and Stick to it
It’s not important to define the best way for your team to utilize Git.  It’s important to develop a system that you and your team can consistently use.

Our branching strategy roughly looks like this.  As stated above, we have two branches - a `dev` branch and a `main` branch.  When a developer gets a ticket, they open up a pull request branched off of dev.  Another engineer is then required to approve the code.  Afterwards, the code is marked as ready for QA.  Harri takes this PR, performs manual QA on it, and if things look good - merge it into `dev`.

When Harri is ready to make a release, she opens up a PR to merge `dev` into `main`.  She performs manual QA and runs automated tests to ensure that the release goes good.  If so, she merges `dev` into `main`, and then deploys `main` to our servers (at the time of writing this we’re using Heroku, but we’re in the process of migrating over to AWS).

Once everything looks good on production, Harri merges `main` into `dev`, so that `main` and `dev` are in parity with each other.

You could argue that this strategy is non-optimal.  It makes PRs have to stay open inherently longer because the release manager is timing when they are merging PRs based off of their release schedule.  This can cause open PRs to diverge from `dev`/`main`, resulting in merge conflicts and other problems.

But it fits well with who is on our team and the amount of resources that we have.  It’s a workflow that is manageable for all.  Of course it’s an iterative process - we need to continue to improve our workflows.  But we shouldn’t sacrifice consistency for optimality in how we use Git branches.

### Keep Calm and Carry On
Building solid development operations is not easy work.  I feel like a lot of the challenges around building software aren’t doing things like writing an algorithm or implementing a data structure.

It’s being able to coordinate with team members in a way that we are consistently communicating with each other and consistently getting each other unstuck.  It requires everything from being able to emotionally cope with nasty merge conflicts that make you want to pull your hair out to being able to build trust within your team to follow the practices you’ve set out to each other's best abilities.

So take it one day at a time.  Don’t stay up until 1 am in the morning trying to make arbitrary deadlines.  Take the time to build comradery with your team members.  This is difficult in the era of COVID-19, for sure.  At YvesBlue, we have weekly zoom “happy hours” where we catch up with one another, and demos where we show off the work we’ve been doing.


What tips and tricks have you and your team implemented in your development operations?  Sound off in the comments below!


