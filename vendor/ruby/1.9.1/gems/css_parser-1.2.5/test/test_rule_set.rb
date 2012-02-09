require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require "set"

# Test cases for parsing CSS blocks
class RuleSetTests < Test::Unit::TestCase
  include CssParser

  def setup
    @cp = Parser.new
  end

  def test_setting_property_values
    rs = RuleSet.new(nil, nil)
    
    rs['background-color'] = 'red'
    assert_equal('red;', rs['background-color'])

    rs['background-color'] = 'blue !important;'
    assert_equal('blue !important;', rs['background-color'])
  end

  def test_getting_property_values
    rs = RuleSet.new('#content p, a', 'color: #fff;')
    assert_equal('#fff;', rs['color'])
  end

  def test_getting_property_value_ignoring_case
    rs = RuleSet.new('#content p, a', 'color: #fff;')
    assert_equal('#fff;', rs['  ColoR '])
  end

  def test_each_selector
    expected = [
       {:selector => "#content p", :declarations => "color: #fff;", :specificity => 101},
       {:selector => "a", :declarations => "color: #fff;", :specificity => 1}
    ]

    actual = []
    rs = RuleSet.new('#content p, a', 'color: #fff;')
    rs.each_selector do |sel, decs, spec|
      actual << {:selector => sel, :declarations => decs, :specificity => spec}
    end

    assert_equal(expected, actual)
  end

  def test_each_declaration
    expected = Set.new([
       {:property => 'margin', :value => '1px -0.25em', :is_important => false},
       {:property => 'background', :value => 'white none no-repeat', :is_important => true},
       {:property => 'color', :value => '#fff', :is_important => false}
    ])

    actual = Set.new
    rs = RuleSet.new(nil, 'color: #fff; Background: white none no-repeat !important; margin: 1px -0.25em;')
    rs.each_declaration do |prop, val, imp|
      actual << {:property => prop, :value => val, :is_important => imp}
    end

    assert_equal(expected, actual)
  end

  def test_each_declaration_respects_order
    css_fragment = "margin: 0; padding: 20px; margin-bottom: 28px;"
    rs           = RuleSet.new(nil, css_fragment)
    expected     = %w(margin padding margin-bottom)
    actual       = []
    rs.each_declaration { |prop, val, imp| actual << prop }
    assert_equal(expected, actual)
  end

  def test_declarations_to_s
    declarations = 'color: #fff; font-weight: bold;'
    rs = RuleSet.new('#content p, a', declarations)
    assert_equal(declarations.split(' ').sort, rs.declarations_to_s.split(' ').sort)
  end

  def test_important_declarations_to_s
    declarations = 'color: #fff; font-weight: bold !important;'
    rs = RuleSet.new('#content p, a', declarations)
    assert_equal(declarations.split(' ').sort, rs.declarations_to_s.split(' ').sort)
  end

  def test_overriding_specificity
    rs = RuleSet.new('#content p, a', 'color: white', 1000)
    rs.each_selector do |sel, decs, spec|
      assert_equal 1000, spec
    end
  end
end
