### Fabrication ###

Fabrication is an object generation library. It allows you to define Fabricators that are essentially the schematic for objects you want to generate. You can then generate them as needed anywhere in your app or specs.

Currently supported object types are...

* Plain old Ruby objects
* ActiveRecord objects
* Mongoid Documents

By default it will lazily generate active record associations. So if you have a has_many :widgets defined, it will not actually generate the widgets until the association is accessed. You can override this by appending "!" to the name of the parameter when defining the field in the Fabricator.

### Installation ###

Add this to your gemfile.

`gem 'fabrication'`

Now you can define fabricators in any of the following locations.

* `spec/fabricators.rb`
* `spec/fabricators/*.rb`

* `test/fabricators.rb`
* `test/fabricators/*.rb`

They are automatically loaded, so no additional requires are necessary.

### Usage ###

Define your fabricators.

    Fabricator(:company) do
      name "Fun Factory"
      employees(:count => 20) { |company, i| Fabricate(:drone, :company => company, :name => "Drone #{i}") }
      location! { Fabricate(:location) }
      after_create { |company| company.update_attribute(:ceo, Fabricate(:drone, :name => 'Lead Drone') }
    end

Breaking down the above, we are defining a "company" fabricator, which will generate Company model objects.

* The object has a name field, which is statically filled with "Fun Factory".
* It has a has_many association to employees and will generate an array of 20 records as indicated by the :count => 20. The block is passed the company object being fabricated and index of the array being created.
* It has a belongs_to association to location and this will be generated immediately with the company object. This is because of the "!" after the association name.
* After the object is created, it will update the "ceo" association with a new "drone" record.

Alternatively, you can Fabricate(:company) without first defining the Fabricator. Doing so will create an empty Fabricator called ":company" and prevent you from defining the Fabricator explicitly later.

### Inheritance ###

So you already have a company fabricator, but you need one that specifically generates an LLC. No problem!

    Fabricator(:llc, :from => :company) do
      type "LLC"
    end

Setting the :from option will inherit the class and all the attributes from the named Fabricator. Even if you haven't defined a :company Fabricator yet, it will still work as long as it references an actual class name.

You can also explicitly specify the class being fabricated with the :class_name parameter.

    Fabricator(:llc, :class_name => :company) do
      type "LLC"
    end

### Fabricating ###

Now that your Fabricators are defined, you can start generating some objects! To generate the LLC from the previous example, just do this:

    llc = Fabricate(:llc, :name => "Awesome Labs", :location => "Earth")

That will return an instance of the LLC using the fields defined in the Fabricators and overriding with anything passed into Fabricate.

If you need to do something more complex, you can also pass a block to Fabricate. You can use all the features available to you when defining Fabricators, but they only apply to the object generated by this Fabricate call.

    llc = Fabricate(:llc, :name => "Awesome, Inc.") do
      location!(:count => 2) { Faker::Address.city }
    end

Sometimes you don't actually need to save an option when it is created but just build it. In that case, just call `Fabricate.build` and it will skip the saving step.

    Fabricate.build(:company, :name => "Hashrocket")

You can also fabricate the object as an attribute hash instead of an actual instance. This is useful for controller or API testing where the receiver wants a hash representation of the object. If you have activesupport it will be a HashWithIndifferentAccess, otherwise it will be a regular Ruby Hash.

    Fabricate.attributes_for(:company)

### Sequences ###

Sometimes you need a sequence of numbers while you're generating data. Fabrication provides you with an easy and flexible means for keeping track of sequences.

This will create a sequence named ":number" that will start at 0. Every time you call it, it will increment by one.

    Fabricate.sequence(:number)

If you need to override the starting number, you can do it with a second parameter. It will always return the seed number on the first call and it will be ignored with subsequent calls.

    Fabricate.sequence(:number, 99)

If you are generating something like an email address, you can pass it a block and the block response will be returned.

    Fabricate.sequence(:name) { |i| "Name #{i}" }

And in a semi-real use case, it would look something like this:

    Fabricate(:person) do
      ssn { Fabricate.sequence :ssn, 111111111 }
      email { Fabricate.sequence(:email) { |i| "user#{i}@example.com" } }
    end

### Contributing ###

I (paulelliott) am actively maintaining this project. If you would like to contribute, please fork the project, make your changes on a feature branch, and submit a pull request.

To run rake successfully:

1. Clone the project
2. Install mongodb and sqlite3
3. Install bundler
4. Run `bundle install` from the project root
5. Run `rake` and the test suite should be all green!
