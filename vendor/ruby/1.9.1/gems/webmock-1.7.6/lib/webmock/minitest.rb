require 'minitest/unit'
require 'webmock'

MiniTest::Unit::TestCase.class_eval do
  include WebMock::API

  alias_method :teardown_without_webmock, :teardown
  def teardown_with_webmock
    teardown_without_webmock
    WebMock.reset!
  end
  alias_method :teardown, :teardown_with_webmock
end

WebMock::AssertionFailure.error_class = MiniTest::Assertion
