class Fabrication::Schematic

  GENERATORS = [
    Fabrication::Generator::ActiveRecord,
    Fabrication::Generator::Sequel,
    Fabrication::Generator::Mongoid,
    Fabrication::Generator::Base
  ]

  attr_accessor :generator, :klass
  def initialize(klass, &block)
    self.klass = klass
    self.generator = GENERATORS.detect { |gen| gen.supports?(klass) }
    instance_eval(&block) if block_given?
  end

  def after_build(&block)
    callbacks[:after_build] ||= []
    callbacks[:after_build] << block
  end

  def after_create(&block)
    callbacks[:after_create] ||= []
    callbacks[:after_create] << block
  end

  def attribute(name)
    attributes.select { |a| a.name == name }.first
  end

  def append_or_update_attribute(attribute)
    if index = attributes.index { |a| a.name == attribute.name }
      attributes[index] = attribute
    else
      attributes << attribute
    end
  end

  attr_writer :attributes
  def attributes
    @attributes ||= []
  end

  attr_writer :callbacks
  def callbacks
    @callbacks ||= {}
  end

  def generate(options={}, overrides={}, &block)
    new_schematic = merge(overrides, &block)
    new_schematic.instance_eval do
      if options[:attributes]
        to_hash(generator.new(klass).generate({:save => false}, attributes, callbacks))
      else
        generator.new(klass).generate(options, attributes, callbacks)
      end
    end
  end

  def initialize_copy(original)
    self.callbacks = {}
    original.callbacks.each do |type, callbacks|
      self.callbacks[type] = callbacks.clone
    end

    self.attributes = original.attributes.clone
  end

  def init_with(*args)
    args
  end

  def merge(overrides={}, &block)
    clone.tap do |schematic|
      schematic.instance_eval(&block) if block_given?
      overrides.each do |name, value|
        schematic.append_or_update_attribute(Fabrication::Attribute.new(name.to_sym, nil, value))
      end
    end
  end

  def method_missing(method_name, *args, &block)
    method_name = parse_method_name(method_name, args)
    if args.empty? or args.first.is_a?(Hash)
      params = args.first || {}
      value = block_given? ? block : generate_value(method_name, params)
    else
      params = {}
      value = args.first
    end

    append_or_update_attribute(Fabrication::Attribute.new(method_name, params, value))
  end

  def on_init(&block)
    callbacks[:on_init] = block
  end

  def parse_method_name(method_name, args)
    if method_name.to_s.end_with?("!")
      method_name = method_name.to_s.chomp("!").to_sym
      args[0] ||= {}
      args[0][:force] = true
    end
    method_name
  end

  def sequence(name=Fabrication::Sequencer::DEFAULT, start=0, &block)
    name = "#{self.klass.to_s.downcase.gsub(/::/, '_')}_#{name}"
    Fabrication::Sequencer.sequence(name, start, &block)
  end

  private

  def generate_value(name, params)
    name = name.to_s
    name = name.singularize if name.respond_to?(:singularize)
    params[:count] ||= 1 if !params[:count] && name != name.to_s
    Proc.new { Fabricate(params[:fabricator] || name.to_sym) }
  end

  def to_hash(object)
    (defined?(HashWithIndifferentAccess) ? HashWithIndifferentAccess.new : {}).tap do |hash|
      attributes.map do |attribute|
        hash[attribute.name] = object.send(attribute.name)
      end
    end
  end

end
