require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class RuleSetExpandingShorthandTests < Test::Unit::TestCase
  include CssParser

  def setup
    @cp = CssParser::Parser.new
  end

# ==== Dimensions shorthand
  def test_expanding_border_shorthand
    declarations = expand_declarations('border: none')
    assert_equal 'none', declarations['border-right-style']

    declarations = expand_declarations('border: 1px solid red')
    assert_equal '1px', declarations['border-top-width']
    assert_equal 'solid', declarations['border-bottom-style']  
    
    declarations = expand_declarations('border-color: red hsla(255, 0, 0, 5) rgb(2% ,2%,2%)')
    assert_equal 'red', declarations['border-top-color']
    assert_equal 'rgb(2%,2%,2%)', declarations['border-bottom-color']
    assert_equal 'hsla(255,0,0,5)', declarations['border-left-color']

    declarations = expand_declarations('border: thin dot-dot-dash')
    assert_equal 'dot-dot-dash', declarations['border-left-style']
    assert_equal 'thin', declarations['border-left-width']
    assert_nil declarations['border-left-color']
  end

# ==== Dimensions shorthand
  def test_getting_dimensions_from_shorthand
    # test various shorthand forms
    ['margin: 0px auto', 'margin: 0px auto 0px', 'margin: 0px auto 0px'].each do |shorthand|
      declarations = expand_declarations(shorthand)
      assert_equal({"margin-right" => "auto", "margin-bottom" => "0px", "margin-left" => "auto", "margin-top" => "0px"}, declarations)
    end

    # test various units
    ['em', 'ex', 'in', 'px', 'pt', 'pc', '%'].each do |unit|
      shorthand = "margin: 0% -0.123#{unit} 9px -.9pc"
      declarations = expand_declarations(shorthand)
      assert_equal({"margin-right" => "-0.123#{unit}", "margin-bottom" => "9px", "margin-left" => "-.9pc", "margin-top" => "0%"}, declarations)    
    end
  end


# ==== Font shorthand
  def test_getting_font_size_from_shorthand
    ['em', 'ex', 'in', 'px', 'pt', 'pc', '%'].each do |unit|
      shorthand = "font: 300 italic 11.25#{unit}/14px verdana, helvetica, sans-serif;"
      declarations = expand_declarations(shorthand)
      assert_equal("11.25#{unit}", declarations['font-size'])
    end
    
    ['smaller', 'small', 'medium', 'large', 'x-large', 'auto'].each do |unit|
      shorthand = "font: 300 italic #{unit}/14px verdana, helvetica, sans-serif;"
      declarations = expand_declarations(shorthand)
      assert_equal(unit, declarations['font-size'])
    end
  end

  def test_getting_font_families_from_shorthand
    shorthand = "font: 300 italic 12px/14px \"Helvetica-Neue-Light 45\", 'verdana', helvetica, sans-serif;"
    declarations = expand_declarations(shorthand)
    assert_equal("\"Helvetica-Neue-Light 45\", 'verdana', helvetica, sans-serif", declarations['font-family'])
  end

  def test_getting_font_weight_from_shorthand
    ['300', 'bold', 'bolder', 'lighter', 'normal'].each do |unit|
      shorthand = "font: #{unit} italic 12px sans-serif;"
      declarations = expand_declarations(shorthand)
      assert_equal(unit, declarations['font-weight'])
    end

    # ensure normal is the default state
    ['font: normal italic 12px sans-serif;', 'font: italic 12px sans-serif;',
     'font: small-caps normal 12px sans-serif;', 'font: 12px/16px sans-serif;'].each do |shorthand|
      declarations = expand_declarations(shorthand)
      assert_equal('normal', declarations['font-weight'], shorthand)
    end
  end

  def test_getting_font_variant_from_shorthand
    shorthand = "font: small-caps italic 12px sans-serif;"
    declarations = expand_declarations(shorthand)
    assert_equal('small-caps', declarations['font-variant'])

    # ensure normal is the default state
    ['font: normal italic 12px sans-serif;', 'font: italic 12px sans-serif;',
     'font: normal 12px sans-serif;', 'font: 12px/16px sans-serif;'].each do |shorthand|
      declarations = expand_declarations(shorthand)
      assert_equal('normal', declarations['font-variant'], shorthand)
    end
  end

  def test_getting_font_style_from_shorthand
    ['italic', 'oblique'].each do |unit|
      shorthand = "font: normal #{unit} bold 12px sans-serif;"
      declarations = expand_declarations(shorthand)
      assert_equal(unit, declarations['font-style'])
    end

    # ensure normal is the default state
    ['font: normal bold 12px sans-serif;', 'font: small-caps 12px sans-serif;',
     'font: normal 12px sans-serif;', 'font: 12px/16px sans-serif;'].each do |shorthand|
      declarations = expand_declarations(shorthand)
      assert_equal('normal', declarations['font-style'], shorthand)
    end
  end

  def test_getting_line_height_from_shorthand
    ['em', 'ex', 'in', 'px', 'pt', 'pc', '%'].each do |unit|
      shorthand = "font: 300 italic 12px/0.25#{unit} verdana, helvetica, sans-serif;"
      declarations = expand_declarations(shorthand)
      assert_equal("0.25#{unit}", declarations['line-height'])
    end

    # ensure normal is the default state
    ['font: normal bold 12px sans-serif;', 'font: small-caps 12px sans-serif;',
     'font: normal 12px sans-serif;', 'font: 12px sans-serif;'].each do |shorthand|
      declarations = expand_declarations(shorthand)
      assert_equal('normal', declarations['line-height'], shorthand)
    end
  end


