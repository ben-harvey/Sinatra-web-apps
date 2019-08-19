<h2><strong><em>Classes and Objects</em></strong></h2>

<p>Classes are the blueprint for objects, containing the common attributes and behaviors that will be present in all objects of the class.</p>

<pre><code class="ruby">class Car
end
</code></pre>

<img src="/images/NeoEggplant.jpg">

<p>This code defines the class <code>Car</code>.</p>

<p>Objects are created from classes.  Each object has its own unique state, stored in its instance variables.</p>

<pre><code class="ruby">my_car = Car.new
</code></pre>

<p>This code instantiates a new object of class <code>Car</code> and stores it in the local variable <code>my_car</code>.</p>

<h2><strong><em>Encapsulation</em></strong></h2>

<p>In procedural programming, once a local variable is initialized it can be accessed from anywhere in the program. This can lead to issues with dependency and makes large code bases tricky. In OOP, data is not accessed directly. By being grouped together in a class, data is both organized and also protected. Since attributes are private from outside the class they can only be accessed explicitly through methods.</p>

<pre><code class="ruby">class Cat
  @color = ‘red’
end
cat = Cat.new
cat.color # NoMethodError
</code></pre>

<p><strong><em>Use  `attr_</em>`  to create setter and getter methods</strong>*</p>

<p>In Ruby, variables initialized inside classes are only accessible outside of classes through the use of methods.  Methods that access variables are called getters or readers, while methods that (re)assign variables are called setters or writers.
<code>ruby
class Book
  def title # instance getter
    @title
  end
  def @title=(new_title) # instance setter
    @title = new_title
  end
end
book = Book.new
book.title = 'Life of Pi'
puts book.title # 'Life of Pi'
</code>
The <code>Module#attr</code>  methods provide a convenient shortcut for the above instance methods.  <code>attr_reader</code> creates a setter method equivalent to the above, while <code>attr_writer</code> creates a getter method equivalent to the above.  Both methods create a corresponding instance variable (that is not actually initialized until the method is called).  <code>attr_accessor</code> bundles the functionality of <code>attr_reader</code> and <code>attr_writer</code> together in one method.</p>

<h2><strong><em>How to call setters and getters</em></strong></h2>

<p>To call a getter or setter method you invoke the instance method on an instance of the object.
<code>ruby
class Book
  attr_accessor :title
end
book = Book.new
book.title = 'Life of Pi'
book.title # 'Life of Pi'
</code>
In the code above we instantiated an object <code>book</code>of the <code>Book</code> class then invoked the <code>title=</code> instance method. This assigned the string <code>'Life of Pi'</code> to the <code>@title</code> instance variable.  Then we called the <code>title</code> instance methods on the same object, the return value being the string <code>'Life of Pi'</code> referenced by <code>@title</code>.</p>

<h2><strong><em>Instance methods vs. class methods</em></strong></h2>

<p>Instance methods are called on instances of a class.  Their method names are defined without <code>self</code>
<code>ruby
class Mouse
  def sqeak
    puts 'squeak!'
  end
end
stuart = Mouse.new
stuart.squeak # 'squeak!'
</code>
Class methods are called on the class itself. When they are defined, the method name is prepended by the reserved word <code>self</code>
<code>ruby
class Mouse
  def self.squeak
    puts 'classy squeak!'
  end
end
Mouse.squeak # 'classy squeak!'
</code></p>

<h2><strong><em>Referencing and setting instance variables vs. using getters and setters</em></strong></h2>

<p>The <code>attr</code> methods are vanilla getters and setters, meaning that they will return or set the instance variable without any other manipulation.
<code>ruby
class Car
  attr_accessor :wheels
  def show_wheels
    puts "This car has #{wheels} wheels."
    puts "This car has #{@wheels} wheels."
  end
  def change_wheels(new_number)
    # wheels = new_number   Ruby thinks this is local variable initialization
    self.wheels = new_number
    @wheels = new_number
  end
end
</code>
In <code>show_wheels</code>, the return value of <code>wheels</code>  will be equal to <code>@wheels</code>.  Note that in the case of calling the setter method for reassignment, <code>self</code> must be prepended to the setter, or the instance variable <code>@wheels</code> used directly, to disambiguate from local variable initialization.
Things change when custom setters and getters are implemented:
```ruby
class GasError < StandardError; end</p>

<p>class Vehicle
  attr_reader :gas
  def gas=(amount)
    if amount < 0
        raise GasError, "Cannot add negative amount"
    else @gas = amount
    end
  end</p>

<p>def add_gas(gallons)
      #self.gas += gallons  Calls custom setter
    @gas += gallons # allows for negative gas amounts
  end
end</p>

<p>car = Vehicle.new
car.gas = 10
puts car.gas # 10
car.add_gas(-20)
puts car.gas # -10</p>

<pre><code>In this case, by reassigning the instance variable `@gas` directly, we have circumvented the input validation in our custom setter and allowed for negative gas amounts.  This is why it is preferred to use setter and getter methods when they are available.

## ***Class inheritance***

Inheritance models an 'is-a' relationship.  For example, a car *is a* vehicle. Therefore a `Car` object should inherit attributes and behaviors from a `Vehicle` parent class.
```ruby
class Vehicle
  def honk
    puts "HONK!"
  end
class Car < Vehicle; end
</code></pre>

<ul>
<li>Inheritance is a way to keep code DRY by sharing common code among similar objects.</li>
<li>Ruby only allows a class to inherit from a single parent.</li>
<li>All classes automatically inherit from <code>Object</code>, which inherits from <code>BasicObject</code></li>
</ul>

<h2><strong><em>Polymorphism</em></strong></h2>

