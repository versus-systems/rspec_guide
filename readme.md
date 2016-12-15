# Versus RSpec Guidelines

RSpec is used at Versus for Unit Testing. For feature or integration style tests, we use Cucumber. For more information on Cucumber, please see the Versus Cucumber Guildelines.

Since RSpec is used for Unit Testing, we will in most all cases not be touching external dependencies, including the database. There is a specific unit-style test that must hit the database in order to verify the code. When testing models directly, and more specifically when testing uniqueness contraints, a database hit is required as a conflicting record must already exist in the database for the contraint to fail.

While most of our testing is around testing functions, these functions many times collaborate with objects so traditional object testing rules can apply. There are two types of messages you can send an object. You can send a "Query" message or a "Command" message.

When testing an object, you must test all of the public messages it accepts, regardless of whether they are query or command. When testing query methods, you want to verify you got the expected answer. When testing command methods, you want to verify the system was changed in the expected way.

When testing our interactions with collaborating objects however, we don't need to test that we call "query" methods on those objects and we don't need to test that we got the expected answer. We merely need to set the state on the collaborating object (either real or mock) such that it can answer our queries correctly.

We do need to test that we call "command" methods on our collaborating objects, but we do not need to test that they did actually change the system. We can be confident that tests on our collaborating objects take care of that. By verifying we sent the message, we can trust that the object we sent it to knows how to do it's job.

Tests on our functions are primarily query style tests, verifying that given some input, we get the expected output. However, many of our functions are not "pure" and perform external interactions with databases and external services. In these cases we not only want to verify that we get back the expected output given some input, but we want to verify any command messages it sends to collaborating objects.

## General Guidelines

* Test *what* things do, not *how* they do them.
* Do not use Factories or Fixtures. Since we are not hitting the database, factories and fixtures are not necessary. Leave their use to the integration tests where a database is involved.
* Don't persist your models except in the already stated execption for uniqueness contraint checking.
* Use the actual object under test, not a mock
* Use mocks/stubs for all collaborations
* Prefer to inject your collaborators
* When testing functions like our Components, test a set of inputs which exercise each possible path through the code. Verify the output is what we expect in each case.
* When testing objects like models or any other standard object, test all public methods. Do not test private methods. If you do not want a method to be part of of the public interface, make it private.
* Whether testing functions or objects, perform the minimum required setup for a test. Keep common/global setup at the outermost layer, with additional setup in each relevant context.
* Setup should be done using `let` and as necessary, `before` blocks. Avoid `let!` unless truly necessary. Take advantage of laziness.

## Examples

Each of these examples illustrates situations you may find yourself testing. They include recommended practices as well as explainations why.

### FizzBuzz

FizzBuzz is implemented as a simple function. There are no objects involved and as such we simply must test that for a veriety of inputs we get the expected output.

```ruby
def fizzbuzz n
  result = ''
  result += 'Fizz' if (n % 3).zero?
  result += 'Buzz' if (n % 5).zero?
  result.empty? ? n : result
end
```

```ruby
describe '#fizzbuzz' do
  it 'returns 1 given 1' do
    expect(fizzbuzz 1).to eq 1
  end

  it 'returns 2 given 2' do
    expect(fizzbuzz 2).to eq 2
  end

  it 'returns "Fizz" given 3' do
    expect(fizzbuzz 3).to eq 'Fizz'
  end

  it 'returns "Buzz" given 5' do
    expect(fizzbuzz 5).to eq 'Buzz'
  end

  it 'returns "Fizz" given 6' do
    expect(fizzbuzz 6).to eq 'Fizz'
  end

  it 'returns 8 given 8' do
    expect(fizzbuzz 8).to eq 8
  end

  it 'returns "Buzz" given 10' do
    expect(fizzbuzz 10).to eq 'Buzz'
  end

  it 'returns "fizzbuzz" given 15' do
    expect(fizzbuzz 15).to eq 'FizzBuzz'
  end
end
```

Results when run:

```bash
#fizzbuzz
  returns 1 given 1
  returns 2 given 2
  returns "Fizz" given 3
  returns "Buzz" given 5
  returns "Fizz" given 6
  returns 8 given 8
  returns "Buzz" given 10
  returns "FizzBuzz" given 15
```

### Persist

This is a simple function that given an object it calls `save` on it and either returns the persisted object or `nil`. Not necessarily the best function but I wanted to illustrate two concepts.

Our function:

```ruby
def persist model
  return model if model.save
end
```

