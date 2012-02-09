$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'mongo'
require 'test/unit'
require './test/test_helper'

class ForkTest < Test::Unit::TestCase
  include Mongo

  def setup
    @conn = standard_connection
  end

  def test_fork
    # Now insert some data
    10.times do |n|
      @conn[MONGO_TEST_DB]['nums'].insert({:a => n})
    end

    # Now fork. You'll almost always see an exception here.
    if !Kernel.fork
      10.times do
        assert @conn[MONGO_TEST_DB]['nums'].find_one
      end
    else
      10.times do
        assert @conn[MONGO_TEST_DB]['nums'].find_one
      end
    end
  end
end
