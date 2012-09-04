# Lookup tables with ruby-on-rails

By: Nimrod Priell

This gem adds an ActiveRecord macro to define memory-cached, dynamically growing, normalized lookup tables for entity 'type'-like objects. Or in plain English - if you want to have a table containing, say, ProductTypes which can grow with new types simply when you refer to them, and not keep the Product table containing a thousand repeating 'type="book"' entries - sit down and try to follow through.

Installation is described down the page.

## Motivation

A [normalized DB][1] means that you want to keep types as separate tables, with foreign keys pointing from your main entity to its type. For instance, instead of 

<table>
  <tr>
    <td>
      ID
    </td>
    <td>
      car_name
    </td>
    <td>
      car_type
    </td>
  </tr>
  <tr>
    <td>
      1
    </td>
    <td>
      Chevrolet Aveo
    </td>
    <td>
      Compact
    </td>
  </tr>
  <tr>
    <td>
      2
    </td>
    <td>
      Ford Fiesta
    </td>
    <td>
      Compact
    </td>
  </tr>
  <tr>
    <td>
      3
    </td>
    <td>
      BMW Z-5
    </td>
    <td>
      Sports
    </td>
  </tr>
</table>

You want to have two tables:

<table>
  <tr>
    <td>
      ID
    </td>
    <td>
      car_name
    </td>
    <td>
      car_type_id
    </td>
  </tr>
  <tr>
    <td>
      1
    </td>
    <td>
      Chevrolet Aveo
    </td>
    <td>
      1
    </td>
  </tr>
  <tr>
    <td>
      2
    </td>
    <td>
      Ford Fiesta
    </td>
    <td>
      1
    </td>
  </tr>
  <tr>
    <td>
      3
    </td>
    <td>
      BMW Z-5
    </td>
    <td>
      2
    </td>
  </tr>
</table>

And

<table>
  <tr>
    <td>
      car_type_id
    </td>
    <td>
      car_type_name
    </td>
  </tr>
  <tr>
    <td>
      1
    </td>
    <td>
      Compact
    </td>
  </tr>
  <tr>
    <td>
      2
    </td>
    <td>
      Sports
    </td>
  </tr>
</table>

The pros/cons of a normalized DB can be discussed elsewhere. I'd just point out a denormalized solution is most useful in settings like [column oriented DBMSes][2]. For the rest of us folks using standard databases, we usually want to use lookups.

The usual way to do this with ruby on rails is:

* Generate a CarType model using `rails generate model CarType name:string`

* Link between CarType and Car tables using `belongs_to` and `has_many`

Then to work with this you can transparently read the car type:

    car = Car.all.first
    car.car_type.name # returns "Compact"

Ruby does an awesome job of caching the results for you, so that you'll probably not hit the DB every time you get the same car type from different car objects.

You can even make this shorter, by defining a delegate to car_type_name from CarType:

*in car_type_name.rb*
    
    delegate :name, :to => :car, :prefix => true

And now you can access this as 

    car.car_type_name

However, it's less pleasant to insert with this technique:

    car.car_type.car_type_name = "Sports"
    car.car_type.save!
    #Now let's see what happened to the OTHER compact car
    Car.all.second.car_type_name #Oops, returns "Sports"

Right, what are we doing? We should've used

    car.update_attributes(car_type: CarType.find_or_create_by_name(name: "Sports"))

Okay. Probably want to shove that into its own method rather than have this repeated in the code several times. But you also need a helper method for creating cars that way…

Furthermore, ruby is good about caching, but it caches by the exact query used, and the cache expires after the controller action ends. You can configure more advanced caches, perhaps. Also caches turned much better in 3.2, since it caches by ID now. But the cache is maintained per request only. So in terms of caching, this might be a better solution since the cache is held for your entire application.

The point is all this can get tedious if you use a normalized structure where you have 15 entities and each has at least one 'type-like' field. That's a whole lot of dangling Type objects (model classes, in rails terminology). What you really want is an interface like this:

    car.all.first
    car.car_type #return "Compact"
    car.car_type = "Sports" # No effect on car.all.second, just automatically use the second constant
    car.car_type = "Sedan" # Magically create a new type

Oh, and it'll be nice if all of this is cached and you can define car types as constants (or symbols). You obviously still want to be able to run:

    CarType.where (:id > 3) #Just an example of supposed "arbitrary" SQL involving a real live CarType class

