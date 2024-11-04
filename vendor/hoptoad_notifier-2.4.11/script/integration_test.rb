#!/usr/bin/env ruby

require 'logger'
require 'fileutils'

RAILS_ENV = "production"
RAILS_ROOT = FileUtils.pwd
RAILS_DEFAULT_LOGGER = Logger.new(STDOUT)

$: << File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'hoptoad_notifier'
require 'rails/init'

fail "Please supply an API Key as the first argument" if ARGV.empty?

host = ARGV[1]
host ||= "hoptoadapp.com"

secure = (ARGV[2] == "secure")

exception = begin
              raise "Testing hoptoad notifier with secure = #{secure}. If you can see this, it works."
            rescue => foo
              foo
            end

HoptoadNotifier.configure do |config|
  config.secure  = secure
  config.host    = host
  config.api_key = ARGV.first
end
puts "Configuration:"
HoptoadNotifier.configuration.to_hash.each do |key, value|
  puts sprintf("%25s: %s", key.to_s, value.inspect.slice(0, 55))
end
puts "Sending #{secure ? "" : "in"}secure notification to project with key #{ARGV.first}"
HoptoadNotifier.notify(exception)

