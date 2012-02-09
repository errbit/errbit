# encoding: UTF-8

require './test_helper'
require 'tempfile'
require 'test/unit'

class TestXPath < Test::Unit::TestCase
  def setup
    @doc = XML::Document.file(File.join(File.dirname(__FILE__), 'model/soap.xml'))
  end
  
  def teardown
    @doc = nil
  end
  
  def test_doc_find
    nodes = @doc.find('/soap:Envelope')
    assert_instance_of(XML::XPath::Object, nodes)
    assert_equal(1, nodes.length)
    assert_equal(nodes.xpath_type, XML::XPath::NODESET)
  end

  def test_doc_find_first
    node = @doc.find_first('/soap:Envelope/soap:Body')
    assert_instance_of(XML::Node, node)
  end

  def test_ns
    nodes = @doc.find('//ns1:IdAndName', 'ns1:http://domain.somewhere.com')
    assert_equal(3, nodes.length)
  end

  def test_ns_array
    nodes = @doc.find('//ns1:IdAndName', ['ns1:http://domain.somewhere.com'])
    assert_equal(3, nodes.length)
  end

  def test_default_ns1
    # Find all nodes with http://services.somewhere.com namespace
    nodes = @doc.find('//*[namespace-uri()="http://services.somewhere.com"]')
    assert_equal(2, nodes.length)
    assert_equal('getManufacturerNamesResponse', nodes[0].name)
    assert_equal('IDAndNameList', nodes[1].name)
  end

  def test_default_ns2
    # Find all nodes with http://services.somewhere.com namespace
    nodes = @doc.find('//ns:*', 'ns:http://services.somewhere.com')
    assert_equal(2, nodes.length)
    assert_equal('getManufacturerNamesResponse', nodes[0].name)
    assert_equal('IDAndNameList', nodes[1].name)

    # Get getManufacturerNamesResponse node
    nodes = @doc.find('//ns:getManufacturerNamesResponse', 'ns:http://services.somewhere.com')
    assert_equal(1, nodes.length)

    # Get IdAndName node
    nodes = @doc.find('/soap:Envelope/soap:Body/ns0:getManufacturerNamesResponse/ns0:IDAndNameList/ns1:IdAndName',
                      ['ns0:http://services.somewhere.com', 'ns1:http://domain.somewhere.com'])
    assert_equal(3, nodes.length)
  end

  def test_default_ns3
    # Find all nodes with http://services.somewhere.com namespace
    nodes = @doc.find('//ns:*', 'ns' => 'http://services.somewhere.com')
    assert_equal(2, nodes.length)
    assert_equal('getManufacturerNamesResponse', nodes[0].name)
    assert_equal('IDAndNameList', nodes[1].name)
  end

  def test_default_ns4
    # Find all nodes with http://services.somewhere.com namespace
    nodes = @doc.find('//ns:*', :ns => 'http://services.somewhere.com')
    assert_equal(2, nodes.length)
    assert_equal('getManufacturerNamesResponse', nodes[0].name)
    assert_equal('IDAndNameList', nodes[1].name)
  end

  def test_default_ns5
    # Find all nodes with http://services.somewhere.com namespace
    XML::Namespace.new(@doc.root, 'ns', 'http://services.somewhere.com')
    nodes = @doc.find('//ns:*')
    assert_equal(2, nodes.length)
    assert_equal('getManufacturerNamesResponse', nodes[0].name)
    assert_equal('IDAndNameList', nodes[1].name)
  end

  def test_attribute_ns
    # Pull all nodes with http://services.somewhere.com namespace
    nodes = @doc.find('@soap:encodingStyle')
    assert_equal(1, nodes.length)
    assert_equal('encodingStyle', nodes.first.name)
    assert_equal('http://www.w3.org/2001/12/soap-encoding', nodes.first.value)
  end

  def test_register_default_ns
    doc = XML::Document.file(File.join(File.dirname(__FILE__), 'model/atom.xml'))

    # No namespace has been yet defined
    assert_raise(XML::Error) do
      node = doc.find("atom:title")
    end

    node = doc.find('atom:title', 'atom:http://www.w3.org/2005/Atom')
    assert_not_nil(node)

    # Register namespace
    doc.root.namespaces.default_prefix = 'atom'
    node = doc.find("atom:title")
    assert_not_nil(node)
  end

  def test_node_find
    nodes = @doc.find('//ns1:IdAndName', 'ns1:http://domain.somewhere.com')
    node = nodes.first

    # Since we are searching on the node, don't have to register namespace
    nodes = node.find('ns1:name')
    assert_equal(1, nodes.length)
		assert_equal(nodes.first.object_id, nodes.last.object_id, 'First and last should be the same')
    assert_equal('name', nodes.first.name)
    assert_equal('man1', nodes.first.content)
  end

  def test_node_find_first
    node = @doc.find_first('//ns1:IdAndName', 'ns1:http://domain.somewhere.com')

    # Since we are searching on the node, don't have to register namespace
    node = node.find_first('ns1:name')
    assert_equal('name', node.name)
    assert_equal('man1', node.content)
  end

  def test_node_no_doc
    node = XML::Node.new('header', 'some content')
    assert_raise(TypeError) do
      node = node.find_first('/header')
    end
  end

  def test_memory
    # This sometimes causes a segmentation fault because
    # an xml document is sometimes freed before the
    # xpath_object used to query it.  When the xpath_object
    # is free, it iterates over its results which are pointers
    # to the document's nodes. A segmentation fault then happens.

    1000.times do
      doc = XML::Document.new('1.0')
      doc.root = XML::Node.new("header")

      1000.times do
        doc.root << XML::Node.new("footer")
      end

      nodes = doc.find('/header/footer')
    end
  end

  # Test that document doesn't get freed before nodes
  def test_xpath_free
    doc = XML::Document.file(File.join(File.dirname(__FILE__), 'model/soap.xml'))
    nodes = doc.find('//*')
    GC.start
    assert_equal('Envelope', nodes.first.name)
  end

  def test_xpath_namespace_nodes
    doc = XML::Document.string('<feed xmlns="http://www.w3.org/2005/Atom" xmlns:xhtml="http://www.w3.org/1999/xhtml"><entry/></feed>')
    nodes = doc.find('//atom:entry|namespace::*', :atom => "http://www.w3.org/2005/Atom")
    assert_equal(4, nodes.length)

    node = nodes[0]
    assert_equal(XML::Node::ELEMENT_NODE, node.node_type)

    node = nodes[1]
    assert_equal(XML::Node::NAMESPACE_DECL, node.node_type)

    node = nodes[2]
    assert_equal(XML::Node::NAMESPACE_DECL, node.node_type)

    node = nodes[3]
    assert_equal(XML::Node::NAMESPACE_DECL, node.node_type)
  end

	# Test to make sure we don't get nil on empty results.
	# This is also to test that we don't segfault due to our C code getting a NULL pointer
	# and not handling it properly.
	def test_xpath_empty_result
    doc = XML::Document.string('<html><body><p>Welcome to XHTML land!</p></body></html>')
		nodes = doc.find("//object/param[translate(@name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') = 'wmode']")
		assert_not_nil nodes
	end

  def test_invalid_expression
    xml = LibXML::XML::Document.string('<a></a>')

    # Using the expression twice used to cause a Segmentation Fault
    error = assert_raise(XML::Error) do
      xml.find('//a/')
    end
    assert_equal("Error: Invalid expression.", error.to_s)

    # Try again - this used to cause a Segmentation Fault
    error = assert_raise(XML::Error) do
      xml.find('//a/')
    end
    assert_equal("Error: Invalid expression.", error.to_s)
  end
end