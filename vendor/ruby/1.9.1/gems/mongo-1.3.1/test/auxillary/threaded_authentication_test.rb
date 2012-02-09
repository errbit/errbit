$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'mongo'
require 'thread'
require 'test/unit'
require './test/test_helper'

# NOTE: This test requires bouncing the server.
# It also requires that a user exists on the admin database.
class AuthenticationTest < Test::Unit::TestCase
  include Mongo

  def setup
    @conn = standard_connection(:pool_size => 10)
    @db1 = @conn.db('mongo-ruby-test-auth1')
    @db2 = @conn.db('mongo-ruby-test-auth2')
    @admin = @conn.db('admin')
  end

  def teardown
    @db1.authenticate('user1', 'secret')
    @db2.authenticate('user2', 'secret')
    @conn.drop_database('mongo-ruby-test-auth1')
    @conn.drop_database('mongo-ruby-test-auth2')
  end

  def threaded_exec
    threads = []

    100.times do
      threads << Thread.new do
        yield
      end
    end

    100.times do |n|
      threads[n].join
    end
  end

  def test_authenticate
    @admin.authenticate('bob', 'secret')
    @db1.add_user('user1', 'secret')
    @db2.add_user('user2', 'secret')
    @admin.logout

    threaded_exec do
      assert_raise Mongo::OperationFailure do
        @db1['stuff'].insert({:a => 2}, :safe => true)
      end
    end

    threaded_exec do
      assert_raise Mongo::OperationFailure do
        @db2['stuff'].insert({:a => 2}, :safe => true)
      end
    end

    @db1.authenticate('user1', 'secret')
    @db2.authenticate('user2', 'secret')

    threaded_exec do
      assert @db1['stuff'].insert({:a => 2}, :safe => true)
    end

    threaded_exec do
      assert @db2['stuff'].insert({:a => 2}, :safe => true)
    end

    puts "Please bounce the server."
    gets

    # Here we reconnect.
    begin
      @db1['stuff'].find.to_a
      rescue Mongo::ConnectionFailure
    end

    threaded_exec do
      assert @db1['stuff'].insert({:a => 2}, :safe => true)
    end

    threaded_exec do
      assert @db2['stuff'].insert({:a => 2}, :safe => true)
    end

    @db1.logout
    threaded_exec do
      assert_raise Mongo::OperationFailure do
        @db1['stuff'].insert({:a => 2}, :safe => true)
      end
    end

    @db2.logout
    threaded_exec do
      assert_raise Mongo::OperationFailure do
        assert @db2['stuff'].insert({:a => 2}, :safe => true)
      end
    end
  end

end
