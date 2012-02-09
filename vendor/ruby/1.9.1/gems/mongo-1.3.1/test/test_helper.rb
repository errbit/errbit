$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems' if RUBY_VERSION < '1.9.0' && ENV['C_EXT']
require 'mongo'
require 'test/unit'

def silently
  warn_level = $VERBOSE
  $VERBOSE = nil
  result = yield
  $VERBOSE = warn_level
  result
end

begin
  require 'rubygems' if RUBY_VERSION < "1.9.0" && !ENV['C_EXT']
  silently { require 'shoulda' }
  silently { require 'mocha' }
rescue LoadError
  puts <<MSG

This test suite requires shoulda and mocha.
You can install them as follows:
  gem install shoulda
  gem install mocha

MSG

  exit
end

require 'bson_ext/cbson' if !(RUBY_PLATFORM =~ /java/) && ENV['C_EXT']

unless defined? MONGO_TEST_DB
  MONGO_TEST_DB = 'ruby-test-db'
end

unless defined? TEST_PORT
  TEST_PORT = ENV['MONGO_RUBY_DRIVER_PORT'] ? ENV['MONGO_RUBY_DRIVER_PORT'].to_i : Mongo::Connection::DEFAULT_PORT
end

unless defined? TEST_HOST
  TEST_HOST = ENV['MONGO_RUBY_DRIVER_HOST'] || 'localhost'
end

class Test::Unit::TestCase
  include Mongo
  include BSON

  def self.standard_connection(options={})
    Connection.new(TEST_HOST, TEST_PORT, options)
  end

  def standard_connection(options={})
    self.class.standard_connection(options)
  end

  def self.host_port
    "#{mongo_host}:#{mongo_port}"
  end

  def self.mongo_host
    TEST_HOST
  end

  def self.mongo_port
    TEST_PORT
  end

  def host_port
    self.class.host_port
  end

  def mongo_host
    self.class.mongo_host
  end

  def mongo_port
    self.class.mongo_port
  end

  def new_mock_socket(host='localhost', port=27017)
    socket = Object.new
    socket.stubs(:setsockopt).with(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
    socket.stubs(:close)
    socket
  end

  def new_mock_db
    db = Object.new
  end

  def assert_raise_error(klass, message)
    begin
      yield
    rescue => e
      assert_equal klass, e.class
      assert e.message.include?(message), "#{e.message} does not include #{message}."
    else
      flunk "Expected assertion #{klass} but none was raised."
    end
  end
end
