# encoding: UTF-8

require './test_helper'
require 'test/unit'

class TestNode < Test::Unit::TestCase
  def setup
    @file_name = "model/bands.utf-8.xml"

    # Strip spaces to make testing easier
    XML.default_keep_blanks = false
    file = File.join(File.dirname(__FILE__), @file_name)
    @doc = XML::Document.file(file)
  end
  
  def teardown
    XML.default_keep_blanks = true
    @doc = nil
  end

  def nodes
    # Find all nodes with a country attributes
    @doc.find('*[@country]')
  end

  def test_doc_class
    assert_instance_of(XML::Document, @doc)
  end

  def test_doc_node_type
    assert_equal XML::Node::DOCUMENT_NODE, @doc.node_type
  end

  def test_root_class
    assert_instance_of(XML::Node, @doc.root)
  end

  def test_root_node_type
    assert_equal XML::Node::ELEMENT_NODE, @doc.root.node_type
  end

  def test_node_class
    for n in nodes
      assert_instance_of(XML::Node, n)
    end
  end

  def test_context
    node = @doc.root
    context = node.context
    assert_instance_of(XML::XPath::Context, context)
  end

  def test_find
    assert_instance_of(XML::XPath::Object, self.nodes)
  end

  def test_node_child_get
    assert_instance_of(TrueClass, @doc.root.child?)
    assert_instance_of(XML::Node, @doc.root.child)

    if defined?(Encoding)
      assert_equal(Encoding::UTF_8, @doc.root.child.name.encoding)
      assert_equal("m\u00F6tley_cr\u00FCe", @doc.root.child.name)
    else
      assert_equal("m\303\266tley_cr\303\274e", @doc.root.child.name)
    end
  end

  def test_node_doc
    for n in nodes
      assert_instance_of(XML::Document, n.doc) if n.document?
    end
  end
  
  def test_name
    node = @doc.root.children.last
    assert_equal("iron_maiden", node.name)
  end

  def test_node_find
    nodes = @doc.root.find('./fixnum')
    for node in nodes
      assert_instance_of(XML::Node, node)
    end
  end

  def test_equality
    node_a = @doc.find_first('*[@country]')
    node_b = @doc.root.child

    assert(node_a == node_b)
    assert(node_a.eql?(node_b))
    assert(node_a.equal?(node_b))

    file = File.join(File.dirname(__FILE__), @file_name)
    doc2 = XML::Document.file(file)

    node_a2 = doc2.find_first('*[@country]')

    assert_equal(node_a.to_s, node_a2.to_s)
    assert_equal(node_a, node_a2)
    assert(node_a.eql?(node_a2))
    assert(!node_a.equal?(node_a2))
  end

  def test_equality_nil
    node = @doc.root
    assert(node != nil)
  end

  def test_equality_wrong_type
    node = @doc.root

    assert_raise(TypeError) do
      assert(node != 'abc')
    end
  end

  def test_content
    node = @doc.root.last
    assert_equal("Iron Maiden is a British heavy metal band formed in 1975.",
                 node.content)
  end

  def test_base
    doc = XML::Parser.string('<person />').parse
    assert_nil(doc.root.base_uri)
  end

	# We use the same facility that libXSLT does here to disable output escaping.
	# This lets you specify that the node's content should be rendered unaltered
	# whenever it is being output.  This is useful for things like <script> and
	# <style> nodes in HTML documents if you don't want to be forced to wrap them
	# in CDATA nodes.  Or if you are sanitizing existing HTML documents and want
	# to preserve the content of any of the text nodes.
	#
	def test_output_escaping
		text = '<bad-script>if (a &lt; b || b &gt; c) { return "text"; }<stop/>return "&gt;&gt;&gt;snip&lt;&lt;&lt;";</bad-script>'
    node = XML::Parser.string(text).parse.root
		assert_equal text, node.to_s

		text_noenc = '<bad-script>if (a < b || b > c) { return "text"; }<stop/>return ">>>snip<<<";</bad-script>'
		node.output_escaping = false
		assert_equal text_noenc, node.to_s

		node.output_escaping = true
		assert_equal text, node.to_s

		node.output_escaping = nil
		assert_equal text_noenc, node.to_s

		node.output_escaping = true
		assert_equal text, node.to_s
  end

	# Just a sanity check for output escaping.
	def test_output_escaping_sanity
		text = '<bad-script>if (a &lt; b || b &gt; c) { return "text"; }<stop/>return "&gt;&gt;&gt;snip&lt;&lt;&lt;";</bad-script>'
    node = XML::Parser.string(text).parse.root
		affected = node.find('//text()')

		check_escaping = lambda do |flag|
			assert_equal('bad-script', node.name)
			assert_equal(flag, node.output_escaping?)
			affected.each do |x|
				assert_equal(flag ? 'text' : 'textnoenc', x.name)
				assert_equal(flag, x.output_escaping?)
			end
		end

		node.output_escaping = false
		check_escaping[false]

		node.output_escaping = true
		check_escaping[true]

		node.output_escaping = nil
		check_escaping[false]

		node.output_escaping = true
		check_escaping[true]

		affected.first.output_escaping = true
		affected.last.output_escaping = false
		assert node.output_escaping?.nil?
  end

  def test_space_preserve
    node = @doc.root

    node.space_preserve = false
    assert_equal XML::Node::SPACE_DEFAULT, node.space_preserve

    node.space_preserve = true
    assert_equal XML::Node::SPACE_PRESERVE, node.space_preserve
  end

  def test_empty
    text = '<name> </name>'
    doc = XML::Parser.string(text).parse

    node = doc.root
    assert(!node.empty?)
    
    text_node = node.first
    assert(text_node.empty?)
  end
end