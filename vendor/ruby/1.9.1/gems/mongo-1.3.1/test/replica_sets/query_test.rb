$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require './test/replica_sets/rs_test_helper'

# NOTE: This test expects a replica set of three nodes to be running
# on the local host.
class ReplicaSetQueryTest < Test::Unit::TestCase
  include Mongo

  def setup
    @conn = ReplSetConnection.new([RS.host, RS.ports[0]])
    @db = @conn.db(MONGO_TEST_DB)
    @db.drop_collection("test-sets")
    @coll = @db.collection("test-sets")
  end

  def teardown
    RS.restart_killed_nodes
  end

  def test_query
    @coll.save({:a => 20}, :safe => {:w => 3})
    @coll.save({:a => 30}, :safe => {:w => 3})
    @coll.save({:a => 40}, :safe => {:w => 3})
    results = []
    @coll.find.each {|r| results << r}
    [20, 30, 40].each do |a|
      assert results.any? {|r| r['a'] == a}, "Could not find record for a => #{a}"
    end

    puts "Benchmark before failover: #{benchmark_queries}"

    RS.kill_primary

    results = []
    rescue_connection_failure do
      @coll.find.each {|r| results << r}
      [20, 30, 40].each do |a|
        assert results.any? {|r| r['a'] == a}, "Could not find record for a => #{a}"
      end

    puts "Benchmark after failover: #{benchmark_queries}"
    end
  end

  def benchmark_queries
    t1 = Time.now
    10000.times { @coll.find_one }
    Time.now - t1
  end

end