# ==== Background shorthand
  def test_getting_background_properties_from_shorthand
    expected = {"background-image" => "url('chess.png')", "background-color" => "gray", "background-repeat" => "repeat", 
              "background-attachment" => "fixed", "background-position" => "50%"}

    shorthand = "background: url('chess.png') gray 50% repeat fixed;"
    declarations = expand_declarations(shorthand)
    assert_equal expected, declarations
  end

  def test_getting_background_position_from_shorthand
    ['em', 'ex', 'in', 'px', 'pt', 'pc', '%'].each do |unit|
      shorthand = "background: url('chess.png') gray 30% -0.15#{unit} repeat fixed;"
      declarations = expand_declarations(shorthand)
      assert_equal("30% -0.15#{unit}", declarations['background-position'])
    end

    ['left', 'center', 'right', 'top', 'bottom', 'inherit'].each do |position|
      shorthand = "background: url('chess.png') #000fff #{position} no-repeat fixed;"
      declarations = expand_declarations(shorthand)
      assert_equal(position, declarations['background-position'])
    end
  end

  def test_getting_background_colour_from_shorthand
    ['blue', 'lime', 'rgb(10,10,10)', 'rgb (  -10%, 99, 300)', '#ffa0a0', '#03c', 'trAnsparEnt', 'inherit'].each do |colour|
      shorthand = "background:#{colour} url('chess.png') center repeat fixed ;"
      declarations = expand_declarations(shorthand)
      assert_equal(colour, declarations['background-color'])
    end
  end

  def test_getting_background_attachment_from_shorthand
    ['scroll', 'fixed', 'inherit'].each do |attachment|
      shorthand = "background:#0f0f0f url('chess.png') center repeat #{attachment};"
      declarations = expand_declarations(shorthand)
      assert_equal(attachment, declarations['background-attachment'])
    end
  end

  def test_getting_background_repeat_from_shorthand
    ['repeat-x', 'repeat-y', 'no-repeat', 'inherit'].each do |repeat|
      shorthand = "background:#0f0f0f none #{repeat};"
      declarations = expand_declarations(shorthand)
      assert_equal(repeat, declarations['background-repeat'])
    end
  end

  def test_getting_background_image_from_shorthand
    ['url("chess.png")', 'url("https://example.org:80/~files/chess.png?123=abc&test#5")', 
     'url(https://example.org:80/~files/chess.png?123=abc&test#5)',
     "url('https://example.org:80/~files/chess.png?123=abc&test#5')", 'none', 'inherit'].each do |image|
      
      shorthand = "background: #0f0f0f #{image} ;"
      declarations = expand_declarations(shorthand)
      assert_equal(image, declarations['background-image'])
    end
  end

  # ==== List-style shorthand
  def test_getting_list_style_properties_from_shorthand
    expected = {'list-style-image' => 'url(\'chess.png\')', 'list-style-type' => 'katakana',
                  'list-style-position' => 'inside'}

    shorthand = "list-style: katakana inside url(\'chess.png\');"
    declarations = expand_declarations(shorthand)
    assert_equal expected, declarations
  end

  def test_getting_list_style_position_from_shorthand
    ['inside', 'outside'].each do |position|
      shorthand = "list-style: katakana #{position} url('chess.png');"
      declarations = expand_declarations(shorthand)
      assert_equal(position, declarations['list-style-position'])
    end
  end

  def test_getting_list_style_type_from_shorthand
    ['disc', 'circle', 'square', 'decimal', 'decimal-leading-zero', 'lower-roman', 'upper-roman', 'lower-greek', 'lower-alpha', 'lower-latin', 'upper-alpha', 'upper-latin', 'hebrew', 'armenian', 'georgian', 'cjk-ideographic', 'hiragana', 'katakana', 'hira-gana-iroha', 'katakana-iroha', 'none'].each do |type|
      shorthand = "list-style: #{type} inside url('chess.png');"
      declarations = expand_declarations(shorthand)
      assert_equal(type, declarations['list-style-type'])
    end
  end

protected
  def expand_declarations(declarations)
    ruleset = RuleSet.new(nil, declarations)
    ruleset.expand_shorthand!

    collected = {}
    ruleset.each_declaration do |prop, val, imp|
      collected[prop.to_s] = val.to_s
    end
    collected  
  end
end
