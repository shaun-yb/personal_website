---
title: "Coronavirus SIR Modeling"
layout: page
path: "/projects/everythings-cancelled/coronavirus-sir-modeling"
---

### Coronavirus SIR Modeling

This is the first data visualization tool that I have come up.  I was inspired by animations that the Washington Post had to demonstrate impacts of social isolation: https://www.washingtonpost.com/graphics/2020/world/corona-simulator/.

I thought, well, it would be really interesting if the user could tweak arguments to see the curve flattening it out!

Below is a (very) rough sketch of what we would want to see.  

![alt text](https://i.ibb.co/GRgGgCb/Screen-Shot-2020-03-20-at-2-57-24-PM.png "Coronavirus SIR Modeling Mockup")

We want the user to be able to select a country, average number of contacts per day (or generic unit of time), and the chance of transmission for a given contact.  Using this information, we construct a graph showing the number of infected individuals at a given time.  Since we can get the actual infected number for any country at any given point using [this API](https://github.com/ExpDev07/coronavirus-tracker-api), our graph does not start off at zero.  This is represented by the pink line.  

We also have a black curve.  This black curve represents the number of infected individuals who need hospitalization.  This is represented to be 14% of all infected people, as shown [here](http://www.cidrap.umn.edu/news-perspective/2020/02/study-72000-covid-19-patients-finds-23-death-rate).  To generate this curve, we just take the first curve and reduce the values to 14%.

Finally, we are plotting a blue line.  This blue line is the number of hospital beds that a country has, provided by the [World Health Organization](https://data.worldbank.org/indicator/SH.MED.BEDS.ZS).  Using this graph, we can view at what point the demand for hospital beds outweighs the supply under various social isolation scenarios.  We can also see how overburdened thes healthcare system will be, and for how long.

Currently, I have fired up an API that can be found [here](https://github.com/everythings-cancelled/coronavirus_sir_model_api).  I'm working on implementing a React application to consume this API.  Wanna help out?  [Get in touch](https://shauncar.land/contact/)!