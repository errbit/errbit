require 'test/test_helper'
include Mongo

class ConnectionTest < Test::Unit::TestCase
  context "Initialization: " do

    context "given async connection options" do

      should "default the workers pool to 1" do
        Async::WorkerPool.expects(:new).with(1)

        Connection.new('localhost', 27017)
      end

      should "override the workers pool size with the :worker_pool_size key" do
        size = 6
        Async::WorkerPool.expects(:new).with(size)

        Connection.new('localhost', 27017, :worker_pool_size => size)
      end
    end # context 'given async connection options'

  end # context 'Initialization'
end
