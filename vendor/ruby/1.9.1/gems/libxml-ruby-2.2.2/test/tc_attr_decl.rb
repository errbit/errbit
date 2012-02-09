# encoding: UTF-8

require './test_helper'
require 'test/unit'

class AttrDeclTest < Test::Unit::TestCase
  def setup
    xp = XML::Parser.string(<<-EOS)
	<!DOCTYPE test [
	  <!ELEMENT root (property*)>
	  <!ELEMENT property EMPTY>
	  <!ATTLIST property name       NMTOKEN          #REQUIRED>
	  <!ATTLIST property access     (r | w | rw)    "rw">
	]>
	<root>
	  <property name="readonly" access="r" />
	  <property name="readwrite" />
	</root>
    EOS
    @doc = xp.parse
  end
  
  def teardown
    @doc = nil
  end

  def test_attributes
    # Get a element with an access attribute
    elem = @doc.find_first('/root/property[@name="readonly"]')
    assert_equal(2, elem.attributes.length)
    assert_not_nil(elem['access'])

    # Get a element node without a access attribute
    elem = @doc.find_first('/root/property[@name="readwrite"]')
    assert_equal(1, elem.attributes.length)
    assert_nil(elem['access'])
  end

  def test_attr
    # Get a property node without a access attribute
    elem = @doc.find_first('/root/property[@name="readonly"]')

    # Get the attr_decl
    attr = elem.attributes.get_attribute('access')
    assert_not_nil(attr)
    assert_equal(XML::Node::ATTRIBUTE_NODE, attr.node_type)
    assert_equal('attribute', attr.node_type_name)

    # Get its value
    assert_equal('r', attr.value)
  end

  def test_attr_decl
    # Get a property node without a access attribute
    elem = @doc.find_first('/root/property[@name="readwrite"]')

    # Get the attr_decl
    attr_decl = elem.attributes.get_attribute('access')
    assert_not_nil(attr_decl)
    assert_equal(XML::Node::ATTRIBUTE_DECL, attr_decl.node_type)
    assert_equal('attribute declaration', attr_decl.node_type_name)

    # Get its value
    assert_equal('rw', attr_decl.value)
  end

  def test_type
    # Get a property node without a access attribute
    elem = @doc.find_first('/root/property[@name="readwrite"]')
    attr_decl = elem.attributes.get_attribute('access')

    assert_not_nil(attr_decl)
    assert_equal(XML::Node::ATTRIBUTE_DECL, attr_decl.node_type)
    assert_equal('attribute declaration', attr_decl.node_type_name)
  end
  
  def test_name
    elem = @doc.find_first('/root/property[@name="readwrite"]')
    attr_decl = elem.attributes.get_attribute('access')

    assert_equal('access', attr_decl.name)
  end

  def test_value
    elem = @doc.find_first('/root/property[@name="readwrite"]')
    attr_decl = elem.attributes.get_attribute('access')

    assert_equal('rw', attr_decl.value)
  end

  def test_to_s
    elem = @doc.find_first('/root/property[@name="readwrite"]')
    attr_decl = elem.attributes.get_attribute('access')

    assert_equal('access = rw', attr_decl.to_s)
  end

  def test_prev
    elem = @doc.find_first('/root/property[@name="readwrite"]')
    attr_decl = elem.attributes.get_attribute('access')

    first_decl = attr_decl.prev
    assert_equal(XML::Node::ATTRIBUTE_DECL, first_decl.node_type)
    assert_equal('name', first_decl.name)
    assert_nil(first_decl.value)

    elem_decl = first_decl.prev
    assert_equal(XML::Node::ELEMENT_DECL, elem_decl.node_type)
  end

  def test_next
    elem = @doc.find_first('/root/property[@name="readwrite"]')
    attr_decl = elem.attributes.get_attribute('access')

    next_decl = attr_decl.next
    assert_nil(next_decl)
  end

  def test_doc
    elem = @doc.find_first('/root/property[@name="readwrite"]')
    attr_decl = elem.attributes.get_attribute('access')

    assert_same(@doc, attr_decl.doc)
  end

  def test_parent
    elem = @doc.find_first('/root/property[@name="readwrite"]')
    attr_decl = elem.attributes.get_attribute('access')

    parent = attr_decl.parent
    assert_instance_of(XML::Dtd, parent)
  end
end