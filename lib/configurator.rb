class Configurator
  attr_reader :storage

  def self.run(mapping)
    reader = self.new(mapping)
    reader.read
    OpenStruct.new(reader.storage)
  end

  def initialize(mapping)
    @mapping = mapping
    @storage = {}
    @overrides = {}
  end

  def read
    @mapping.each do |key, values|
      @overrides[key] = values.pop if values.last.is_a? Proc
      env_name = values.find { |v| ENV[v] }
      storage[key] = YAML.parse(ENV[env_name]).to_ruby if env_name
    end

    @overrides.each do |key, override|
      storage[key] = override.call(storage)
    end
  end
end
