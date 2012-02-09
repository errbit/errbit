# encoding: UTF-8

require './test_helper'
require 'test/unit'

class TestXInclude < Test::Unit::TestCase
  def setup
    @doc = XML::Document.file(File.join(File.dirname(__FILE__), 'model/xinclude.xml'))
    assert_instance_of(XML::Document, @doc)
  end

  def teardown
    @doc = nil
  end

  def test_ruby_xml_xinclude
    assert_equal(1, @doc.xinclude)
    assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<document xmlns:xi=\"http://www.w3.org/2001/XInclude\">\n  <p>This libxml2 binding has the following project information:\n   <code>This is some text to include in an xml file via XInclude.</code></p>\n</document>\n",
                 @doc.to_s)
  end
end
