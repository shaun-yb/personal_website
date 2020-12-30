---
title: Serialization at YvesBlie
date: "2020-12-28"
layout: post
draft: false
path: "/posts/serialization-at-yvesblue/"
category: "Software Engineering"
tags:
  - "Software Engineering"
description: ""
---

### Background

An early architectural decision that we made early on at YvesBlue was to return a serialized representation of resources for all of our API endpoints, regardless   of what HTTP verb that endpoint correlates to.  This basically means that for example, when we make POST endpoints, we want to return a serialized representation of that resource created.  Or alternatively, if we made a PUT request, we'd want to return a serialized representation of the updated resource.  

There were a few motives behind this.  Primarily though, as a user of our API, I want to receive a written contract that ensures that a read or write to the database was successful.  Additionally, as the user of the API, providing a thorough and consistent serialization of the resource will create written documentation on how the data model works.  We can put the responses we are returning in our API documentation (we use Postman) along with documentation on what each field means.

### Challenges With Where We Were
In our Rails application, there are three very important models are `Funds` and `Holdings`.  A `Fund` has many `Holdings`.  Each `Holding` belongs to one and only one `Fund`.  A truncated version of the migrations that would create these tables would look like this:

```
create_table "funds", force: :cascade do |t|
  t.integer :id
  t.text :name
  t.text :industry
  t.text :vertical
end

create_table "holdings", force: :cascade do |t|
  t.integer :id
  t.integer :fund_id
  t.text :name
  t.decimal :amount
  t.decimal :weight
end
```

With the corresponding models:
```
class Fund < ApplicationRecord
  has_many :holdings
end

class Holding < ApplicationRecord
  belongs_to :fund
end
```

Now, let's look at one of our controllers - our Fund Holding Controller.  Our goal is to implement the following endpoints:

```
GET /api/funds # get all of the funds
GET /api/funds/:fund_id # get a specific fund
POST /api/funds # create a fund

GET /api/funds/:fund_id/holdings # get all of the holdings on a fund
GET /api/funds/:fund_id/holdings/:holding_id # get a specific holding on a fund
POST /api/funds/:fund_id/holdings  # create a holding
```

The endpoints we built initially looked like this:
```
class Api::BaseController < ApplicationController; end
  module Api
    class FundsController < BaseController
      def index
        @fund = Fund.all
      end

      def show
        @fund = Fund.find(params[:fund_id])
      end

      def create
        @fund = FundRepository.new.create!(fund_params)
      end

      private

      def fund_params
        params.require(:fund).permit(:name, :industry, :vertical)
      end
    end
  end

module Api
  module Funds
    class HoldingsController < BaseController
      def index
        @holdings = Holding.all
      end

      def show
        @holding = Holding.find(params[:holding_id])
      end

      def create
        @fund = Fund.find(params[:fund_id])
        @holding = HoldingRepository.new.create!(@fund, holding_params)
        head 201
      end

      private

      def holding_params
        params.require(:holding).permit(:name, :weight, :amount)
      end
    end
  end
end
```

As you can see, the `#create`, `#update`, and `#destroy` endpoints return status codes.  For the `#index` and `#show` endpoints, we had corresponding views that Rails automatically used to create JSON representations of our resources.  Specifically, we used JBuilder to create view templates that look like this:

```

  # /api/funds/index.json.jbuilder
  json.funds @funds.each do |fund|
    json.id fund.id
    json.name fund.name
    json.industry fund.industry
    json.vertical fund.vertical
    json.holdings fund.holdings.each { |holding| { id: holding.id, weight: holding.weight, name: holding.name, amount: holding.amount, fund_id: fund.id } }
  end

  # /api/funds/show.json.jbuilder
  json.fund @fund do |fund|
    json.id fund.id
    json.name fund.name
    json.industry fund.industry
    json.vertical fund.vertical
    json.holdings fund.holdings.each { |holding| { id: holding.id, weight: holding.weight, name: holding.name, amount: holding.amount, fund_id: fund.id } }

  end

# /api/funds/holdings/index.json.jbuilder
json.holdings @fund.holdings do |holding|
  json.id holding.id
  json.fund_id @fund.id
  json.name holding.name
  json.weight holding.weight
end

# /api/funds/holdings/show.json.jbuilder
json.holding @holding do
  json.id holding.id
  json.fund_id @fund.id
  json.name holding.name
  json.weight holding.weight
end
```

