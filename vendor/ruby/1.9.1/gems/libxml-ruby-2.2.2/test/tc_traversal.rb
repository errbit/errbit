# encoding: UTF-8

require './test_helper'
require 'test/unit'

class TestTranversal < Test::Unit::TestCase
  ROOT_NODES_LENGTH = 27
  ROOT_ELEMENTS_LENGTH = 13
  
  def setup
    filename = File.join(File.dirname(__FILE__), 'model/books.xml')
    @doc = XML::Document.file(filename)
  end
  
  def teardown
    @doc = nil
  end
  
  def test_children
    # Includes text nodes and such
    assert_equal(ROOT_NODES_LENGTH, @doc.root.children.length)
  end
  
  def test_children_iteration
    # Includes text nodes and such
    nodes = @doc.root.children.inject([]) do |arr, node|
      arr << node
      arr
    end
    
    assert_equal(ROOT_NODES_LENGTH, nodes.length)
  end

  def test_no_children
    # Get a node with no children
    node = @doc.find_first('/catalog/book[@id="bk113"]/price')
    assert_equal(0, node.children.length)
  end

  def test_no_children_inner_xml
    # Get a node with no children
    node = @doc.find_first('/catalog/book[@id="bk113"]/price')
    assert_nil(node.inner_xml)
  end
  def test_each
    # Includes text nodes and such
    nodes = @doc.root.inject([]) do |arr, node|
      arr << node
      arr
    end
    
    assert_equal(ROOT_NODES_LENGTH, nodes.length)
  end
  
  def test_each_element
    # Includes text nodes and such
    nodes = []
    @doc.root.each_element do |node|
      nodes << node
    end
    
    assert_equal(ROOT_ELEMENTS_LENGTH, nodes.length)
  end
  
  def test_next
    nodes = []
    
    node = @doc.root.first
    
    while node
      nodes << node
      node = node.next
    end
    assert_equal(ROOT_NODES_LENGTH, nodes.length)
  end

  def test_next?
    first_node = @doc.root.first
    assert(first_node.next?)
    
    last_node = @doc.root.last
    assert(!last_node.next?)
  end
    
  def test_prev
    nodes = []
    
    node = @doc.root.last
    
    while node
      nodes << node
      node = node.prev
    end
    assert_equal(ROOT_NODES_LENGTH, nodes.length)
  end
  
  def test_prev?
    first_node = @doc.root.first
    assert(!first_node.prev?)
    
    last_node = @doc.root.last
    assert(last_node.prev?)
  end

  def test_parent?
    assert(!@doc.parent?)
    assert(@doc.root.parent?)
  end
   
  def test_child?
    assert(@doc.child?)
    assert(!@doc.root.first.child?)
  end
  
  def test_next_prev_equivalence
    next_nodes = []
    last_nodes = []
    
    node = @doc.root.first
    while node
      next_nodes << node
      node = node.next
    end
  
    node = @doc.root.last
    while node
      last_nodes << node
      node = node.prev
    end
    
    assert_equal(next_nodes, last_nodes.reverse)
  end
  
  def test_next_children_equivalence
    next_nodes = []
    
    node = @doc.root.first
    while node
      next_nodes << node
      node = node.next
    end
  
    assert_equal(@doc.root.children, next_nodes)
  end

  def test_doc_class
    assert_instance_of(XML::Document, @doc)
  end
  
  def test_root_class
    assert_instance_of(XML::Node, @doc.root)
  end
end
