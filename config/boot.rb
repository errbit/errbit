require 'rubygems'

if RUBY_VERSION.to_f >= 1.9
  # The psych engine for YAML doesn't handle `<<: *defaults` properly.
  # See: https://github.com/tenderlove/psych/issues/8
  require 'yaml'
  YAML::ENGINE.yamler = 'syck'
end

# Set up gems listed in the Gemfile.
gemfile = File.expand_path('../../Gemfile', __FILE__)
begin
  ENV['BUNDLE_GEMFILE'] = gemfile
  require 'bundler'
  Bundler.setup
rescue Bundler::GemNotFound => e
  STDERR.puts e.message
  STDERR.puts "Try running `bundle install`."
  exit!
end if File.exist?(gemfile)