To complete our goal of returning JSON representations of the resource for all of its endpoints, we added in the JBuilder template for the `CREATE` endpoint on both the funds and fund holdings controllers:

```
  # /api/funds/create.json.jbuilder
  json.fund @fund do |fund|
    json.id fund.id
    json.name fund.name
    json.industry fund.industry
    json.vertical fund.vertical
    json.holdings fund.holdings.each { |holding| { id: holding.id, weight: holding.weight, name: holding.name, amount: holding.amount, fund_id: fund.id } }
  end

# /api/funds/holdings/create.json.jbuilder
json.holding @holding do
  json.id holding.id
  json.fund_id @fund.id
  json.name holding.name
  json.weight holding.weight
end
```

Finally, after all of this, we achieved our goal (w00t!).  However, there are several architectural flaws with this design that we soon found out after implementing it.

Namely, there's a lot of duplicate code.  This block:
```
  json.id holding.id
  json.fund_id @fund.id
  json.name holding.name
  json.weight holding.weight
```

and this block:
```
    json.id fund.id
    json.name fund.name
    json.industry fund.industry
    json.vertical fund.vertical
    json.holdings fund.holdings.each { |holding| { id: holding.id, weight: holding.weight, name: holding.name, amount: holding.amount, fund_id: fund.id } }
```

are both repeated multiple times.

What would happen if we wanted to add a `description` field to our Holding model?  We would have to update code in all of the Holding's JBuilder views.  We'd also have to update this line in all of the Fund's JBuilder views:

`json.holdings fund.holdings.each { |holding| { id: holding.id, weight: holding.weight, name: holding.name, amount: holding.amount, fund_id: fund.id } }`


To fix this, we decided to do a few things.  First, we pulled out all of the code in our JBuilder views into `serializer`s.  Serializers, in the context of our code bases, are Plain Old Ruby Objects (POROs) that are responsbile for taking in a model, and returning a JSON representation of it.  These lived at the top level (`app/serializers`).  Our Holding Serializer now looked like this:

```
  # app/serializers/fund_serializer.rb
  class FundSerializer < BaseSerializer
    json.fund @fund do |fund|
      json.id fund.id
      json.name fund.name
      json.industry fund.industry
      json.vertical fund.vertical
      json.holdings fund.holdings.each { |holding| { id: holding.id, weight: holding.weight, name: holding.name, amount: holding.amount, fund_id: fund.id } }
    end
  end

  # app/serializers/holding_serializer.rb
  class HoldingSerializer < BaseSerializer
    attr_reader :holding

    def initialize(holding)
      @holding = holding
    end

    def serialize
      Jbuilder.encode do |json|
        json.id holding.id
        json.fund_id holding.fund.id
        json.name holding.name
        json.weight holding.weight
      end
    end
  end

  # app/serializers/base_serializer.rb
  class BaseSerializer
    def serialize
      raise "Interface method serialize not implemented."
    end
  end
```


Why this is better - we're implementing the single responsibiltiy principle in the sense that the business logic of mapping a resource to a JSON hash is encapsulated in one place.  If we wanted to add in a description, in order for that data to get serialized in our API requests, we only have to touch two places in the code; the two serializers above.

We then had to connect our controllers with our serializers.  To do that, we added in the following method in the Base Controller:

```
      def render_serialized_resource(status: :ok, serializer:)
        render plain: serializer.serialize, status: status
      end
```

Since both the `FundsController` and the `HoldingsController` inherits from the `BaseController`, both can use the `render_serialized_resource` method as if it was an instance method.

This method takes in an instance of a serializer, and calls `.serialize` on it.  It uses the result of what the `.serialize` method provides and renders it as plain, raw JSON.  Exactly what we want to do!

This might seem a bit off at first, especially if you're used to working in a typed language.  Ruby is a duck language - that is, there is not type verification happening to ensure that we are always passing in either an instance of the FundSerializer or an instance of the HoldingSerializer, such as:

```
      def render_serialized_resource(status: :ok, serializer:)
        raise unless serializer.is_a?(FundSerializer) || serializer.is_a?(HoldingSerializer)
        render plain: serializer.serialize, status: status
      end
```

We don't want the `render_serialized_resource` method to be dependent on any concrete implementation of a serializer.  We want to build instances of serializer classes, and then pass those instances to the `render_serialized_resource` method.  This way, if for example, we wanted to start serializing a different resource, such as a User, we can do so on the fly.

