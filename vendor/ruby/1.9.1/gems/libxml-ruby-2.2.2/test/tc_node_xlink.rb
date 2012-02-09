# encoding: UTF-8

# $Id$
require './test_helper'

require 'test/unit'

class TC_XML_Node_XLink < Test::Unit::TestCase
  def setup()
    xp = XML::Parser.string('<ruby_array xmlns:xlink="http://www.w3.org/1999/xlink/namespace/"><fixnum xlink:type="simple">one</fixnum></ruby_array>')
    doc = xp.parse
    assert_instance_of(XML::Document, doc)
    @root = doc.root
    assert_instance_of(XML::Node, @root)
  end

  def teardown()
    @root = nil
  end

  def test_xml_node_xlink()
    for elem in @root.find('fixnum')
      assert_instance_of(XML::Node, elem)
      assert_instance_of(TrueClass, elem.xlink?)
      assert_equal("simple", elem.xlink_type_name)
      assert_equal(XML::Node::XLINK_TYPE_SIMPLE, elem.xlink_type)
    end
  end
end
