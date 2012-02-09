# encoding: UTF-8

require './test_helper'

require 'test/unit'

# attributes is deprecated - use attributes instead.
# Tests for backwards compatibility

class Testattributes < Test::Unit::TestCase
  def setup()
    xp = XML::Parser.string('<ruby_array uga="booga" foo="bar"><fixnum>one</fixnum><fixnum>two</fixnum></ruby_array>')
    @doc = xp.parse
  end

  def teardown()
    @doc = nil
  end

  def test_traversal
    attributes = @doc.root.attributes
    
    assert_instance_of(XML::Attributes, attributes)
    attribute = attributes.first
    assert_equal('uga', attribute.name)
    assert_equal('booga', attribute.value)

    attribute = attribute.next
    assert_instance_of(XML::Attr, attribute)
    assert_equal('foo', attribute.name)
    assert_equal('bar', attribute.value)
  end
  
  def test_no_attributes
    attributes = @doc.root.child.attributes
    assert_instance_of(XML::Attributes, attributes)
    assert_equal(0, attributes.length)
  end
end