Since this function is very generic and doesn't actually care *what* its input is other than the input responds to `save` then using a standard generic mock is preferred. We set up our mock in the outermost layer but leave the stubbed result on `save` dynamic.

The first thing we do is just verify that we interact with the object correctly. That is, we verify that we called `save`. We verify this because `save` is a "command" message. We are telling our collaborating object to do something.

Then we have different contexts representing the different outcomes of that collaboration. We can then verify we get the expected results for each case.

```ruby
context 'when testing generic object interaction' do
  describe '#persist' do
    let(:model) { double :model, save: persistence_result }
    let(:persistence_result) { true }

    it 'calls "save" on the model' do
      expect(model).to receive(:save)
      persist model
    end

    context 'when the model persists successfully' do
      let(:persistence_result) { true }

      it 'returns the persisted model' do
        expect(persist model).to eq model
      end
    end

    context 'when the model fails to persist' do
      let(:persistence_result) { false }

      it 'returns nil' do
        expect(persist model).to be_nil
      end
    end
  end
end
```

Results when run:

```bash
when testing generic object interaction
  #persist
    calls "save" on the model
    when the model persists successfully
      returns the persisted model
    when the model fails to persist
      returns nil
```


Alternatively if we have a function that is expecting a very specific type of input, we should use a specific mock based on the type of object. This will ensure we are not trying to stub methods that don't exist on the real object. It is preferable though, when possible, to create generic functions. But for the point of illustration we'll make a `persist_user` function that wants a `User` passed in.

```ruby
def persist_user user
  return user if user.save
end

class User
  def save
  end
end
```

We now have our function and a simple `User` class that exposes `save` method.

Our spec will look very much the same, but take note we are constructing our mock differently and instead of a generic double asking for a double based on a new `User`.

```ruby
context 'when testing specific object interaction' do
  describe '#persist_user' do
    let(:user) { object_double User.new, save: persistence_result }
    let(:persistence_result) { true }

    it 'calls "save" on the user' do
      expect(user).to receive(:save)
      persist_user user
    end

    context 'when the user persists successfully' do
      let(:persistence_result) { true }

      it 'returns the persisted user' do
        expect(persist_user user).to eq user
      end
    end

    context 'when the user fails to persist' do
      let(:persistence_result) { false }

      it 'returns nil' do
        expect(persist_user user).to be_nil
      end
    end
  end
end
```

Results when run:

```bash
when testing specific object interaction
  #persist_user
    calls "save" on the user
    when the user persists successfully
      returns the persisted user
    when the user fails to persist
      returns nil
```

### Find

In this example we have a simple function that uses a collaborating object to try and find a record, presumably from a database. If it fails to find the record, it just wants to create a new record using that same collaborating object.

In this particular case we are not concerned with varying the input to the function but rather the different possible behaviors of our collaborator as how to react to what the collaborator does is where the core logic of our function is.

Note, the `find` method we are calling on our collaborator is a "query" message. We are not telling the object to do something and instead asking for an answer. Therefore we do not verify that we made the call, we merely set things up so the call can succeed.

It could be argued that `new` is also a "query" message, but I've also seen it argued as a "command" since we are telling it to initialize a new object for us. To be safe I've got an expectation that we call `new` as appropriate. Doing a `create` on ActiveRecord would definitely be a "command" style message.

For both examples we'll use a class:

```ruby
class User
  def self.find id
  end
end
```

The preferred method for building this function is with injection support for the collaborating object.

```
def injectable_find_or_create id, repository=User
  repository.find(id) || repository.new
end
```

We have an optional argument that defaults to the repository we want to use, in this case, the `User` class. Since we are dealing with a specific class as our collaborator, we want to use a `class_double`. We will then set it up so it responds as we desire and assert that our function does what it was designed to do. Using the `class_double` will verify our stub functions actually exist on the class. Everytime we call the fuction in a test we will also provide the optional argument of the repository we want to use.


```ruby
context 'when using injection' do
  describe '#find_or_create' do
    let(:repository) { class_double 'User', find: repository_result, new: :new_record }

    context 'when the record is found' do
      let(:repository_result) { :existing_record }

      it 'returns the existing record' do
        expect(injectable_find_or_create 123, repository).to eq :existing_record
      end
    end

    context 'when the record is not found' do
      let(:repository_result) { nil }

      it 'uses repository to create a new user' do
        expect(repository).to receive :new
        injectable_find_or_create 123, repository
      end

      it 'returns a new record' do
        expect(injectable_find_or_create 123, repository).to eq :new_record
      end
    end
  end
end
```

