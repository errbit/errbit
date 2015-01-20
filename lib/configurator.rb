module Configurator
  def self.run(mapping, processors)
    Processor.process(Reader.read(mapping), processors)
  end
end
