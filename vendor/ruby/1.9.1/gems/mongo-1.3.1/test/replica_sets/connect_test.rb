$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require './test/replica_sets/rs_test_helper'

# NOTE: This test expects a replica set of three nodes to be running on RS.host,
# on ports TEST_PORT, RS.ports[1], and TEST + 2.
class ConnectTest < Test::Unit::TestCase
  include Mongo

  def setup
    RS.restart_killed_nodes
  end

  def teardown
    RS.restart_killed_nodes
  end

  def test_connect_with_deprecated_multi
    @conn = Connection.multi([[RS.host, RS.ports[0]], [RS.host, RS.ports[1]]], :name => RS.name)
    assert @conn.is_a?(ReplSetConnection)
    assert @conn.connected?
  end

  def test_connect_bad_name
    assert_raise_error(ReplicaSetConnectionError, "-wrong") do
      ReplSetConnection.new([RS.host, RS.ports[0]], [RS.host, RS.ports[1]],
        [RS.host, RS.ports[2]], :rs_name => RS.name + "-wrong")
    end
  end

  def test_connect
    @conn = ReplSetConnection.new([RS.host, RS.ports[1]], [RS.host, RS.ports[0]],
      [RS.host, RS.ports[2]], :name => RS.name)
    assert @conn.connected?
    assert @conn.read_primary?
    assert @conn.primary?

    assert_equal RS.primary, @conn.primary
    assert_equal RS.secondaries.sort, @conn.secondaries.sort
    assert_equal RS.arbiters.sort, @conn.arbiters.sort

    @conn = ReplSetConnection.new([RS.host, RS.ports[1]], [RS.host, RS.ports[0]],
      :name => RS.name)
    assert @conn.connected?
  end

  def test_host_port_accessors
    @conn = ReplSetConnection.new([RS.host, RS.ports[0]], [RS.host, RS.ports[1]],
      [RS.host, RS.ports[2]], :name => RS.name)

    assert_equal @conn.host, RS.primary[0]
    assert_equal @conn.port, RS.primary[1]
  end

  def test_connect_with_primary_node_killed
    node = RS.kill_primary

    # Becuase we're killing the primary and trying to connect right away,
    # this is going to fail right away.
    assert_raise_error(ConnectionFailure, "Failed to connect to primary node") do
      @conn = ReplSetConnection.new([RS.host, RS.ports[0]], [RS.host, RS.ports[1]],
        [RS.host, RS.ports[2]])
    end

    # This allows the secondary to come up as a primary
    rescue_connection_failure do
      @conn = ReplSetConnection.new([RS.host, RS.ports[0]], [RS.host, RS.ports[1]],
        [RS.host, RS.ports[2]])
    end
    assert @conn.connected?
  end

  def test_connect_with_secondary_node_killed
    node = RS.kill_secondary

    @conn = ReplSetConnection.new([RS.host, RS.ports[0]], [RS.host, RS.ports[1]],
      [RS.host, RS.ports[2]])
    assert @conn.connected?
  end

  def test_connect_with_third_node_killed
    RS.kill(RS.get_node_from_port(RS.ports[2]))

    @conn = ReplSetConnection.new([RS.host, RS.ports[0]], [RS.host, RS.ports[1]],
      [RS.host, RS.ports[2]])
    assert @conn.connected?
  end

  def test_connect_with_primary_stepped_down
    RS.step_down_primary

    rescue_connection_failure do
      @conn = ReplSetConnection.new([RS.host, RS.ports[0]], [RS.host, RS.ports[1]],
        [RS.host, RS.ports[2]])
    end
    assert @conn.connected?
  end

end
