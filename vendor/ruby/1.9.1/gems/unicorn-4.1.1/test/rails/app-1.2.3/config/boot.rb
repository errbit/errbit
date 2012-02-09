# -*- encoding: binary -*-

unless defined?(RAILS_ROOT)
  root_path = File.join(File.dirname(__FILE__), '..')
  RAILS_ROOT = root_path
end

unless defined?(Rails::Initializer)
  require "#{RAILS_ROOT}/vendor/rails/railties/lib/initializer"
  Rails::Initializer.run(:set_load_path)
end
