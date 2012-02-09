require File.expand_path(File.dirname(__FILE__) + '/test_helper')

# Test cases for the handling of media types
class CssParserMediaTypesTests < Test::Unit::TestCase
  include CssParser

  def setup
    @cp = Parser.new
  end

  def test_finding_by_media_type
    # from http://www.w3.org/TR/CSS21/media.html#at-media-rule
    css = <<-EOT
      @media print {
        body { font-size: 10pt }
      }
      @media screen {
        body { font-size: 13px }
      }
      @media screen, print {
        body { line-height: 1.2 }
      }
      @media screen, 3d-glasses, print and resolution > 90dpi {
        body { color: blue; }
      }
    EOT

    @cp.add_block!(css)

    assert_equal 'font-size: 10pt; line-height: 1.2;', @cp.find_by_selector('body', :print).join(' ')
    assert_equal 'font-size: 13px; line-height: 1.2; color: blue;', @cp.find_by_selector('body', :screen).join(' ')
    assert_equal 'color: blue;', @cp.find_by_selector('body', 'print and resolution > 90dpi'.to_sym).join(' ')
  end

  def test_finding_by_multiple_media_types
    css = <<-EOT
      @media print {
        body { font-size: 10pt }
      }
      @media handheld {
        body { font-size: 13px }
      }
      @media screen, print {
        body { line-height: 1.2 }
      }
    EOT
    @cp.add_block!(css)

    assert_equal 'font-size: 13px; line-height: 1.2;', @cp.find_by_selector('body', [:screen,:handheld]).join(' ')
  end

  def test_adding_block_with_media_types
    css = <<-EOT
      body { font-size: 10pt }
    EOT

    @cp.add_block!(css, :media_types => [:screen])
    
    assert_equal 'font-size: 10pt;', @cp.find_by_selector('body', :screen).join(' ')
    assert @cp.find_by_selector('body', :handheld).empty?
  end
  
  def test_adding_block_and_limiting_media_types1
    css = <<-EOT
      @import "import1.css", print
    EOT
    
    base_dir = File.dirname(__FILE__)  + '/fixtures/'

    @cp.add_block!(css, :only_media_types => :screen, :base_dir => base_dir)
    assert @cp.find_by_selector('div').empty?

  end
  
  def test_adding_block_and_limiting_media_types2
    css = <<-EOT
      @import "import1.css", print and (color)
    EOT
    
    base_dir = File.dirname(__FILE__)  + '/fixtures/'

    @cp.add_block!(css, :only_media_types => 'print and (color)', :base_dir => base_dir)
    assert_match 'color: lime', @cp.find_by_selector('div').join(' ')
  end  

  def test_adding_block_and_limiting_media_types
    css = <<-EOT
      @import "import1.css"
    EOT
    
    base_dir = File.dirname(__FILE__)  + '/fixtures/'
    @cp.add_block!(css, :only_media_types => :print, :base_dir => base_dir)
    assert_match '', @cp.find_by_selector('div').join(' ')
  end  

  def test_adding_rule_set_with_media_type
    @cp.add_rule!('body', 'color: black;', [:handheld,:tty])
    @cp.add_rule!('body', 'color: blue;', :screen)
    assert_equal 'color: black;', @cp.find_by_selector('body', :handheld).join(' ')
  end

  def test_adding_rule_set_with_media_query
    @cp.add_rule!('body', 'color: black;', 'aural and (device-aspect-ratio: 16/9)')
    assert_equal 'color: black;', @cp.find_by_selector('body', 'aural and (device-aspect-ratio: 16/9)').join(' ')
    assert_equal 'color: black;', @cp.find_by_selector('body', :all).join(' ')
  end

  def test_selecting_with_all_media_types
    @cp.add_rule!('body', 'color: black;', [:handheld,:tty])
    assert_equal 'color: black;', @cp.find_by_selector('body', :all).join(' ')
  end


end
