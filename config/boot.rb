# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
require 'json'

begin
  # try to use Yajl, the json_gem compatibility layer must be loaded after json
  require 'yajl/json_gem'
rescue LoadError
  # fail silently because json gem is fine
end
