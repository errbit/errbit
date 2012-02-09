require 'test/test_helper'
include Mongo

class WorkerPoolTest < Test::Unit::TestCase
  context "Initialization: " do

    def wait_for_async
      sleep 0.2
    end

    setup do
      def new_mock_queue
        stub_everything('queue')
      end

      def new_mock_thread
        stub_everything('thread')
      end
    end

    context "given a size" do
      setup do
        @size = 5
      end

      should "allocate a Thread 'size' times" do
        Queue.stubs(:new).returns(new_mock_queue)
        Thread.expects(:new).times(@size).returns(new_mock_thread)
        Async::WorkerPool.new @size
      end

      should "set 'abort_on_exception' for each current thread" do
        Queue.stubs(:new).returns(new_mock_queue)
        thread = new_mock_thread
        Thread.stubs(:new).returns(thread)

        thread.expects(:abort_on_exception=).with(true).times(@size)

        Async::WorkerPool.new @size
      end

      should "save each thread into the workers queue" do
        assert_equal @size, Async::WorkerPool.new(@size).workers.size
      end

    end # context 'given a size'


    context "given a job" do
      setup do
        @pool = Async::WorkerPool.new 1
        @command = stub_everything('command')
        @cmd_args = stub_everything('command args')
        @callback = stub_everything('callback')
      end

      should "remove nils from the command args array and pass the results to the callback" do
        args = [nil, @cmd_args]
        @command.expects(:call).with(@cmd_args).returns(2)
        @callback.expects(:call).with(nil, 2)

        @pool.enqueue @command, args, @callback
        wait_for_async
      end

      should "execute the original command with args and pass the results to the callback" do
        @cmd_args.expects(:compact).returns(@cmd_args)
        @command.expects(:call).with(@cmd_args).returns(2)
        @callback.expects(:call).with(nil, 2)

        @pool.enqueue @command, @cmd_args, @callback
        wait_for_async
      end

      should "capture any exceptions and pass them to the callback" do
        args = [@cmd_args]
        error = StandardError.new
        @command.expects(:call).with(@cmd_args).raises(error)
        @callback.expects(:call).with(error, nil)

        @pool.enqueue @command, args, @callback
        wait_for_async
      end

      should "abort the thread when the callback raises an exception" do
        args = [@cmd_args]
        error = StandardError.new
        @callback.expects(:call).raises(error)

        assert_raises(StandardError) do
          @pool.enqueue @command, args, @callback
          wait_for_async
        end
      end
    end # context 'given a job'


  end
end
