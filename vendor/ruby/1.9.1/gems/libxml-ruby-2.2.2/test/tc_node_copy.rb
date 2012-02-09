# encoding: UTF-8

require './test_helper'
require 'test/unit'

# see mailing list archive
# [libxml-devel] Segmentation fault when add the cloned/copied node
# 2007/11/27 20:51

class TestNodeCopy < Test::Unit::TestCase
  def setup
    str = <<-STR
      <html><body>
        <div class="textarea" id="t1" style="STATIC">foo</div>
        <div class="textarea" id="t2" style="STATIC">bar</div>
      </body></html>
    STR

    doc = XML::Parser.string(str).parse

    xpath = "//div"
    @div1 = doc.find(xpath).to_a[0]
    @div2 = doc.find(xpath).to_a[1]
  end

  def test_libxml_node_copy_not_segv
    @div2.each do |child|
      c = child.copy(false)
      @div1 << c
    end
    assert @div1.to_s =~ /foo/
  end

  def test_libxml_node_clone_not_segv
    @div2.each do |child|
      c = child.clone
      @div1 << c
    end
    assert @div1.to_s =~ /foo/
  end

end # TC_XML_Node_Copy
