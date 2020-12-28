---
title: Serialization
date: "2020-12-28"
layout: post
draft: true
path: "/posts/serialization-at-yvesblue/"
category: "Software Engineering"
tags:
  - "Software Engineering"
description: ""
---

### Background  
  
An early architectural decision that we made early on at YvesBlue was to return a serialized representation of resources for all of our API endpoints, regardless   of what HTTP verb that endpoint correlates to.  
  
This basically means that for example, when we make POST endpoints, we want to return a serialized representation of that resource created.  Or alternatively, if we made a PUT request, we'd want to return a serialized representation of the updated resource.  Finally, we decided that we wanted to use JSON to implement our serializations.  
  
There were a few motives behind this.  Primarily though, as a user of our API, I want to receive a written contract that ensures that a read or write to the database was successful.  Additionally, as the user of the API, providing a thorough and consistent serialization of the resource will create written documentation on how the data model works.  We can put the responses we are returning in our API documentation (we use Postman) along with documentation on what each field means.  
  
### Challenges With Where We Were  
In our Rails application, three very important models are `Users`, `Funds` and `Holdings`.  A `User` has many `Funds`.  A `Fund` belongs to one and only one fund and has many `Holdings`.  Each `Holding` belongs to one and only one `Fund`.  A truncated version of the migrations that would create these tables would look like this:  
  
```  
create_table "users", force: :cascade do |t|  
 t.text :email t.text :first_name t.text :last_nameend  
create_table "funds", force: :cascade do |t|  
 t.integer :id t.integer :user_id t.text :nameend  
  
create_table "holdings", force: :cascade do |t|  
 t.integer :id t.integer :fund_id t.text :name t.decimal :amount t.decimal :weightend  
```  
  
With the corresponding models:  
```  
class User < ApplicationRecord  
 has_many :fundsend  
  
class Fund < ApplicationRecord  
 belongs_to :user has_many :holdingsend  
  
class Holding < ApplicationRecord  
 belongs_to :fundend  
```  
  
Now, let's look at one of our controllers - our Fund Holding Controller.  Our goal is to implement the following endpoints:  
  
```  
GET /api/funds/:fund_id/holdings # get all of the holdings on a fund  
GET /api/funds:fund_id/holdings/:holding_id # get a specific holding on a fund  
POST /api/funds/:fund_id/holdings  # create a holding  
PUT /api/funds/:fund_id/holdings/:holding_id  # create a holding  
DELETE /api/funds/:fund_id/holdings/:holding_id # delete a holding  
```  
  
The endpoints we built initially looked like this:  
  
```  
module Api  
 module Funds class HoldingsController < ApplicationController def index @fund = Fund.find(params[:fund_id]) end  
 def show @holding = Holding.find(params[:holding_id]) end  
 def create @fund = Fund.find(params[:fund_id]) @holding = HoldingRepository.new.create!(@fund, holding_params) head 201 end  
 def update @holding = Holding.find(params[:holding_id]) @holding = HoldingRepository.new.update!(@holding, holding_params) head 200 end  
 def destroy @holding = Holding.find(params[:holding_id]) @holding = HoldingRepository.new.destroy!(@holding, holding_params) head 200 end  
 private  
 def holding_params params.require(:holding).permit(:name, :weight, :amount) end end endend  
```  
  
As you can see, the `#create`, `#update`, and `#destroy` endpoints return status codes.  For the `#index` and `#show` endpoints, we had corresponding views that Rails automatically used to create JSON representations of our resources.  Specifically, we used JBuilder to create view templates that look like this:  
  
```  
# /api/funds/holdings/index.json.jbuilder  
json.holdings @fund.holdings do |holding|  
 json.id holding.id json.fund_id @fund.id json.name holding.name json.weight holding.weightend  
  
# /api/funds/holdings/show.json.jbuilder  
json.holding @holding do  
 json.id holding.id json.fund_id @fund.id json.name holding.name json.weight holding.weightend  
```  
  
To complete our goal of returning JSON representations of the resource for all of its endpoints, we added in JBuilder templates for the PUT, POST, and DELETE endpoints:  
  
```  
# /api/funds/holdings/create.json.jbuilder  
json.holding @holding do  
 json.id holding.id json.fund_id @fund.id json.name holding.name json.weight holding.weightend  
  
# /api/funds/holdings/update.json.jbuilder  
json.holding @holding do  
 json.id holding.id json.fund_id @fund.id json.name holding.name json.weight holding.weightend  
  
# /api/funds/holdings/destroy.json.jbuilder  
json.holding @holding do  
 json.id holding.id json.fund_id @fund.id json.name holding.name json.weight holding.weightend  
```  
  
Finally, after all of this, we achieved our goal (w00t!).  However, there are several architectural flaws with this design that we soon found out after implementing it.  
  
Namely, there's a lot of duplicate code.  This block:  
```  
 json.id holding.id json.fund_id @fund.id json.name holding.name json.weight holding.weight```  
  
Is repeated four different times.  What would happen if we wanted to add a `description` field to our Holding model?  We would have to update code in four different files.  
  
To fix this, we decided to do a few things.  First, we pulled out all of the code in our JBuilder views into `serializer`s.  Serializers, in the context of our code bases, are Plain Old Ruby Objects (POROs) that are responsbile for taking in a model, and returning a JSON representation of it.  These lived at the top level (`app/serializers`).  Our Holding Serializer now looked like this:  
  
```  
 class HoldingRepository < BaseRepository attr_reader :holding  
 def initialize(holding) @holding = holding end  
 def serialize Jbuilder.encode do |json| json.id holding.id json.fund_id @fund.id json.name holding.name json.weight holding.weight end end end  
 class BaseRepository def serialize raise "Interface method serialize not implemented." end end```  
  
How this is better.  We're implementing the single responsibiltiy principle in the sense that the business logic of mapping a resource to a JSON hash is encapsulated in one place.  If we want to add a field to our model, we only have one place we need to change the code!  
  
  
  
### Testing