Results when run:

```bash
when using injection
  #find_or_create
    when the record is found
      returns the existing record
    when the record is not found
      uses repository to create a new user
      returns a new record
```

Alternatively, if we don't use injection, we can create our `class_double` as a stubbed constant. That means everywhere we use that class we'll actually get our stubbed class. This isn't as nice as injection, but there are many cases where this may end up being the better way to go. Our spec will look almost the same, but this time we are not passing in an extra argument and we have created our mock slightly different.

First our new function that is not injectable:

```ruby
def find_or_create id
  User.find(id) || User.new
end
```

And our spec then is:

```ruby
context 'when stubbing constants' do
  describe '#find_or_create' do
    before { class_double('User', find: repository_result, new: :new_record).as_stubbed_const }

    context 'when the record is found' do
      let(:repository_result) { :existing_record }

      it 'returns the existing record' do
        expect(find_or_create 123).to eq :existing_record
      end
    end

    context 'when the record is not found' do
      let(:repository_result) { nil }

      it 'uses User to create a new user' do
        expect(User).to receive :new
        find_or_create 123
      end

      it 'returns a new record' do
        expect(find_or_create 123).to eq :new_record
      end
    end
  end
end
```

Results when run:

```bash
when stubbing constants
  #find_or_create
    when the record is found
      returns the existing record
    when the record is not found
      uses User to create a new user
      returns a new record
```

### Car

We've focused a lot about specs for functions. The main reason for this is our current code bases are "function heavy". We have a lot constant functions, but fewer actual classes and instances of classes. However you will write specs for Classes and Objects, especially models. In this example we will deal with testing an instance of a class. This object has a collaborating object, which is optionally injectable. It's a very simple class overall but shows how to test the public interface of the object as well as to verify it works with it's collaborators correctly.

We will use two classes for this example:

```ruby
class FuelTank
  def fuel
  end

  def burn gallons
  end
end

class Car
  attr_reader :color, :fuel_tank, :odometer

  def initialize color, fuel_tank=FuelTank.new
    @color = color
    @fuel_tank = fuel_tank
    @odometer = 0
  end

  def popular?
    color == :red
  end

  def range
    fuel_tank.fuel * 20
  end

  def drive miles
    fuel_tank.burn(miles / 20)
    @odometer += miles
  end
end
```

For the `FuelTank` we are going to use a mock because in this fictional example the `burn` method actually touches an external system. We will inject this mock to use instead of our real `FuelTank`. Since we are expecting a `FuelTank` then we use an `instance_double` when creating the mock. This will ensure that the stubbed methods actually exist on an instance of that class.

Note again, that we have both a "query" message `fuel` and a "command" method `burn`. We only put an expectation around the "command" method being called.

```ruby
describe Car do
  subject(:car) { Car.new color, fuel_tank }
  let(:fuel_tank) { instance_double 'FuelTank', fuel: fuel, burn: nil }
  let(:color) { :white }
  let(:fuel) { 0 }

  describe '#popular?' do
    context 'when the car is red' do
      let(:color) { :red }

      it { is_expected.to be_popular }
    end

    context 'when the car is blue' do
      let(:color) { :blue }

      it { is_expected.to_not be_popular }
    end
  end

  describe '#range' do
    context 'with a tank with 3 gallons of fuel' do
      let(:fuel) { 3 }

      specify { expect(car.range).to eq 60 }
    end

    context 'with a tank with 5 gallons of fuel' do
      let(:fuel) { 5 }

      specify { expect(car.range).to eq 100 }
    end
  end

  describe '#drive' do
    context 'when driving 20 miles' do
      let(:fuel) { 1 }

      specify { expect { car.drive 20 }.to change(car, :odometer).by 20 }

      it 'burns 1 gallon of fuel' do
        expect(fuel_tank).to receive(:burn).with 1
        car.drive 20
      end
    end

    context 'when driving 40 miles' do
      let(:fuel) { 2 }

      specify { expect { car.drive 40 }.to change(car, :odometer).by 40 }

      it 'burns 2 gallons of fuel' do
        expect(fuel_tank).to receive(:burn).with 2
        car.drive 40
      end
    end
  end
end
```

Results when run:

```bash
Car
  #popular?
    when the car is red
      should be popular
    when the car is blue
      should not be popular
  #range
    with a tank with 3 gallons of fuel
      should eq 60
    with a tank with 5 gallons of fuel
      should eq 100
  #drive
    when driving 20 miles
      should change #odometer by 20
      burns 1 gallon of fuel
    when driving 40 miles
      should change #odometer by 40
      burns 2 gallons of fuel
```

