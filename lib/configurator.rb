require "ostruct"

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
  # @param Hash map of configuration keys with array values where the array is
  #   a list of environment variables to scan for configuration
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
    @mapping.each do |key, values|
      @overrides[key] = values.pop if values.last.is_a? Proc
      env_name = values.find { |v| ENV[v] }
      @storage[key] = if env_name
        ENV[env_name].empty? ? "" : YAML.parse(ENV[env_name]).to_ruby
      end
    end
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
