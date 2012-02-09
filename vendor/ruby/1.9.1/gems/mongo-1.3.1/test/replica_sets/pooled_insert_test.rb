$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require './test/replica_sets/rs_test_helper'

# NOTE: This test expects a replica set of three nodes to be running
# on the local host.
class ReplicaSetPooledInsertTest < Test::Unit::TestCase
  include Mongo

  def setup
    @conn = ReplSetConnection.new([RS.host, RS.ports[0]], [RS.host, RS.ports[1]],
      [RS.host, RS.ports[2]], :pool_size => 10, :timeout => 5)
    @db = @conn.db(MONGO_TEST_DB)
    @db.drop_collection("test-sets")
    @coll = @db.collection("test-sets")
  end

  def teardown
    RS.restart_killed_nodes
  end

  def test_insert
    expected_results = [-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    @coll.save({:a => -1}, :safe => true)

    RS.kill_primary

    threads = []
    10.times do |i|
      threads[i] = Thread.new do
        rescue_connection_failure do
          @coll.save({:a => i}, :safe => true)
        end
      end
    end

    # Restart the old master and wait for sync
    RS.restart_killed_nodes
    sleep(1)
    results = []

    rescue_connection_failure do
      @coll.find.each {|r| results << r}
      expected_results.each do |a|
        assert results.any? {|r| r['a'] == a}, "Could not find record for a => #{a}"
      end
    end

    @coll.save({:a => 10}, :safe => true)
    @coll.find.each {|r| results << r}
    (expected_results + [10]).each do |a|
      assert results.any? {|r| r['a'] == a}, "Could not find record for a => #{a} on second find"
    end
  end

end