We pass in a `status` param with a default message of `:ok`.  Usually, the default value is only changed for `create` requests, which would be a `:created` status.

This works for implementing our `show` and `create` endpoints.  Because we are rendering a single resource.  But it breaks for our index endpoints.  To fix this, I added in the following `render_serialized_collection` method in the `BaseController`:

```
      def render_serialized_collection(status: :ok, serializer_klass:, collection:)
        deserialized_collection_items = []

        collection.each do |collection_item|
          serializer = serializer_klass.new(collection_item)
          deserialized_collection_items << JSON.parse(serializer.serialize)
        end

        serialized_collection = deserialized_collection_items.to_json
        render plain: serialized_collection, status: status
      end
```

As before, we have an optional status param - which at the moment will always be `:ok` because this is only being used for `index` endpoints.  It takes in an enumerable `collection` - such as `@funds` or `@holdings`, along with their corresponding serializer class (e.g. `FundSerializer` or `HoldingSerializer`).  The method iterates over all of the items in the collection, and creates a new instance of the `serializer_klass` for each.  The JSON strings generated from each item in the collection is collected in an array.  This array then intself is parsed into JSON, and rendered plainly to the user.

As an aside, notice that I am using named parameters (e.g. `status:, serializer_klass:)`.  In my opinion, any public method that has more than one param should have named parameters; @-me if you don't agree and I'm happy to have a flamewar about it ;P.

This is the final results of our controller:

```
  module Api
    class BaseController < ApplicationController
      def render_serialized_resource(status: :ok, serializer:)
        render plain: serializer.serialize, status: status
      end

      def render_serialized_collection(status: :ok, serializer_klass:, collection:)
        deserialized_collection_items = []

        collection.each do |collection_item|
          serializer = serializer_klass.new(collection_item)
          deserialized_collection_items << JSON.parse(serializer.serialize)
        end

        serialized_collection = deserialized_collection_items.to_json
        render plain: serialized_collection, status: status
      end
    end
  end

  module Api
    class FundsController < BaseController
      def index
        @funds = Fund.all
        render_serialized_collection collection: @fund
      end

      def show
        @fund = Fund.find(params[:fund_id])
      end

      def create
        @fund = FundRepository.new.create!(fund_params)
      end

      private

      def fund_params
        params.require(:fund).permit(:name, :industry, :vertical)
      end
    end
  end

module Api
  module Funds
    class HoldingsController < BaseController
      def index
        @fund = Fund.find(params[:fund_id])
        @holdings = Holding.where(fund_id: @fund.id)
        render_serialized_collection collection: @holdings, serializer_klass: HoldingSerializer
      end

      def show
        @holding = Holding.find(params[:holding_id])
        render_serialized_resource serializer: HoldingSerializer.new(@holding)
      end

      def create
        @fund = Fund.find(params[:fund_id])
        @holding = HoldingRepository.new.create!(@fund, holding_params)
        render_serialized_resource serializer: HoldingSerializer.new(@holding), status: :created
      end

      private

      def holding_params
        params.require(:holding).permit(:name, :weight, :amount)
      end
    end
  end
end
```

This is looking much better!  But there's still one more problematic line of code in the `FundSerializer`:
```
    json.holdings fund.holdings.each { |holding| { id: holding.id, weight: holding.weight, name: holding.name, amount: holding.amount, fund_id: fund.id } }
```

We should aim to reduce using business logic in our serializers because it creates more code that we have to maintain and test.  If we were to add in a `description` field, as described above, we'd have to update this class.

Our goal was to then be able to use our `HoldingSerializer` within our `FundSerializer`.  So that we are re-using our code, and if we ever want to change how we're serializing a model, we only have to change it in one place.

To do this, we added in a `deserialize` method in the `BaseSerializer` that looked like this:

```
  def deserialize
    JSON.parse(serialize)
  end
```

 When this is called on a class that inherits from the `BaseSerializer`, it calls `serialize` on itself, and passes that into a `JSON` parser.  This will convert the `serialize` string into a hash.  Since the `HoldingSerializer` inherits from the `BaseSerializer`, we can do this:

 ```
  class FundSerializer < BaseSerializer
    json.fund @fund do |fund|
      json.id fund.id
      json.name fund.name
      json.industry fund.industry
      json.vertical fund.vertical
      json.holdings fund.holdings.each { |holding| HoldingSerializer.new(holding).deserialize }
    end
  end
```

What do think of this approach?  Please let me know! :)
