require 'yaml'

module Configurator
  def self.run(mapping, processors)
    Processor.process(Reader.read(mapping), processors)
  end

  class Reader
    attr_reader :variables

    def self.read(mapping)
      reader = self.new(mapping)
      reader.read
      reader.variables
    end

    def initialize(mapping)
      @mapping = mapping
      @variables = {}
    end

    def read
      @mapping.each do |key, values|
        env_name = values.find { |v| ENV[v] }

        @variables[key] = YAML.parse(ENV[env_name]).to_ruby if env_name
      end
    end
  end
end
