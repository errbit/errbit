# encoding: UTF-8

require './test_helper'

require 'test/unit'

class TestXPathExpression < Test::Unit::TestCase
  def setup
    xp = XML::Parser.string('<ruby_array uga="booga" foo="bar"><fixnum>one</fixnum><fixnum>two</fixnum></ruby_array>')
    @doc = xp.parse
  end
  
  def teardown
    @doc = nil
  end

  def test_nodes
    expr = XML::XPath::Expression.compile('/ruby_array/fixnum')
    set = @doc.find(expr)
    assert_instance_of(XML::XPath::Object, set)
    assert_equal(2, set.size)
  end

  def test_find_class
    expr = XML::XPath::Expression.new('/ruby_array/fixnum')
    set = @doc.find(expr)
    assert_instance_of(XML::XPath::Object, set)
    assert_equal(2, set.size)
  end

  def test_find_invalid
    error = assert_raise(TypeError) do
      set = @doc.find(999)
    end
    assert_equal('Argument should be an intance of a String or XPath::Expression',
                 error.to_s)
  end
end
