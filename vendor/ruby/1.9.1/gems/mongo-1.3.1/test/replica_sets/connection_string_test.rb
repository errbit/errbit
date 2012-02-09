$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require './test/replica_sets/rs_test_helper'

# NOTE: This test expects a replica set of three nodes to be running on RS.host,
# on ports TEST_PORT, RS.ports[1], and TEST + 2.
class ConnectionStringTest < Test::Unit::TestCase
  include Mongo

  def setup
    RS.restart_killed_nodes
  end

  def teardown
    RS.restart_killed_nodes
  end

  def test_connect_with_connection_string
    @conn = Connection.from_uri("mongodb://#{RS.host}:#{RS.ports[0]},#{RS.host}:#{RS.ports[1]}?replicaset=#{RS.name}")
    assert @conn.is_a?(ReplSetConnection)
    assert @conn.connected?
  end

  def test_connect_with_full_connection_string
    @conn = Connection.from_uri("mongodb://#{RS.host}:#{RS.ports[0]},#{RS.host}:#{RS.ports[1]}?replicaset=#{RS.name};safe=true;w=2;fsync=true;slaveok=true")
    assert @conn.is_a?(ReplSetConnection)
    assert @conn.connected?
    assert_equal 2, @conn.safe[:w]
    assert @conn.safe[:fsync]
    assert @conn.read_pool
  end

end
