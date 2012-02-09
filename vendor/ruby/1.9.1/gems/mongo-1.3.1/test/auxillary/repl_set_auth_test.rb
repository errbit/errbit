$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require './test/test_helper'
require './test/tools/auth_repl_set_manager'

class AuthTest < Test::Unit::TestCase
  include Mongo

  def setup
    @manager = AuthReplSetManager.new(:start_port => 40000)
    @manager.start_set
  end

  def teardown
    @manager.cleanup_set
  end

  def test_repl_set_auth
    @conn = ReplSetConnection.new([@manager.host, @manager.ports[0]], [@manager.host, @manager.ports[1]],
      [@manager.host, @manager.ports[2]], :name => @manager.name)

    # Add an admin user
    @conn['admin'].add_user("me", "secret")

    # Ensure that insert fails
    assert_raise_error Mongo::OperationFailure, "unauthorized" do
      @conn['foo']['stuff'].insert({:a => 2}, :safe => {:w => 3})
    end

    # Then authenticate
    assert @conn['admin'].authenticate("me", "secret")

    # Insert should succeed now
    assert @conn['foo']['stuff'].insert({:a => 2}, :safe => {:w => 3})

    # So should a query
    assert @conn['foo']['stuff'].find_one

    # But not when we logout
    @conn['admin'].logout

    assert_raise_error Mongo::OperationFailure, "unauthorized" do
      @conn['foo']['stuff'].find_one
    end

    # Same should apply to a random secondary
    @slave1 = Connection.new(@conn.secondary_pools[0].host,
      @conn.secondary_pools[0].port, :slave_ok => true)

    # Find should fail
    assert_raise_error Mongo::OperationFailure, "unauthorized" do
      @slave1['foo']['stuff'].find_one
    end

    # But not when authenticated
    @slave1['admin'].authenticate("me", "secret")
    assert @slave1['foo']['stuff'].find_one
  end
end
