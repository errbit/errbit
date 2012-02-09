require File.expand_path(File.dirname(__FILE__) + '/test_helper')

# Test cases for reading and generating CSS shorthand properties
class RuleSetCreatingShorthandTests < Test::Unit::TestCase
  include CssParser

  def setup
    @cp = CssParser::Parser.new
  end

# ==== Border shorthand
  def test_combining_borders_into_shorthand
    properties = {'border-top-width' => 'auto', 'border-right-width' => 'thin', 'border-bottom-width' => 'auto', 'border-left-width' => '0px'}

    combined = create_shorthand(properties)

    assert_equal('', combined['border'])
    assert_equal('auto thin auto 0px;', combined['border-width'])

    # after creating shorthand, all long-hand properties should be deleted
    assert_properties_are_deleted(combined, properties)

    # should not combine if any properties are missing
    properties.delete('border-top-width')

    combined = create_shorthand(properties)

    assert_equal '', combined['border-width']
    
    properties = {'border-width' => '22%', 'border-color' => 'rgba(255, 0, 0)'}
    combined = create_shorthand(properties)
    assert_equal '22% rgba(255, 0, 0);', combined['border']
    assert_equal '', combined['border-width']
    
    properties = {'border-top-style' => 'none', 'border-right-style' => 'none', 'border-bottom-style' => 'none', 'border-left-style' => 'none'}
    combined = create_shorthand(properties)
    assert_equal 'none;', combined['border']
  end

# ==== Dimensions shorthand
  def test_combining_dimensions_into_shorthand
    properties = {'margin-right' => 'auto', 'margin-bottom' => '0px', 'margin-left' => 'auto', 'margin-top' => '0px', 
                  'padding-right' => '1.25em', 'padding-bottom' => '11%', 'padding-left' => '3pc', 'padding-top' => '11.25ex'}
    
    combined = create_shorthand(properties)
    
    assert_equal('0px auto;', combined['margin'])
    assert_equal('11.25ex 1.25em 11% 3pc;', combined['padding'])

    # after creating shorthand, all long-hand properties should be deleted
    assert_properties_are_deleted(combined, properties)

    # should not combine if any properties are missing
    properties.delete('margin-right')
    properties.delete('padding-right')

    combined = create_shorthand(properties)

    assert_equal '', combined['margin']
    assert_equal '', combined['padding']
  end
  
# ==== Dimensions shorthand, auto property
  def test_combining_dimensions_into_shorthand_with_auto
    rs = RuleSet.new('#page', "margin: 0; margin-left: auto; margin-right: auto;")
    rs.expand_shorthand!
    assert_equal('auto;', rs['margin-left'])
    rs.create_shorthand!
    assert_equal('0 auto;', rs['margin'])
  end

# ==== Font shorthand
  def test_combining_font_into_shorthand
    # should combine if all font properties are present
    properties = {"font-weight" => "300", "font-size" => "12pt", 
                   "font-family" => "sans-serif", "line-height" => "18px",
                   "font-style" => "oblique", "font-variant" => "small-caps"}
    
    combined = create_shorthand(properties)
    assert_equal('oblique small-caps 300 12pt/18px sans-serif;', combined['font'])

    # after creating shorthand, all long-hand properties should be deleted
    assert_properties_are_deleted(combined, properties)

    # should not combine if any properties are missing
    properties.delete('font-weight')
    combined = create_shorthand(properties)
    assert_equal '', combined['font']
  end

# ==== Background shorthand
  def test_combining_background_into_shorthand
    properties = {'background-image' => 'url(\'chess.png\')', 'background-color' => 'gray', 
                  'background-position' => 'center -10.2%', 'background-attachment' => 'fixed',
                  'background-repeat' => 'no-repeat'}
    
    combined = create_shorthand(properties)
    
    assert_equal('gray url(\'chess.png\') no-repeat center -10.2% fixed;', combined['background'])
    
    # after creating shorthand, all long-hand properties should be deleted
    assert_properties_are_deleted(combined, properties)
  end


# ==== List-style shorthand
  def test_combining_list_style_into_shorthand
    properties = {'list-style-image' => 'url(\'chess.png\')', 'list-style-type' => 'katakana',
                  'list-style-position' => 'inside'}

    combined = create_shorthand(properties)

    assert_equal('katakana inside url(\'chess.png\');', combined['list-style'])

    # after creating shorthand, all long-hand properties should be deleted
    assert_properties_are_deleted(combined, properties)
  end


  def test_property_values_in_url
    rs = RuleSet.new('#header', "background:url(http://example.com/1528/www/top-logo.jpg) no-repeat top right; padding: 79px 0 10px 0;  text-align:left;")
    rs.expand_shorthand!
    assert_equal('top right;', rs['background-position'])
    rs.create_shorthand!
    assert_equal('url(http://example.com/1528/www/top-logo.jpg) no-repeat top right;', rs['background'])
end

protected
  def assert_properties_are_deleted(ruleset, properties)
    properties.each do |property, value|
      assert_equal '', ruleset[property]
    end
  end

  def create_shorthand(properties)
    ruleset = RuleSet.new(nil, nil)
    properties.each do |property, value|
      ruleset[property] = value
    end
    ruleset.create_shorthand!
    ruleset
  end
end
