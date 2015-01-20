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
        type     = values.shift
        env_name = values.find { |v| ENV[v] }

        @variables[key] = send(type, ENV[env_name]) if env_name
      end
    end

    def string(v)
      return nil if v == nil

      v.to_s
    end

    def array(v)
      return [] if v == nil

      v.split(',').map(&:strip)
    end

    def boolean(v)
      return false if v == nil
      return false if v == 'false'
      return false if v == 0
      return true  if v == 'true'
      return true  if v == 1
      return true  if v == true
      return false
    end

    def integer(v)
      return nil if v == nil
      v.to_i
    end

    def symbol(v)
      return nil if v == nil
      v.to_sym
    end
  end
end
