require './test/test_helper'
include Mongo

class ConnectionTest < Test::Unit::TestCase
  context "Initialization: " do
    context "given a single node" do
      setup do
        @conn = Connection.new('localhost', 27017, :connect => false)
        TCPSocket.stubs(:new).returns(new_mock_socket)

        admin_db = new_mock_db
        admin_db.expects(:command).returns({'ok' => 1, 'ismaster' => 1}).twice
        @conn.expects(:[]).with('admin').returns(admin_db).twice
        @conn.connect
      end

      should "set localhost and port to master" do
        assert_equal 'localhost', @conn.primary_pool.host
        assert_equal 27017, @conn.primary_pool.port
      end

      should "set connection pool to 1" do
        assert_equal 1, @conn.primary_pool.size
      end

      should "default slave_ok to false" do
        assert !@conn.slave_ok?
      end
    end

    context "initializing with a mongodb uri" do
      should "parse a simple uri" do
        @conn = Connection.from_uri("mongodb://localhost", :connect => false)
        assert_equal ['localhost', 27017], @conn.host_to_try
      end

      should "allow a complex host names" do
        host_name = "foo.bar-12345.org"
        @conn = Connection.from_uri("mongodb://#{host_name}", :connect => false)
        assert_equal [host_name, 27017], @conn.host_to_try
      end

      should "parse a uri with a hyphen & underscore in the username or password" do
        @conn = Connection.from_uri("mongodb://hyphen-user_name:p-s_s@localhost:27017/db", :connect => false)
        assert_equal ['localhost', 27017], @conn.host_to_try
        auth_hash = { 'db_name' => 'db', 'username' => 'hyphen-user_name', "password" => 'p-s_s' }
        assert_equal auth_hash, @conn.auths[0]
      end

      should "attempt to connect" do
        TCPSocket.stubs(:new).returns(new_mock_socket)
        @conn = Connection.from_uri("mongodb://localhost", :connect => false)

        admin_db = new_mock_db
        admin_db.expects(:command).returns({'ok' => 1, 'ismaster' => 1}).twice
        @conn.expects(:[]).with('admin').returns(admin_db).twice
        @conn.connect
      end

      should "raise an error on invalid uris" do
        assert_raise MongoArgumentError do
          Connection.from_uri("mongo://localhost", :connect => false)
        end

        assert_raise MongoArgumentError do
          Connection.from_uri("mongodb://localhost:abc", :connect => false)
        end

        assert_raise MongoArgumentError do
          Connection.from_uri("mongodb://localhost:27017, my.db.com:27018, ", :connect => false)
        end
      end

      should "require all of username, password, and database if any one is specified" do
        assert_raise MongoArgumentError do
          Connection.from_uri("mongodb://localhost/db", :connect => false)
        end

        assert_raise MongoArgumentError do
          Connection.from_uri("mongodb://kyle:password@localhost", :connect => false)
        end
      end
    end
  end
end
