[Joshua Weltz](http://ecotheory.biology.gatech.edu/), a quantative biology professor at Georgia Tech, came up with a [formula](https://figshare.com/articles/COVID-19_Event_Risk_Assessment_Planner/11965533) to calculate the chance that within a country, at a given event of X size, there is at least one infected individual.  This formula can be written as: 

`risk(g,p,i) = 1 -(1-(i/p))^g`

Where `g` is the group size at the event, `i` is the number of infected individuals in the population, and `p` is the total size of the calculation.

So far, a backend API has been wired up that you can see in [this repo](https://github.com/everythings-cancelled/event_risk_assessment_api).  This API has an endpoint that takes in a country's name and a group size.  It uses external APIs to get a country's total population and infected population in real time.  It then uses this information to calculate the risk using Dr. Weltz' formula, and returns it as a response to the user.

A React frontend client to consume this API still needs to be developed.  I would imagine it would look something like this:

![alt text](https://i.ibb.co/rb4981x/6-CA95-FAE-E56-E-4-CB6-8-A37-FFB15070-EA29.jpg "Event Risk Assessment Mockup")


There's probably a lot more that we can do with this.  Have any ideas?  [Get in touch](http://shauncar.land/contact)!
