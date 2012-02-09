require 'rubygems'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'webmock/test_unit'
require 'test/unit'

class Test::Unit::TestCase
  AssertionFailedError =  Test::Unit::AssertionFailedError rescue MiniTest::Assertion
  def assert_raise_with_message(e, message, &block)
    e = assert_raise(e, &block)
    if message.is_a?(Regexp)
      assert_match(message, e.message)
    else
      assert_equal(message, e.message)
    end
  end

  def assert_fail(message, &block)
    assert_raise_with_message(AssertionFailedError, message, &block)
  end
end
