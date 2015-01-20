module Configurator
  class Processor
    attr_reader :cache

    def self.process(variables, processors)
      processor = self.new(variables, processors)
      OpenStruct.new(processor.cache)
    end

    def initialize(variables, processors)
      @variables = variables
      @processors = processors
      @cache = variables

      processors.each do |key, block|
        @cache[key] = block.call(@cache)
      end
    end
  end
end
