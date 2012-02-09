class Fabrication::Attribute

  attr_accessor :name, :params, :value

  def initialize(name, params, value)
    self.name = name
    self.params = params
    self.value = value
  end

end
