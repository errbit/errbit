require 'rubygems'
require 'bundler/setup'

require 'spec'
require File.expand_path('../../lib/happymapper', __FILE__)

def fixture_file(filename)
  File.read(File.dirname(__FILE__) + "/fixtures/#{filename}")
end