But you want to minimize generating these numerous type classes. If you're like me, you don't even want to see them lying around in app/model. Who cares about them?

I've looked thoroughly for a nice rails solution to this, but after failing to find one, I created my own rails metaprogramming hook.

## Installation

Either run `gem install rails_lookup` to install the latest version of the gem,
or preferably add the rails_lookup dependency to your project's `Gemfile`:

    gem 'rails_lookup' 

The result of this hook is that you get the exact syntax described above, with only two lines of code (no extra classes or anything):
In your ActiveRecord object simply add

    require 'active_record/lookup'
    class Car < ActiveRecord::Base
      #...
      include RailsLookup
      lookup :car_type, :as => :type
      #...
    end

That's it. the generated CarType class (which you won't see as a car_type.rb file, obviously, as it is generated in real-time), contains some nice methods to look into the cache as well: So you can call

    CarType.id_for "Sports" #Returns 2
    CarType.name_for 1 #Returns "Compact"

and you can still hack at the underlying ID for an object, if you need to:

    car = car.all.first
    car.type = "Sports"
    car.type_id #Returns 2
    car.type_id = 1
    car.type #Returns "Compact"

You can also do

    Car.find_all_by_type('Compact')

and so on.

The lookup macro takes a parameter which will be the name of the generated class
and table. Therefore it has to be unique in the project: If you have both car
types and engine types, each must have a differently-named lookup. However, for
terseness, the `:as` parameter lets you specify a short alias so you can call
`car.type` and not `car.car_type`.

The lookup macro also can have the `:presence` parameter which when set to `false`
allows the lookup attr to be nil. The default is that the lookup has to be present.

The only remaining thing is to define your migrations for creating the actual database tables. After all, that's something you only want to do once and not every time this class loads, so this isn't the place for it. However, it's easy enough to create your own scaffolds so that 

     rails generate migration create_car_type_lookup_for_car

will automatically create the migration

    class CreateCarTypeLookupForCar < ActiveRecord::Migration
      def self.change
        create_table :car_types do |t|
          t.string :name
          t.timestamps #Btw you can remove these, I don't much like them in type tables anyway
        end
    
        remove_column :cars, :car_type #Let's assume you have one of those now…
        add_column :cars, :type, :integer #Maybe put not_null constraints here.
      end
    end

Note that the name of the table is the lookup name while the column that refers
to that table is named after the shorthand `:as` alias.

(The change syntax is specific to Rails 3.2. You will need to use .up and .down
for Rails < 3.2)

I'll let you work out the details for actually migrating the data you already
have yourself. 

[1]: http://en.wikipedia.org/wiki/Database_normalization
[2]: http://en.wikipedia.org/wiki/Column-oriented_DBMS

I hope this helped you and saved a lot of time and frustration. Follow me on twitter: @nimrodpriell

## Using scopes

Not all parts of rails go through the same flow in active record. For example,
to use lookup tables in scopes we don't get all of the transparent mapping
discussed above. So a correct scoping for the CarColor lookup will be

    scope :by_color, lambda { |color| 
      joins(:car_color).where({:car_colors => { name: color }})
    }

This is obviously true wherever you use this style of query-building (in this
case, we could've just used 'find_by_color' instead; However you can only go so
far with the auto-generated finder methods, and sometimes you have to build your
own queries). Note that the relation is called `:car_color` and hence this is
the way it is refered to in the '.joins' method, but the '.where' method
generates an SQL directly where the table name, :car_colors, is used.

Also, notice using this syntax will obviously bypass the cache and create an 
actual SQL query, so you're losing some of the power of the lookups

## What doesn't work

You can't create a new instance with the lookup type right now. I.e,

    Car.new(color: "Red")

will not work. Instead, use either 

    Car.new(car_color_id: CarColor.id_for("Red"))

or 

    Car.initialize_by_color("Red")

## Testing

    rvm gemset create rails_lookup_devel
    gem install bundler
    bundle install
    rake test

That should basically do it. The gems required are managed in the Gemfile, they
are currently Rails and SQLite (which is used only for testing). This has been
tested to work with rails-3.0.9. Tests run on later rails versions - 3.1.4 and
3.2.2 specifically - but it has been reported not to work on these. I'm looking
into it.


