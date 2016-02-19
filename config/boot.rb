require 'rubygems'

detected_ruby_version = Gem::Version.new(RUBY_VERSION.dup)
required_ruby_version = Gem::Version.new('2.1.0') # minimum supported version

if detected_ruby_version < required_ruby_version
  fail "RUBY_VERSION must be at least #{required_ruby_version}, " \
       "detected RUBY_VERSION #{RUBY_VERSION}"
end

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
require 'json'

begin
  # try to use Yajl, the json_gem compatibility layer must be loaded after json
  require 'yajl/json_gem'
rescue LoadError
  warn "JSON: unable to load Yajl; just using the json gem"
end
