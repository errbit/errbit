class Fabrication::Generator::Base

  def self.supports?(klass); true end

  def generate(options={:save => true}, attributes=[], callbacks={})
    if callbacks[:on_init]
      self.instance = klass.new(*callbacks[:on_init].call)
    else
      self.instance = klass.new
    end

    process_attributes(attributes)

    callbacks[:after_build].each { |callback| callback.call(instance) } if callbacks[:after_build]
    after_generation(options)
    callbacks[:after_create].each { |callback| callback.call(instance) } if callbacks[:after_create] && options[:save]

    instance
  end

  def initialize(klass)
    self.klass = klass
  end

  def association?(method_name); false end

  def method_missing(method_name, *args, &block)
    if block_given?
      options = args.first || {}
      if !options[:force] && association?(method_name)
        method_name = method_name.to_s
        count = options[:count] || 0

        # copy the original getter
        instance.instance_variable_set("@__#{method_name}_original", instance.method(method_name))

        # store the block for lazy generation
        instance.instance_variable_set("@__#{method_name}_block", block)

        # redefine the getter
        instance.instance_eval %<
          def #{method_name}
            original_value = @__#{method_name}_original.call
            if @__#{method_name}_block
              if #{count} \>= 1
                original_value = #{method_name}= (1..#{count}).map { |i| @__#{method_name}_block.call(self, i) }
              else
                original_value = #{method_name}= @__#{method_name}_block.call(self)
              end
              @__#{method_name}_block = nil
            end
            original_value
          end
        >
      else
        assign(method_name, options, &block)
      end
    else
      assign(method_name, {}, args.first)
    end
  end

  protected

  attr_accessor :klass, :instance

  def after_generation(options)
    instance.save! if options[:save] && instance.respond_to?(:save!)
  end

  def assign(method_name, options, raw_value=nil)
    if options.has_key?(:count)
      value = (1..options[:count]).map do |i|
        block_given? ? yield(instance, i) : raw_value
      end
    else
      value = block_given? ? yield(instance) : raw_value
    end
    instance.send("#{method_name}=", value)
  end

  def post_initialize; end

  def process_attributes(attributes)
    attributes.each do |attribute|
      if Proc === attribute.value
        method_missing(attribute.name, attribute.params, &attribute.value)
      else
        method_missing(attribute.name, attribute.value)
      end
    end
  end

end
