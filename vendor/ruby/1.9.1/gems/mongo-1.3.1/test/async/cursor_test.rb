require 'test/test_helper'
require 'logger'

class CursorTest < Test::Unit::TestCase

  include Mongo

  @@connection = Connection.new(ENV['MONGO_RUBY_DRIVER_HOST'] || 'localhost',
                        ENV['MONGO_RUBY_DRIVER_PORT'] || Connection::DEFAULT_PORT)
  @@db   = @@connection.db(MONGO_TEST_DB)
  @@coll = @@db.collection('test')
  @@version = @@connection.server_version

  def wait_for_async
    sleep 0.2
  end

  def setup
    @@coll.remove
    @@coll.insert('a' => 1)     # collection not created until it's used
    @@coll_full_name = "#{MONGO_TEST_DB}.test"
  end

  def test_async_explain
    failsafe = mock('failsafe will get called in block', :call => true)

    cursor = @@coll.find('a' => 1)

    cursor.explain(:async => true) do |error, result|
      assert_not_nil result['cursor']
      assert_kind_of Numeric, result['n']
      assert_kind_of Numeric, result['millis']
      assert_kind_of Numeric, result['nscanned']
      failsafe.call
    end
    wait_for_async
  end

  def test_async_count
    failsafe = mock('failsafe will get called in block')
    failsafe.expects(:call).times(3)

    @@coll.remove

    @@coll.find.count(:async => true) do |error, count|
      assert_equal 0, count
      failsafe.call
    end
    wait_for_async

    10.times do |i|
      @@coll.save("x" => i)
    end

    @@coll.find.count(:async => true) do |error, count|
      assert_equal 10, count
      failsafe.call
    end
    wait_for_async

    @@coll.find({"x" => 1}).count(:async => true) do |error, count|
      assert_equal 1, count
      failsafe.call
    end
    wait_for_async
  end

  def test_async_close
    failsafe = mock('failsafe will get called in block', :call => true)

    @@coll.remove
    cursor = @@coll.find
    
    cursor.close(:async => true) do |error, result|
      assert_nil error
      assert result
      assert cursor.closed?
      failsafe.call
    end
    wait_for_async
  end

  def test_async_has_next
    failsafe = mock('failsafe will get called in block', :call => true)

    @@coll.remove
    200.times do |n|
      @@coll.save("x" => n)
    end

    cursor = @@coll.find
    cursor.has_next?(:async => true) do |error, result|
      assert_nil error
      assert result
      failsafe.call
    end
    wait_for_async
  end

  def test_async_next_document
    failsafe = mock('failsafe will get called in block')
    failsafe.expects(:call).times(2)

    @@coll.remove
    200.times do |n|
      @@coll.save("x" => n)
    end

    cursor = @@coll.find
    cursor.next_document(:async => true) do |error, result|
      assert_nil error
      assert result
      failsafe.call
    end
    wait_for_async

    callback = Proc.new do |error, result| 
      assert_nil error
      assert result
      failsafe.call
    end

    cursor.next_document(:async => true, :callback => callback)
    wait_for_async
  end

  def test_async_to_a
    failsafe = mock('failsafe will get called in block')
    failsafe.expects(:call)

    @@coll.remove
    total = 200
    total.times do |n|
      @@coll.save("x" => n)
    end

    cursor = @@coll.find
    cursor.to_a(:async => true) do |error, result|
      assert_nil error
      assert_equal total, result.size
      failsafe.call
    end
    wait_for_async
  end

  def test_async_each
    @@coll.remove
    total = 200
    total.times do |n|
      @@coll.save("x" => n)
    end

    cursor = @@coll.find
    count = 0
    cursor.each(:async => true) do |error, result|
      count += 1
    end
    wait_for_async
    
    assert_equal total, count
  end
end
