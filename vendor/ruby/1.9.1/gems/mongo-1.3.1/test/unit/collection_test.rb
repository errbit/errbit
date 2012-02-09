require './test/test_helper'

class CollectionTest < Test::Unit::TestCase

  context "Basic operations: " do
    setup do
      @logger = mock()
      @logger.expects(:debug)
    end

    should "send update message" do
      @conn = Connection.new('localhost', 27017, :logger => @logger, :connect => false)
      @db   = @conn['testing']
      @coll = @db.collection('books')
      @conn.expects(:send_message).with do |op, msg, log|
        op == 2001
      end
      @conn.stubs(:log_operation)
      @coll.update({}, {:title => 'Moby Dick'})
    end

    should "send insert message" do
      @conn = Connection.new('localhost', 27017, :logger => @logger, :connect => false)
      @db   = @conn['testing']
      @coll = @db.collection('books')
      @conn.expects(:send_message).with do |op, msg, log|
        op == 2002
      end
      @conn.expects(:log_operation).with do |name, payload|
        (name == :insert) && payload[:documents][0][:title].include?('Moby')
      end
      @coll.insert({:title => 'Moby Dick'})
    end

    should "send sort data" do
      @conn = Connection.new('localhost', 27017, :logger => @logger, :connect => false)
      @db   = @conn['testing']
      @coll = @db.collection('books')
      @conn.expects(:receive_message).with do |op, msg, log, sock|
        op == 2004
      end.returns([[], 0, 0])
      @conn.expects(:log_operation).with do |name, payload|
        (name == :find) && payload[:selector][:title].include?('Moby')
      end
      @coll.find({:title => 'Moby Dick'}).sort([['title', 1], ['author', 1]]).next_document
    end

    should "not log binary data" do
      @conn = Connection.new('localhost', 27017, :logger => @logger, :connect => false)
      @db   = @conn['testing']
      @coll = @db.collection('books')
      data = BSON::Binary.new(("BINARY " * 1000).unpack("c*"))
      @conn.expects(:send_message).with do |op, msg, log|
        op == 2002
      end
      @conn.expects(:log_operation).with do |name, payload|
        (name == :insert) && payload[:documents][0][:data].inspect.include?('Binary')
      end
      @coll.insert({:data => data})
    end

    should "send safe update message" do
      @conn = Connection.new('localhost', 27017, :logger => @logger, :connect => false)
      @db   = @conn['testing']
      @coll = @db.collection('books')
      @conn.expects(:send_message_with_safe_check).with do |op, msg, db_name, log|
        op == 2001
      end
      @conn.expects(:log_operation).with do |name, payload|
        (name == :update) && payload[:document][:title].include?('Moby')
      end
      @coll.update({}, {:title => 'Moby Dick'}, :safe => true)
    end

    should "send safe insert message" do
      @conn = Connection.new('localhost', 27017, :logger => @logger, :connect => false)
      @db   = @conn['testing']
      @coll = @db.collection('books')
      @conn.expects(:send_message_with_safe_check).with do |op, msg, db_name, log|
        op == 2001
      end
      @conn.stubs(:log_operation)
      @coll.update({}, {:title => 'Moby Dick'}, :safe => true)
    end

    should "not call insert for each ensure_index call" do
      @conn = Connection.new('localhost', 27017, :logger => @logger, :connect => false)
      @db   = @conn['testing']
      @coll = @db.collection('books')
      @coll.expects(:generate_indexes).once

      @coll.ensure_index [["x", Mongo::DESCENDING]]
      @coll.ensure_index [["x", Mongo::DESCENDING]]
    end

    should "call generate_indexes for a new direction on the same field for ensure_index" do
      @conn = Connection.new('localhost', 27017, :logger => @logger, :connect => false)
      @db   = @conn['testing']
      @coll = @db.collection('books')
      @coll.expects(:generate_indexes).twice

      @coll.ensure_index [["x", Mongo::DESCENDING]]
      @coll.ensure_index [["x", Mongo::ASCENDING]]

    end

    should "call generate_indexes twice because the cache time is 0 seconds" do
      @conn = Connection.new('localhost', 27017, :logger => @logger, :connect => false)
      @db   = @conn['testing']
      @db.cache_time = 0
      @coll = @db.collection('books')
      @coll.expects(:generate_indexes).twice

      @coll.ensure_index [["x", Mongo::DESCENDING]]
      @coll.ensure_index [["x", Mongo::DESCENDING]]
    end

    should "call generate_indexes for each key when calling ensure_indexes" do
      @conn = Connection.new('localhost', 27017, :logger => @logger, :connect => false)
      @db   = @conn['testing']
      @db.cache_time = 300
      @coll = @db.collection('books')
      @coll.expects(:generate_indexes).once.with do |a, b, c|
        a == {"x"=>-1, "y"=>-1}
      end

      @coll.ensure_index [["x", Mongo::DESCENDING], ["y", Mongo::DESCENDING]]
    end
  end
end
