# encoding: UTF-8

require 'xml/libxml'
require 'test/unit'

class TestDeprecatedRequire < Test::Unit::TestCase
  def test_basic
    xp = XML::Parser.string('<ruby_array uga="booga" foo="bar"><fixnum>one</fixnum><fixnum>two</fixnum></ruby_array>')
    assert_instance_of(XML::Parser, xp)
    @doc = xp.parse
    assert_instance_of(XML::Document, @doc)
  end
end
