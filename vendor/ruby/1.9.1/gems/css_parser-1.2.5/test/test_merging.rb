require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class MergingTests < Test::Unit::TestCase
  include CssParser

  def setup
    @cp = CssParser::Parser.new
  end

  def test_simple_merge
    rs1 = RuleSet.new(nil, 'color: black;')
    rs2 = RuleSet.new(nil, 'margin: 0px;')
    merged = CssParser.merge(rs1, rs2)
    assert_equal '0px;', merged['margin']
    assert_equal 'black;', merged['color']
  end

  def test_merging_array
    rs1 = RuleSet.new(nil, 'color: black;')
    rs2 = RuleSet.new(nil, 'margin: 0px;')
    merged = CssParser.merge([rs1, rs2])
    assert_equal '0px;', merged['margin']
    assert_equal 'black;', merged['color']
  end


  def test_merging_multiple
    rs1 = RuleSet.new(nil, 'color: black;')
    rs2 = RuleSet.new(nil, 'margin: 0px;')
    rs3 = RuleSet.new(nil, 'margin: 5px;')
    merged = CssParser.merge(rs1, rs2, rs3)
    assert_equal '5px;', merged['margin']
  end

  def test_multiple_selectors_should_have_zero_specificity
    rs1 = RuleSet.new('p, a[rel="external"]', 'color: black;')
    rs2 = RuleSet.new('a', 'color: blue;')
    merged = CssParser.merge(rs1, rs2)
    assert_equal 'blue;', merged['color']
  end

  def test_setting_specificity
    rs1 = RuleSet.new(nil, 'color: red;', 20)
    rs2 = RuleSet.new(nil, 'color: blue;', 10)
    merged = CssParser.merge(rs1, rs2)
    assert_equal 'red;', merged['color']
  end

  def test_properties_should_be_case_insensitive
    rs1 = RuleSet.new(nil, ' CoLor   : red  ;', 20)
    rs2 = RuleSet.new(nil, 'color: blue;', 10)
    merged = CssParser.merge(rs1, rs2)
    assert_equal 'red;', merged['color']
  end

  def test_merging_backgrounds
    rs1 = RuleSet.new(nil, 'background-color: black;')
    rs2 = RuleSet.new(nil, 'background-image: none;')
    merged = CssParser.merge(rs1, rs2)
    assert_equal 'black none;', merged['background']
  end

  def test_merging_dimensions
    rs1 = RuleSet.new(nil, 'margin: 3em;')
    rs2 = RuleSet.new(nil, 'margin-left: 1em;')
    merged = CssParser.merge(rs1, rs2)
    assert_equal '3em 3em 3em 1em;', merged['margin']
  end

  def test_merging_fonts
    rs1 = RuleSet.new(nil, 'font: 11px Arial;')
    rs2 = RuleSet.new(nil, 'font-weight: bold;')
    merged = CssParser.merge(rs1, rs2)
    assert_equal 'bold 11px Arial;', merged['font']
  end

  def test_raising_error_on_bad_type
    assert_raise ArgumentError do
      CssParser.merge([1,2,3])
    end
  end

  def test_returning_early_with_only_one_params
    rs = RuleSet.new(nil, 'font-weight: bold;')
    merged = CssParser.merge(rs)
    assert_equal rs.object_id, merged.object_id
  end
  
  def test_merging_important
    rs1 = RuleSet.new(nil, 'color: black !important;')
    rs2 = RuleSet.new(nil, 'color: red;')
    merged = CssParser.merge(rs1, rs2)
    assert_equal 'black !important;', merged['color']    
  end

  def test_merging_multiple_important
    rs1 = RuleSet.new(nil, 'color: black !important;', 1000)
    rs2 = RuleSet.new(nil, 'color: red !important;', 1)
    merged = CssParser.merge(rs1, rs2)
    assert_equal 'black !important;', merged['color']    

    rs3 = RuleSet.new(nil, 'color: blue !important;', 1000)
    merged = CssParser.merge(rs1, rs2, rs3)
    assert_equal 'blue !important;', merged['color']    


  end

  def test_merging_shorthand_important
    rs1 = RuleSet.new(nil, 'background: black none !important;')
    rs2 = RuleSet.new(nil, 'background-color: red;')
    merged = CssParser.merge(rs1, rs2)
    assert_equal 'black !important;', merged['background-color']
  end

end