### Model Specs

Our ActiveRecord models should have relationships defined as well as validations. There may be other methods as well, but those are the primary types of things on models. If there are other public methods those should be tested in much the same way as other Classes like in the `Car` example. A method added to a model should not persist the model. Helper methods can change the attributes on a model in a useful way, but they should not persist those changes. It should be up to the outside holder of the model to decide if it should be persisted. As such it should be perfectly safe to call and test methods on a model without having to have a database hit or stub our object under test.

```
class User < ActiveRecord::Base
  has_secure_password
  
  has_many :sessions
  belongs_to :company
  
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
end
```

Note when we test this model, and specifically test the uniqueness, it will hit the database. This is our one exception to the database rule. For testing relationships and validations we use the [Shoulda](https://github.com/thoughtbot/shoulda) gem and their awesome matchers.

```
describe User, type: :model do
  it { is_expected.to have_secure_password }
  it { is_expected.to have_many :sessions }
  it { is_expected.to belong_to :company }
  it { is_expected.to validate_presence_of :email }
  it { is_expected.to validate_uniqueness_of :email }
  it { is_expected.to have_db_index :email }
  it { is_expected.to validate_presence_of :name }
end
```

Result when run:

```bash
User
  should have a secure password
  should have many sessions
  should belong to company
  should require email to be set
  should require case sensitive unique value for email
  should have an index on columns email
  should require name to be set
```

### Persist Component

In our current codebases we use a lot of standalone functions called `Components`. These are either directly lambdas, or are indirectly lambdas produced by a higher order function that takes mata/configuration arguments.

There is not much difference between these tests and the tests described under the function examples. Key differences are our lambdas always take an input hash and return an `Either` (`Right` or `Left`). An `Either` has various predicates that can be used to easily check in a spec what you have: `right?`, `success?`, `left?`, `failure?`.

As a general strategy you should minimize the input to just what is needed for testing the component. It may well be that you expect other things to be in the input hash when the component is typically used, but if they have no bearing on the function you are testing, leave them out of the input.

Since `Persist` is a higher order function we have a spec to ensure that given the expected arguments, we get a `callable` thing back (i.e. a lambda).

We then turn our focus to actually testing the lambda, varying both the meta input to the `Persist[]` function as well as the input hash as necessary. Note, many of our components, especially the common components, work on a large variety of objects, usually all different models. So we use generic `double` most of the time, or if not persisting, the actual real model.

Here we have a real component from our system:

```ruby
module Components
  module Common
    module Persist
      def self.[] model:
        -> (input) {
          if input[model].save
            Right input
          else
            Left input[model].errors.full_messages
          end
        }
      end
    end
  end
end
```

And here is a reasonable spec for that component:

```ruby
module Components
  module Common
    module Persist
      describe '.[]' do
        it 'returns a callable' do
          expect(Persist[model: :user]).to respond_to(:call)
        end
      end

      describe '.[]#call' do
        context 'when persisting the model under :user' do
          let(:input) { { user: double(:user, save: save_result) } }
          let(:save_result) { true }

          it 'saves the object in the input under the key :user' do
            expect(input[:user]).to receive(:save)
            Persist[model: :user].call input
          end

          context 'when the save is successful' do
            let(:save_result) { true }

            it 'returns a successful result' do
              expect(Persist[model: :user].call input).to be_success
            end

            it 'returns the input' do
              expect(Persist[model: :user].call(input).value).to eq input
            end
          end

          context 'when the save fails' do
            let(:save_result) { false }
            before { allow(input[:user]).to receive_message_chain('errors.full_messages').and_return :errors }

            it 'returns a failure result' do
              expect(Persist[model: :user].call input).to be_failure
            end

            it 'returns the errors' do
              expect(Persist[model: :user].call(input).value).to eq :errors
            end
          end
        end

        context 'when persisting the model under :game' do
          let(:input) { { game: double(:game, save: save_result) } }
          let(:save_result) { true }

          it 'saves the object in the input under the key :game' do
            expect(input[:game]).to receive(:save)
            Persist[model: :game].call input
          end
        end
      end
    end
  end
end
```

Result when run:

```bash
.[]
  returns a callable

.[]#call
  when persisting the model under :user
    saves the object in the input under the key :user
    when the save is successful
      returns a successful result
      returns the input
    when the save fails
      returns a failure result
      returns the errors
  when persisting the model under :game
    saves the object in the input under the key :game
```

