$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require './test/replica_sets/rs_test_helper'

# NOTE: This test expects a replica set of three nodes to be running
# on the local host.
class ReplicaSetQuerySecondariesTest < Test::Unit::TestCase
  include Mongo

  def setup
    @conn = ReplSetConnection.new([RS.host, RS.ports[0]], :read_secondary => true)
    @db = @conn.db(MONGO_TEST_DB)
    @db.drop_collection("test-sets")
  end

  def teardown
    RS.restart_killed_nodes
  end

  def test_read_primary
    rescue_connection_failure do
      assert !@conn.read_primary?
      assert !@conn.primary?
    end
  end

  def test_con
    assert @conn.primary_pool, "No primary pool!"
    assert @conn.read_pool, "No read pool!"
    assert @conn.primary_pool.port != @conn.read_pool.port,
      "Primary port and read port at the same!"
  end

  def test_query_secondaries
    @coll = @db.collection("test-sets", :safe => {:w => 3, :wtimeout => 20000})
    @coll.save({:a => 20})
    @coll.save({:a => 30})
    @coll.save({:a => 40})
    results = []
    @coll.find.each {|r| results << r["a"]}
    assert results.include?(20)
    assert results.include?(30)
    assert results.include?(40)

    RS.kill_primary

    results = []
    rescue_connection_failure do
      @coll.find.each {|r| results << r}
      [20, 30, 40].each do |a|
        assert results.any? {|r| r['a'] == a}, "Could not find record for a => #{a}"
      end
    end
  end

  def test_kill_primary
    @coll = @db.collection("test-sets", :safe => {:w => 3, :wtimeout => 10000})
    @coll.save({:a => 20})
    @coll.save({:a => 30})
    assert_equal 2, @coll.find.to_a.length

    # Should still be able to read immediately after killing master node
    RS.kill_primary
    assert_equal 2, @coll.find.to_a.length
    rescue_connection_failure do
      @coll.save({:a => 50}, :safe => {:w => 2, :wtimeout => 10000})
    end
    RS.restart_killed_nodes
    @coll.save({:a => 50}, :safe => {:w => 2, :wtimeout => 10000})
    assert_equal 4, @coll.find.to_a.length
  end

  def test_kill_secondary
    @coll = @db.collection("test-sets", {:safe => {:w => 3, :wtimeout => 20000}})
    @coll.save({:a => 20})
    @coll.save({:a => 30})
    assert_equal 2, @coll.find.to_a.length

    read_node = RS.get_node_from_port(@conn.read_pool.port)
    RS.kill(read_node)

    # Should fail immediately on next read
    old_read_pool_port = @conn.read_pool.port
    assert_raise ConnectionFailure do
      @coll.find.to_a.length
    end

    # Should eventually reconnect and be able to read
    rescue_connection_failure do
      length = @coll.find.to_a.length
      assert_equal 2, length
    end
    new_read_pool_port = @conn.read_pool.port
    assert old_read_pool_port != new_read_pool_port
  end

  def test_write_lots_of_data
    @coll = @db.collection("test-sets", {:safe => {:w => 2}})

    6000.times do |n|
      @coll.save({:a => n})
    end

    cursor = @coll.find()
    cursor.next
    cursor.close
  end

end
