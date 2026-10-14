# frozen_string_literal: true

# Configurator maps lists of environment variables to names that you define in
# order to provide a consistent way to use configuration throughout your
# application
class Configurator
  # Run the configurator and return the processed values
  #
  # @example Simple mapping
  #   ENV['BAR'] = 'onevalue'
  #   ENV['BAZ'] = 'another'
  #
  #   config = Configurator.run({
  #     key_one: ['FOO', 'BAR'],
  #     key_two: ['BAZ']
  #   })
  #
  #   config.key_one
  #   #=> 'onevalue'
  #   config.key_two
  #   #=> 'another'
  #
  # @example Using override blocks
  #   ENV['BAR'] = 'onevalue'
  #   ENV['BAZ'] = 'another'
  #
  #   config = Configurator.run({
  #     key_one: ['FOO', 'BAR', ->(values) {
  #       values[:key_two]
  #     }],
  #     key_two: ['BAZ']
  #   })
  #
  #   config.key_one
  #   #=> 'another'
  #
  # @example Using typed values
  #   config = Configurator.run(
  #     port: {env: 'PORT', type: :integer}
  #   )
  #
  #   config.port
  #   #=> 3000
  #
  # @param [Hash] mapping configuration keys mapped to legacy environment-name
  #   arrays or typed definitions with :env, :type, and optional :override keys
  #   Supported types are :boolean, :integer, :string_array, and :integer_array.
  # @return OpenStruct configuration object
  def self.run(mapping)
    reader = new(mapping)
    reader.read
  end

  # Create the Configurator object
  #
  # @param [Hash] mapping mapping of config names to environment value names
  # @return [Configurator]
  def initialize(mapping)
    @mapping = mapping
    @overrides = {}
    @storage = {}
  end

  # Process the environment variable values and store the overrides
  def scan
    @mapping.each do |key, definition|
      env_names, type, override = parse_definition(definition)
      @overrides[key] = override if override
      env_name = env_names.find { |name| ENV[name] }
      @storage[key] = parse_value(ENV[env_name], type, env_name) if env_name
    end
  end

  def parse_definition(definition)
    if definition.is_a?(Hash)
      env_names = Array(definition.fetch(:env))
      raise ArgumentError, "configuration environment names cannot be empty" if env_names.empty?

      [env_names, definition[:type], definition[:override]]
    else
      values = Array(definition).dup
      override = values.pop if values.last.is_a? Proc
      [values, nil, override]
    end
  end

  def parse_value(value, type, env_name)
    return value.empty? ? "" : YAML.parse(value).to_ruby unless type

    case type
    when :boolean
      parse_boolean(value, env_name)
    when :integer
      parse_integer(value, env_name)
    when :string_array
      parse_array(value, env_name) { |item| item.to_s.strip }
    when :integer_array
      parse_array(value, env_name) { |item| parse_integer(item, env_name) }
    else
      raise ArgumentError, "Unsupported configuration type #{type.inspect}"
    end
  end

  def parse_boolean(value, env_name)
    value = strip_quotes(value.to_s.strip)
    raise ArgumentError, "#{env_name} cannot be empty" if value.empty?

    case value.downcase
    when "true" then true
    when "false" then false
    else
      raise ArgumentError, "#{env_name} must be true or false"
    end
  end

  def parse_integer(value, env_name)
    value = strip_quotes(value.to_s.strip)
    raise ArgumentError, "#{env_name} cannot be empty" if value.empty?

    begin
      Integer(value, 10)
    rescue ArgumentError
      raise ArgumentError, "#{env_name} must contain an integer, got #{value.inspect}"
    end
  end

  def parse_array(value, env_name)
    value = value.to_s.strip
    raise ArgumentError, "#{env_name} cannot be empty" if value.empty?

    value = strip_quotes(value)
    values = if value.start_with?("[") || value.end_with?("]")
      unless value.start_with?("[") && value.end_with?("]")
        raise ArgumentError, "#{env_name} must contain a valid list"
      end

      parse_yaml_array(value, env_name)
    else
      value.split(",")
    end

    if values.any? { |item| item.to_s.strip.empty? }
      raise ArgumentError, "#{env_name} must not contain empty list elements"
    end

    values.map { |item| yield item }
  end

  def strip_quotes(value)
    if value.match?(/\A(['"]).*\1\z/)
      value[1...-1]
    else
      value
    end
  end

  def parse_yaml_array(value, env_name)
    parsed = YAML.safe_load(value, permitted_classes: [], aliases: false)
    raise ArgumentError, "#{env_name} must contain a list" unless parsed.is_a?(Array)

    parsed
  rescue Psych::Exception
    raise ArgumentError, "#{env_name} must contain a valid list"
  end

  # Apply the override functions
  def apply_overrides
    @overrides.each do |key, override|
      @storage[key] = override.call(@storage)
    end
  end

  # Perform all the required processing and return the configuration object
  #
  # @return [OpenStruct] configuration object
  def read
    @storage = {}
    scan
    apply_overrides

    OpenStruct.new(@storage)
  end
end
