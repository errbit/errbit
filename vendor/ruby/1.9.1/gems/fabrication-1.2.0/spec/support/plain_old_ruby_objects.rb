require 'ostruct'

class ParentRubyObject
  attr_accessor \
    :before_save_value,
    :collection_field,
    :dynamic_field,
    :nil_field,
    :number_field,
    :string_field

  def initialize
    self.before_save_value = 11
  end

  def persisted?; true end
end

class ChildRubyObject
  attr_accessor \
    :parent,
    :number_field

  def persisted?; true end
end

class Dog
  attr_accessor :name, :breed, :locations
end

class Location
  attr_accessor :lat, :lng
end

class Person
  attr_accessor :age, :first_name, :last_name, :shoes, :location
end

class City
  attr_accessor :city, :state

  def initialize(city, state)
    self.city = city
    self.state = state
  end
end

class Address
  attr_accessor :city, :state
end

class Contact
  attr_accessor :name, :address
end

module Something
  class Amazing
    attr_accessor :stuff
  end
end

class Sequencer
  attr_accessor :simple_iterator, :param_iterator, :block_iterator

  class Namespaced
    attr_accessor :iterator
  end
end
