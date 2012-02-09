# encoding: UTF-8

require './test_helper'
require "test/unit"

class TC_XML_XPointer < Test::Unit::TestCase
  def setup()
    xp = XML::Parser.string('<!DOCTYPE ra [<!ELEMENT ra (foo+)><!ATTLIST ra id ID #IMPLIED><!ELEMENT foo (#PCDATA)><!ATTLIST foo id ID #IMPLIED>]><ra id="start"><foo id="one">one</foo><foo id="two">two</foo><foo id="three">three</foo></ra>')
    @doc = xp.parse
    assert_instance_of(XML::Document, @doc)
    @root = @doc.root
    assert_instance_of(XML::Node, @root)
  end

  def teardown()
    @doc = nil
    @root = nil
    @xptr = nil
  end

  def test_libxml_xpointer_id
    xptr = @root.pointer('xpointer(id("two"))')
    assert_instance_of(XML::XPath::Object, xptr)
    xptr.each do |node|
      # It seems from the spec that the pointer should
      # be the whole node, rather than just the ID attr.
      assert_equal('two', node.content)
      assert_instance_of(XML::Node, node)
      assert_equal('two', node['id'])
    end

    # FIXME: Not sure at all about this kind of range
    if ENV['NOTWORKING']
      @xptr = @root.pointer('xpointer(id("two")) xpointer(id("three"))')
      assert_instance_of(XML::XPath, @xptr)
      assert_instance_of(XML::Node::Set, @xptr.set)
      assert_equal(2, @xptr.set.length)
      for n in @xptr.set
        assert_match(/two|three/, n.to_s)
      end
    end
  end

  # FIXME: There is a bug in these ranges...
  if ENV['NOTWORKING']
    def test_libxml_xpointer_range()
      nstart = nend = nil
      @xptr = @root.pointer('xpointer(id("one"))').set
      @xptr.each{|n| nstart = n}
      assert_instance_of(XML::Node, nstart)
      @xptr = @root.pointer('xpointer(id("three"))').set
      @xptr.each{|n| nend = n}
      assert_instance_of(XML::Node, nend)
      range = XML::XPointer.range(nstart, nend)
      assert_instance_of(XML::XPath, range)
      assert_instance_of(XML::Node::Set, range.set)

      for n in range.set
        assert_match(/one|two|three/, n.to_s)
      end
      assert_equal(3, range.set.length)
    end
  end

#  def test_libxml_xpointer_start_point()
#    @xptr = @root.pointer('xpointer(start-point("one"))')
#    assert_instance_of(XML::XPath, @xptr)
#    set = @xptr.set
#    assert_instance_of(XML::Node::Set, set)
#    for n in set
#      assert_match(/one|two|three/, n.to_s)
#    end
#  end
end
