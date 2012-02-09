require File.expand_path(File.dirname(__FILE__) + '/test_helper')

# Test cases for reading and generating CSS shorthand properties
class CssParserBasicTests < Test::Unit::TestCase
  include CssParser

  def setup
    @cp = CssParser::Parser.new
    @css = <<-EOT
      html, body, p { margin: 0px; }
      p { padding: 0px; }
      #content { font: 12px/normal sans-serif; }
      .content { color: red; }
    EOT
  end

  def test_finding_by_selector
    @cp.add_block!(@css)
    assert_equal 'margin: 0px;', @cp.find_by_selector('body').join(' ')
    assert_equal 'margin: 0px; padding: 0px;', @cp.find_by_selector('p').join(' ')
    assert_equal 'font: 12px/normal sans-serif;', @cp.find_by_selector('#content').join(' ')
    assert_equal 'color: red;', @cp.find_by_selector('.content').join(' ')
  end

  def test_adding_block
    @cp.add_block!(@css)
    assert_equal 'margin: 0px;', @cp.find_by_selector('body').join
  end

  def test_adding_block_without_closing_brace
    @cp.add_block!('p { color: red;')
    assert_equal 'color: red;', @cp.find_by_selector('p').join
  end

  def test_adding_a_rule
    @cp.add_rule!('div', 'color: blue;')
    assert_equal 'color: blue;', @cp.find_by_selector('div').join(' ')
  end

  def test_adding_a_rule_set
    rs = CssParser::RuleSet.new('div', 'color: blue;')
    @cp.add_rule_set!(rs)
    assert_equal 'color: blue;', @cp.find_by_selector('div').join(' ')
  end

  def test_toggling_uri_conversion
    # with conversion
    cp_with_conversion = Parser.new(:absolute_paths => true)
    cp_with_conversion.add_block!("body { background: url('../style/yellow.png?abc=123') };",
                                  :base_uri => 'http://example.org/style/basic.css')

    assert_equal "background: url('http://example.org/style/yellow.png?abc=123');",
                 cp_with_conversion['body'].join(' ')
    
    # without conversion
    cp_without_conversion = Parser.new(:absolute_paths => false)
    cp_without_conversion.add_block!("body { background: url('../style/yellow.png?abc=123') };",
                                     :base_uri => 'http://example.org/style/basic.css')

    assert_equal "background: url('../style/yellow.png?abc=123');",
                 cp_without_conversion['body'].join(' ')
  end

end
