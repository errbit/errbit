require 'rubygems'
gem 'minitest' # ensures you're using the gem, and not the built in MT
$: << File.expand_path(File.dirname(__FILE__) + "../lib")

require 'minitest/autorun'
require 'minitest/pride'
require 'mocha'

require 'fogbugz'

class FogTest < MiniTest::Unit::TestCase
  def self.test(description, &block)
    define_method("test_" + description.split.join('_').gsub(/\W/, ''), block)
  end
end
