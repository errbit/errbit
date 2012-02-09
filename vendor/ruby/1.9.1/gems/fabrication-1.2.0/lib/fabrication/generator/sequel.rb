class Fabrication::Generator::Sequel < Fabrication::Generator::Base

  def self.supports?(klass)
    defined?(Sequel) && klass.ancestors.include?(Sequel::Model)
  end

  def after_generation(options)
    instance.save if options[:save]
  end

end
