#!/usr/bin/env ruby

require 'test/unit'
require 'term/ansicolor'

class String
  include Term::ANSIColor
end

class Color
  extend Term::ANSIColor
end

class StringLike
  def initialize(string)
    @string = string
  end

  def to_str
    @string
  end
end

class ANSIColorTest < Test::Unit::TestCase
  include Term::ANSIColor

  def setup
    @string = "red"
    @string_red = "\e[31mred\e[0m"
    @string_red_on_green = "\e[42m\e[31mred\e[0m\e[0m"
    @string_like = StringLike.new(@string)
    @string_like_red = StringLike.new(@string_red)
  end

  attr_reader :string, :string_red, :string_red_on_green, :string_like, :string_like_red

  def test_red
    assert_equal string_red, string.red
    assert_equal string_red, Color.red(string)
    assert_equal string_red, Color.red { string }
    assert_equal string_red, Term::ANSIColor.red { string }
    assert_equal string_red, red { string }
  end

  def test_red_on_green
    assert_equal string_red_on_green, string.red.on_green
    assert_equal string_red_on_green, Color.on_green(Color.red(string))
    assert_equal string_red_on_green, Color.on_green { Color.red { string } }
    assert_equal string_red_on_green,
      Term::ANSIColor.on_green { Term::ANSIColor.red { string } }
    assert_equal string_red_on_green, on_green { red { string } }
  end


  def test_uncolored
    assert_equal string, string_red.uncolored
    assert_equal string, Color.uncolored(string_red)
    assert_equal string, Color.uncolored(string_like_red)
    assert_equal string, Color.uncolored { string_red }
    assert_equal string, Color.uncolored { string_like_red }
    assert_equal string, Term::ANSIColor.uncolored { string_red }
    assert_equal string, Term::ANSIColor.uncolored { string_like_red }
    assert_equal string, uncolored { string }
    assert_equal string, uncolored { string_like_red }
    assert_equal "", uncolored(Object.new)
  end

  def test_attributes
    foo = 'foo'
    for (a, _) in Term::ANSIColor.attributes
      # skip clear for Ruby 1.9 which implements String#clear to empty the string
      if a != :clear || Term::ANSIColor.support?(:clear)
        assert_not_equal foo, foo_colored = foo.__send__(a)
        assert_equal foo, foo_colored.uncolored
      end
      assert_not_equal foo, foo_colored = Color.__send__(a, foo)
      assert_equal foo, Color.uncolored(foo_colored)
      assert_not_equal foo, foo_colored = Color.__send__(a) { foo }
      assert_equal foo, Color.uncolored { foo_colored }
      assert_not_equal foo, foo_colored = Term::ANSIColor.__send__(a) { foo }
      assert_equal foo, Term::ANSIColor.uncolored { foo_colored }
      assert_not_equal foo, foo_colored = __send__(a) { foo }
      assert_equal foo, uncolored { foo_colored }
    end
  end

  def test_coloring_string_like
    assert_equal "\e[31mred\e[0m", red(string_like)
  end
end
