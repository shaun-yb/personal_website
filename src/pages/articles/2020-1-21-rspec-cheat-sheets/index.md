---
title: RSpec Cheat Sheet
date: "2020-01-21"
layout: post
draft: false
path: "/posts/rspec-cheat-sheet/"
category: "Software Engineering"
tags:
  - "Software Engineering"
description: ""
---

### Equality Matchers
`expect(a).to equal(b)  #passes if a.equal?(b)`
`expect(a).not_to eq(b) #passes if !a.equal(b)`
`expext(a).to be == b #passes if a ==b`
`expect([1,2,3]).to contain_exactly(2,3,1)`
`expect({a: "b"}).to have_key(:a)`

### Predicate Matchers
Prefix any predicate method with `_be` and remove the `?`
`expect([]).to be_empty`
`expect(nil).to be_nil`

### Errors
`expect { raise "oops"}.to raise_error`
`expect { raise StandardError }.to raise_error(StandardError)`

### OpenStruct
Useful for creating dummy objects w/methods that return values
`foo = OpenStruct.new(bar: "buzz") # foo.bar === "buzz"`

### Stubbing
`allow(book).to receive(:title).and_return("The Great Gatsby")`
`allow_any_instance_of(Book).to receive(:title).and_return("The Great Gatsby")`
`allow(book).to receive(:title).and_call_original`
`allow(usa).to receive(:city).with("NYC").and_return("Greatest City in the World!")`
`allow(usa).to receive(:city).with("not a city!").and_raise(NotACityError)`

### Message Expectations
`expect(usa).to receive(:city).exactly(n).time`
`expect(usa).to receive(:city).at_lease(n).time`
`expect(usa).to receive(:city)at_most(n).time`
`expect(Country).to receive(:list_all_countries)`

### Controller Specs
```
RSpec.describe WidgetsController, :type => :controller do
  describe "GET index" do
    it "has a 200 status code" do
      get :index {foo_param: "bar value" }
      expect(response.status).to eq(200)
	  expect(response.content_type).to eq "application/json"
      parsed_body = JSON.parse(response.body)
      expect(parsed_body). to eq({"fizz" => "bar"})
    end
  end
end
```
