# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__)) + '/helper'

class TestPremailer < Test::Unit::TestCase
  def test_related_attributes
    flunk 'Not implemented'
    local_setup
    
    # h1 { text-align: center; }
    assert_equal 'center', @doc.at('h1')['align']
    
    # td { vertical-align: top; }
    assert_equal 'top', @doc.at('td')['valign']
    
    # p { vertical-align: top; } -- not allowed
    assert_nil @doc.at('p')['valign']
    
    # no align attr is specified for <p> elements, so it should not appear
    assert_nil @doc.at('p.unaligned')['align']
    
    # .contact { background: #9EC03B url("contact_bg.png") repeat 0 0; }
    assert_equal '#9EC03B', @doc.at('td.contact')['bgcolor']
    
    # body { background-color: #9EBF00; }
    assert_equal '#9EBF00', @doc.at('body')['bgcolor']
  end

  def test_merging_cellpadding
    flunk 'Not implemented'
    local_setup('cellpadding.html', {:prefer_cellpadding => true})
    assert_equal '0', @doc.at('#t1')['cellpadding']
    assert_match /padding\:/i, @doc.at('#t1 td')['style']

    assert_equal '5', @doc.at('#t2')['cellpadding']
    assert_no_match /padding\:/i, @doc.at('#t2 td')['style']
    
    assert_nil @doc.at('#t3')['cellpadding']
    assert_match /padding\:/i, @doc.at('#t3 td')['style']

    assert_nil @doc.at('#t4')['cellpadding']
    assert_match /padding\:/i, @doc.at('#t4a')['style']
    assert_match /padding\:/i, @doc.at('#t4b')['style']
  end
  
  def test_preserving_media_queries
    flunk 'Not implemented'
    local_setup
    assert_match /display\: none/i, @doc.at('#iphone')['style']
  end
end  