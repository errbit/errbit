require 'test/test_helper'

class TestCollection < Test::Unit::TestCase
  @@connection ||= Connection.new(ENV['MONGO_RUBY_DRIVER_HOST'] || 'localhost', ENV['MONGO_RUBY_DRIVER_PORT'] || Connection::DEFAULT_PORT)
  @@db   = @@connection.db(MONGO_TEST_DB)
  @@test = @@db.collection("test")
  @@version = @@connection.server_version

  def setup
    @@test.remove
  end

  def wait_for_async
    sleep 0.2
  end

  def test_async_update
    id1 = @@test.save("x" => 5)
    failsafe = mock('failsafe will get called in block', :call => true)

    @@test.update({}, {"$inc" => {"x" => 1}}, :async => true) do |error, result|
      assert_nil error
      assert result
      failsafe.call
    end
    wait_for_async

    assert_equal 1, @@test.count()
    assert_equal 6, @@test.find_one(:_id => id1)["x"]
  end

  if @@version >= "1.1.3"
    def test_async_multi_update
      failsafe = mock('failsafe will get called in block', :call => true)

      @@test.save("num" => 10)
      @@test.save("num" => 10)
      @@test.save("num" => 10)
      assert_equal 3, @@test.count

      @@test.update({"num" => 10}, {"$set" => {"num" => 100}}, :multi => true, :async => true) do |error, result|
        assert_nil error
        assert result
        failsafe.call
      end
      wait_for_async
    end
  end

  def test_async_upsert
    failsafe = mock('failsafe will get called in block')
    failsafe.expects(:call).times(2)

    @@test.update({"page" => "/"}, {"$inc" => {"count" => 1}}, :upsert => true, :async => true) do |error, result|
      assert_nil error
      assert result
      failsafe.call
    end

    @@test.update({"page" => "/"}, {"$inc" => {"count" => 1}}, :upsert => true, :async => true) do |error, result|
      assert_nil error
      assert result
      failsafe.call
    end
    wait_for_async

    assert_equal 1, @@test.count()
    assert_equal 2, @@test.find_one()["count"]
  end

  def test_async_save
    failsafe = mock('failsafe will get called in block', :call => true)

    # note that the first parameter has explicit curly brackets around
    # the hash; without those brackets as a delimiter, the :async key is
    # viewed as part of the required +document+ parameter
    @@test.save({"hello" => "world"}, :async => true) do |error, result|
      assert_nil error
      assert result
      failsafe.call
    end
    wait_for_async
    
    assert_equal "world", @@test.find_one()["hello"]
  end

  def test_async_save_with_exception
    failsafe = mock('failsafe will get called in block', :call => true)

    @@test.create_index("hello", :unique => true)
    @@test.save("hello" => "world")
    
    # all async calls on collections occur in :safe mode
    @@test.save({"hello" => "world"}, :async => true) do |error, result|
      assert error
      assert error.instance_of?(OperationFailure)
      assert_nil result
      failsafe.call
    end
    wait_for_async
    
    assert_equal 1, @@test.count()
    @@test.drop
  end

  def test_async_remove
    failsafe = mock('failsafe will get called in block', :call => true)

    @conn = Connection.new
    @db   = @conn[MONGO_TEST_DB]
    @test = @db['test-async-remove']
    @test.save({:a => 50})
    @test.remove({}, :async => true) do |error, result|
      assert_nil error
      assert result
      failsafe.call
    end
    wait_for_async
    
    @test.drop
  end

  def test_async_count
    failsafe = mock('failsafe will get called in block', :call => true)

    @@test.drop

    @@test.save("x" => 1)
    @@test.save("x" => 2)

    @@test.count(:async => true) do |error, result|
      assert_nil error
      assert_equal 2, result
      failsafe.call
    end
    wait_for_async
  end

  # Note: #size is just an alias for #count.
  def test_async_size
    failsafe = mock('failsafe will get called in block', :call => true)
    
    @@test.drop

    @@test.save("x" => 1)
    @@test.save("x" => 2)

    @@test.size(:async => true) do |error, result|
      assert_nil error
      assert_equal 2, result
      failsafe.call
    end
    wait_for_async
  end

  def test_async_find_one
    failsafe = mock('failsafe will get called in block', :call => true)

    id = @@test.save("hello" => "world", "foo" => "bar")

    @@test.find_one({}, :async => true) do |error, result|
      assert_nil error
      assert_equal @@test.find_one(id), result
      failsafe.call
    end
    wait_for_async
  end

  def test_async_insert
    failsafe = mock('failsafe will get called in block', :call => true)

    doc = {"hello" => "world"}
    @@test.insert(doc, :async => true) do |error, result|
      assert_nil error
      assert result
      failsafe.call
    end
    wait_for_async
    
    assert_equal 1, @@test.count
  end

  def test_async_find
    assert_raise RuntimeError do
      @@test.find({}, :async => true)
    end
  end

  if @@version > "1.3.0"
    def test_async_find_and_modify
      failsafe = mock('failsafe will get called in block', :call => true)

      @@test << { :a => 1, :processed => false }
      @@test << { :a => 2, :processed => false }
      @@test << { :a => 3, :processed => false }

      @@test.find_and_modify(:query => {}, :sort => [['a', -1]], :update => {"$set" => {:processed => true}}, :async => true) do |error, result|
        assert_nil error
        assert result
        failsafe.call
      end
      wait_for_async

      assert @@test.find_one({:a => 3})['processed']
    end

    def test_async_find_and_modify_with_invalid_options
      failsafe = mock('failsafe will get called in block', :call => true)

      @@test << { :a => 1, :processed => false }
      @@test << { :a => 2, :processed => false }
      @@test << { :a => 3, :processed => false }

      @@test.find_and_modify(:blimey => {}, :async => true) do |error, result|
        assert error
        assert error.instance_of?(OperationFailure)
        assert_nil result
        failsafe.call
      end
      wait_for_async
    end
  end

end