<p>Polymorphism is the ability to provide a common interface to different types of data.
```ruby
class Animal
  def speak
    # generic speak behaviour here
  end
end</p>

<p>class Cat < Animal
  def speak
    # specific Cat speak behaviour here
  end
end</p>

<p>class Dog < Animal
  def speak
    # specific Dog speak behaviour here
  end
end</p>

<p>pets = [Dog.new, Cat.new]
pets.each do |pet|
  pet.speak # common interface for different object types
end
```</p>

<h2><strong><em>Modules</em></strong></h2>

<p>Modules have several uses:
- They can be mixed in to classes as a way to provide common behaviors to multiple classes.
 ```ruby
module Honkable
  def honk
    puts 'HONK!'
  end
end</p>

<p>class Car
  include Honkable
end</p>

<p>class Truck
  include Honkable
end</p>

<p>Car.new.honk # 'HONK!'
Truck.new.honk # 'HONK!'
<code>
` They can be used to group like classes together (namespacing), also preventing identical class names from overwriting each other.
</code>ruby
module Building
  class Restaurant; end
  class Library; end
  class PostOffice; end
  class Bar; end
end</p>

<p>module Candy
  class Bar; end
end</p>

<p>Building::Bar.new
Candy::Bar.new
``<code>
- Modules can also be a container for methods that have no other logical home.  Such methods are called with</code>Module.method` syntax.</p>

<h2><strong><em>Method Lookup Path</em></strong></h2>

<p>The order in which Ruby searches through classes, superclasses and modules to find a method.
```ruby
module Honkable
  def honk
    puts 'HONK!'
  end
end
module Washable; end</p>

<p>class Vehicle
  include Honkable
  include Washable
end</p>

<p>class Car < Vehicle; end
Car.new.honk # Lookup path:  Car, Vehicle, Washable, Honkable
```
<em>Lookup order</em>
1.  the calling class
2.  any included modules in the calling class, in reverse order of inclusion
3. the superclass
4.  any included modules in  the superclass, in reverse order of inclusion
5. Object class, Kernel module, BasicObject class (all Ruby classes inherit and mix-in these)</p>

<h2><em>Calling methods with self</em></h2>

<p>In the case of calling a setter method for reassignment, <code>self</code> must be prepended to the setter, or the instance variable used directly, to disambiguate from local variable initialization. (see <em>Referencing and setting instance variables vs. using getters and setters</em>)</p>

<h2><strong><em>More about self</em></strong></h2>

<p>Outside of an instance method, the reserved word <code>self</code> refers to the class itself.  Inside an instance method, <code>self</code> refers to the instance object of the class.
```ruby
class Demo
  def self.outside<em>instance</em>method
    p self
  end</p>

<p>def inside<em>instance</em>method
    p self
  end
end
Demo.outside<em>instance</em>method # Demo
Demo.outside<em>instance</em>method.respond<em>to?(:new) # true
Demo.new.inside</em>instance_method # #<a href="Demo:0x0000558453a14618">Demo:0x0000558453a14618</a>
```</p>

<h2><strong><em>Fake operators</em></strong></h2>

<p>Due to Ruby's syntactical sugar, many things that look like operators are actually method calls.
<code>ruby
2 + 2 # 4
2.+(2) # 4
</code>
 This means that their functionality can be overridden to provide more meaningful functions for custom classes.  Common examples include <code>+</code>, <code>-</code>, <code>==</code>, <code>></code>, <code><</code>.
 ```ruby
 class Car
   attr_reader :cost</p>

<p>def initialize(cost)
    @cost = cost
  end</p>

<p>def ==(other)
    cost == other.cost
  end
end
honda = Car.new(5000)
toyota = Car.new(6000)
puts honda == toyota # false
```</p>

<h2><strong><em>Equality</em></strong></h2>

<p><em>Most Important</em></p>

<p><code>==</code></p>

<ul>
<li>  the  <code>==</code>  operator compares two objects' values, and is frequently used.</li>
<li>  the  <code>==</code>  operator is actually a method. Most built-in Ruby classes, like Array, String, Fixnum, etc override the  <code>==</code>method to specify how to compare objects of those classes.</li>
<li>  if you need to compare custom objects, you should override the  <code>==</code>  method.</li>
<li>  understanding how this method works is the most important part of this assignment.</li>
</ul>

<p><em>Less Important</em></p>

<p><code>equal?</code></p>

<ul>
<li>  The  <code>equal?</code>  method goes one level deeper than  <code>==</code>  and determines whether two variables not only have the same value, but also whether they point to the same object. do not override equal?. the equal? method is not used very often. calling object<em>id on an object will return the object's unique numerical value. Comparing two objects' object</em>id has the same effect as comparing them with equal?.</li>
</ul>

<p><code>===</code></p>

<p>used implicitly in case statements. like  <code>==</code>, the  <code>===</code>operator is actually a method. you rarely need to call this method explicitly, and only need to implement it in your custom classes if you anticipate your objects will be used in case statements, which is probably pretty rare.</p>

<p><code>eql?</code></p>

<p>used implicitly by Hash. very rarely used explicitly.</p>

<h2><strong><em>Collaborator Objects</em></strong></h2>

<p>Collaborator objects are objects that are stored as state within another object.  Collaborator objects model a 'has-a' relationship in OOP, for example a Car object <em>has a</em> SoundSystem object.
```ruby
class SoundSystem; end</p>

<p>class Car
  def initialize
    @sound_system = SoundSystem.new
  end
end
```
Collaborator objects don't need to be a custom object, but can be strings, arrays, hashes, or any object that makes sense in an OOP design.</p>
