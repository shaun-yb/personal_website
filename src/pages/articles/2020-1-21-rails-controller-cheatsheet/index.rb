---
title: Rails Controller Cheat Sheet
date: "2020-01-21"
layout: post
draft: false
path: "/posts/rspec-cheat-sheet/"
category: "Software Engineering"
tags:
  - "Software Engineering"
description: ""
---

#### Action/Route/Controller Associations
- Action: `GET /patients/17`
- Route: `get '/patients/:id' to 'patients#show'`
- Controller: `PatientsController#show(params: { id: '17' })`

 `Http Methods`: `GET`/`POST`/`PATCH`/`PUT`/`DELETE` perform an operation on the resource.
 
#### Paths
If you put `@patient = Patient.find(params[:id])` in your code you will have access to `patient_path(@patient)` in your views, which generates a path to `/patients/17` 

**Note Snake Case:** `MonsterTrucksController`'s route is `monster_truck#show`

#### Resourceful Routes  
- Mapping between HTTP verbs and URLs to controller actions.
- Each maps to a specific `CRUD` verb.

In `routes.rb`, root resource: `resource patients` creates routes for `index`/`show`/`new`/`edit`/`create`/`update`/`destroy` endpoints in the controller.

**Prefixes**
if you want to route`/admin/articles` to `ArticlesController`
```
scope module: 'admin' do
  resources :articles, :comments
end
```

`GET` - `/admin/articles` `articles#index` `articles_path`
`GET` -  `/admin/articles/new` `articles#new` `new_article_path`
`POST` - `/admin/articles` `articles#create` `article_path`
`GET` - `/admin/articles/:id` `articles#show` `article_path`
`PATCH/PUT` - `/admin/articles/:id` `articles#update` `article_path(id)`
`DELETE` - `/admin/articles/:id` `articles#destroy` `article_path(:id)`

**Nested Resources**
If you have resources that are logically children of other resources (e.g.
```
class Magazine < ApplicationRecord
	has_many :ads
end

class Ad < ApplicationRecord
	belongs_to :magazine
end
```

You can use Nested Routes
```
resources :magazines do
	resources :ads
end
```

To get: 
`GET` - `/magazines/:magazine_id/ads` => `ads#index`
`GET` - `/magazines/:magazine_id/ads/new` => `ads#new` (for view)
`POST` - `/magazines/:magazine_id/ads`  => `ads#create` (for db)
`GET`  - `/magazines/:magazine_id/ads/:id` => `ads#show`
`GET` - `magazines/:magazine_id/ads/:id/delete` => `ads#destroy`
`GET` - `magzines/:magazine_id/ads/:id/edit` => `ads#edit` (for views)
`PUT` - `magazines/:magazine_id/ads/:id` => `ads#update` (for db)

- This also gives us `magazine_ads_url` etc etc
- Resources should never be more than 1 level deep.

**Non Resourceful Routes**
Routes that you don't get automatically via restful routing.  You set up each route in app.  If you set up this route:

`get` `'photos(/:id)'``, to:` `'photos#display'`
the request in the format `/photos/1` is called to process this route, triggering `PhotosController.display({id: "1"})`

`get 'photos#search' => photos#search` matches to PhotosController.search

**The Query String**
Used to pass in other parameters into the endpoint.
`/photos/1?user_id=2` would trigger `PhotosController.show({id: "1", user_id: "2"})`

**Naming Routes**
`get 'exit', to: 'sessions#destroy', as: :logout`

**Verb Constraints**
`match 'photos', to: 'photos#show', via: [:get, :post]`  provides routes to the `#get` and `#post` endpoints/methods.

*Routing both  `GET`  and  `POST`  requests to a single action has security implications. In general, you should avoid routing all verbs to an action unless you have a good reason to.*

*`GET` in Rails won't check for CSRF token. You should never write to the database from `GET` requests*

**JSON Rendering**
`render json: {foo: "bar"}`

**Returning Status Code**
`return status: 200`

**Strong Params**
Provides an interface for protection.  Makes ActionController parameters forbidden to be used until they have been explicitly enumerated.
```
def person params
	# means the params should have a key called 'person'.  The value of 'person'
	# can have keys 'name' and 'age'.
	params.require(:person).permit(:name, :age)
end
```

If you use `permit` in a key that points to a hash, it won't allow the hash.  You must specify which attributes inside the hash that should be permitted.
```
params = ActionController::Parameters.new({
  person: {
    contact: {
      email: "none@test.com",
      phone: "555-1234"
    }
  }
})
params.require(:person).permit(contact: [ :email, :phone ])
```