# encoding: UTF-8

require './test_helper'
require 'test/unit'

class TestNodeEdit < Test::Unit::TestCase
  def setup
    xp = XML::Parser.string('<test><num>one</num><num>two</num><num>three</num></test>')
    @doc = xp.parse
  end

  def teardown
    @doc = nil
  end

  def first_node
    @doc.root.child
  end

  def second_node
    first_node.next
  end

  def third_node
    second_node.next
  end

  def test_add_next_01
    first_node.next = XML::Node.new('num', 'one-and-a-half')
    assert_equal('<test><num>one</num><num>one-and-a-half</num><num>two</num><num>three</num></test>',
                 @doc.root.to_s.gsub(/\n\s*/,''))
  end

  def test_add_next_02
    second_node.next = XML::Node.new('num', 'two-and-a-half')
    assert_equal('<test><num>one</num><num>two</num><num>two-and-a-half</num><num>three</num></test>',
                 @doc.root.to_s.gsub(/\n\s*/,''))
  end

  def test_add_next_03
    third_node.next = XML::Node.new('num', 'four')
    assert_equal '<test><num>one</num><num>two</num><num>three</num><num>four</num></test>',
      @doc.root.to_s.gsub(/\n\s*/,'')
  end

  def test_add_prev_01
    first_node.prev = XML::Node.new('num', 'half')
    assert_equal '<test><num>half</num><num>one</num><num>two</num><num>three</num></test>',
      @doc.root.to_s.gsub(/\n\s*/,'')
  end

  def test_add_prev_02
    second_node.prev = XML::Node.new('num', 'one-and-a-half')
    assert_equal '<test><num>one</num><num>one-and-a-half</num><num>two</num><num>three</num></test>',
      @doc.root.to_s.gsub(/\n\s*/,'')
  end

  def test_add_prev_03
    third_node.prev = XML::Node.new('num', 'two-and-a-half')
    assert_equal '<test><num>one</num><num>two</num><num>two-and-a-half</num><num>three</num></test>',
      @doc.root.to_s.gsub(/\n\s*/,'')
  end

  def test_remove_node
    first_node.remove!
    assert_equal('<test><num>two</num><num>three</num></test>',
                 @doc.root.to_s.gsub(/\n\s*/,''))
  end

  def test_freed_node
    root = XML::Node.new("root")

    a = XML::Node.new("a")
    root << a

    a.parent.remove!

    # Node a has now been freed from under us
    error = assert_raise(RuntimeError) do
      a.to_s
    end
    assert_equal('This node has already been freed.', error.to_s)
  end

  def test_remove_node_gc
    xp = XML::Parser.string('<test><num>one</num><num>two</num><num>three</num></test>')
    doc = xp.parse
    node = doc.root.child.remove!
    node = nil
    GC.start
    assert_not_nil(doc)
  end

  def test_remove_node_iteration
    nodes = Array.new
    @doc.root.each_element do |node|
      if node.name == 'num'
        nodes << node
        node.remove!
      end
    end
    assert_equal(3, nodes.length)
  end

  def test_reuse_removed_node
    # Remove the node
    node = @doc.root.first.remove!
    assert_not_nil(node)

    # Add it to the end of the document
    @doc.root.last.next = node

    assert_equal('<test><num>two</num><num>three</num><num>one</num></test>',
                 @doc.root.to_s.gsub(/\n\s*/,''))
  end

  def test_append_existing_node
    doc = XML::Parser.string('<top>a<bottom>b<one>first</one><two>second</two>c</bottom>d</top>').parse
    node1 = doc.find_first('//two')

    doc.root << node1
    assert_equal('<top>a<bottom>b<one>first</one>c</bottom>d<two>second</two></top>',
                 doc.root.to_s)
  end

  def test_wrong_doc
    puts 333333
    doc1 = XML::Parser.string('<nums><one></one></nums>').parse
    doc2 = XML::Parser.string('<nums><two></two></nums>').parse

    node = doc1.root.child

    error = assert_raise(XML::Error) do
      doc2.root << node
    end

    GC.start
    assert_equal(' Nodes belong to different documents.  You must first import the node by calling XML::Document.import.',
                 error.to_s)
  end

  # This test is to verify that an earlier reported bug has been fixed
  def test_merge
    documents = []

    # Read in 500 documents
    500.times do
      documents << XML::Parser.string(File.read(File.join(File.dirname(__FILE__), 'model', 'merge_bug_data.xml'))).parse
    end

    master_doc = documents.shift
    documents.inject(master_doc) do |master_doc, child_doc|
      master_body = master_doc.find("//body").first
      child_body = child_doc.find("//body").first

      child_element = child_body.detect do |node|
        node.element?
      end

      master_body << child_element.copy(true)
      master_doc
    end
  end

  def test_append_chain
    node = XML::Node.new('foo') << XML::Node.new('bar') << "bars contents"
    assert_equal('<foo><bar/>bars contents</foo>',
                 node.to_s)
  end

  def test_set_base
    @doc.root.base_uri = 'http://www.rubynet.org/'
    assert_equal("<test xml:base=\"http://www.rubynet.org/\">\n  <num>one</num>\n  <num>two</num>\n  <num>three</num>\n</test>",
                 @doc.root.to_s)
  end
end