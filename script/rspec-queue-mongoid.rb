#!/usr/bin/env ruby
require 'rubygems'
require 'test_queue'
require 'bundler'
Bundler.setup(:default, :development, :test)
require 'test_queue/runner/rspec'


class MongoidRspecRunner < TestQueue::Runner::RSpec
  def after_fork(num)
    super
    Mongoid.override_database(
      "#{Mongoid.session(:default).options[:database]}_#{num}"
    )
  end
end

MongoidRspecRunner.new.execute
