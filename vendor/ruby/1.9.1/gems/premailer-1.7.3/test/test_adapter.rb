require File.expand_path(File.dirname(__FILE__)) + '/helper'

class TestAdapter < Test::Unit::TestCase

  def test_default_to_best_available
    require 'hpricot'
    assert_equal 'Premailer::Adapter::Hpricot', Premailer::Adapter.use.name
  end

  def test_settable_via_symbol
    Premailer::Adapter.use = :hpricot
    assert_equal 'Premailer::Adapter::Hpricot', Premailer::Adapter.use.name
  end

  def test_adapters_are_findable_by_symbol
    assert_equal 'Premailer::Adapter::Hpricot', Premailer::Adapter.find(:hpricot).name
  end

  def test_adapters_are_findable_by_class
    assert_equal 'Premailer::Adapter::Hpricot', Premailer::Adapter.find(Premailer::Adapter::Hpricot).name
  end

  def test_raises_argument_error
    assert_raises(ArgumentError, "Invalid adapter: unknown") {
      Premailer::Adapter.find(:unknown)
    }
  end

end
