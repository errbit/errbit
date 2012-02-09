# encoding: UTF-8

require './test_helper'
require 'test/unit'

class TestTextNode < Test::Unit::TestCase
  def test_content
    node = XML::Node.new_text('testdata')
    assert_instance_of(XML::Node, node)
    assert_equal('testdata', node.content)
  end

  def test_invalid_content
    error = assert_raise(TypeError) do
      node = XML::Node.new_text(nil)
    end
    assert_equal('wrong argument type nil (expected String)', error.to_s)
  end

	# We use the same facility that libXSLT does here to disable output escaping.
	# This lets you specify that the node's content should be rendered unaltered
	# whenever it is being output.  This is useful for things like <script> and
	# <style> nodes in HTML documents if you don't want to be forced to wrap them
	# in CDATA nodes.  Or if you are sanitizing existing HTML documents and want
	# to preserve the content of any of the text nodes.
	#
	def test_output_escaping
		textnoenc = 'if (a < b || c > d) return "e";'
		text = "if (a &lt; b || c &gt; d) return \"e\";"
 
		node = XML::Node.new_text(textnoenc)
		assert node.output_escaping?
		assert_equal text, node.to_s

		node.output_escaping = false
		assert_equal textnoenc, node.to_s

		node.output_escaping = true
		assert_equal text, node.to_s

		node.output_escaping = nil
		assert_equal textnoenc, node.to_s

		node.output_escaping = true
		assert_equal text, node.to_s
  end

	# Just a sanity check for output escaping.
	def test_output_escaping_sanity
		node = XML::Node.new_text('testdata')
    assert_equal 'text', node.name
		assert node.output_escaping?

		node.output_escaping = false
    assert_equal 'textnoenc', node.name
		assert ! node.output_escaping?

		node.output_escaping = true
    assert_equal 'text', node.name
		assert node.output_escaping?

		node.output_escaping = nil
    assert_equal 'textnoenc', node.name
		assert ! node.output_escaping?

		node.output_escaping = true
    assert_equal 'text', node.name
		assert node.output_escaping?
  end

end
