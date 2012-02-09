require 'rubygems'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require File.expand_path(File.dirname(__FILE__) + '/../test/http_request')

gem "minitest"
require 'minitest/autorun'
require 'webmock/minitest'

class MiniTest::Unit::TestCase
  def assert_raise(*exp, &block)
    assert_raises(*exp, &block)
  end

  def assert_raise_with_message(e, message, &block)
     e = assert_raises(e, &block)
     if message.is_a?(Regexp)
       assert_match(message, e.message)
     else
       assert_equal(message, e.message)
     end
   end

   def assert_fail(message, &block)
     assert_raise_with_message(MiniTest::Assertion, message, &block)
   end
end