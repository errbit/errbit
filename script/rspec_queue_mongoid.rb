#!/usr/bin/env ruby
require 'rubygems'
require 'test_queue'
require 'test_queue/runner/rspec'

require 'bundler'
Bundler.setup(:default, :development, :test)

class MongoidRspecRunner < TestQueue::Runner::RSpec
  def after_fork(num)
    super
    Mongoid.override_database(
      "#{Mongoid.client(:default).options[:database]}_#{num}"
    )
  end
end

MongoidRspecRunner.new.execute
