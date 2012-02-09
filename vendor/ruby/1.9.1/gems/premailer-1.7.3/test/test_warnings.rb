# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__)) + '/helper'

class TestWarnings < Test::Unit::TestCase
  include WEBrick

  def test_element_warnings
    html = <<END_HTML
    <!DOCTYPE html>
    <html>
    <head><link rel="alternate" href="http://example.com/"></head>
    <body>
    <form method="post"> Test </form>
    </body>
		</html>
END_HTML
    
    [:nokogiri, :hpricot].each do |adapter|
      warnings = get_warnings(html, adapter)
      assert_equal 2, warnings.length
      assert warnings.any? { |w| w[:message] == 'form HTML element'}
      assert warnings.any? { |w| w[:message] == 'link HTML element'}
    end
  end

  def test_css_warnings
    html = <<END_HTML
    <!DOCTYPE html>
    <html><body>
    <div style="margin: 5px; height: 100px;">Test</div>
    </body></html>
END_HTML

    [:nokogiri, :hpricot].each do |adapter|
      warnings = get_warnings(html, adapter)
      assert_equal 2, warnings.length
      assert warnings.any? { |w| w[:message] == 'height CSS property'}
      assert warnings.any? { |w| w[:message] == 'margin CSS property'}
    end
  end

  def test_css_aliased_warnings
    html = <<END_HTML
    <!DOCTYPE html>
    <html><body>
    <div style="margin-top: 5px;">Test</div>
    </body></html>
END_HTML

    [:nokogiri, :hpricot].each do |adapter|
      warnings = get_warnings(html, adapter)
      assert_equal 1, warnings.length
      assert warnings.any? { |w| w[:message] == 'margin-top CSS property'}
    end
  end

  def test_attribute_warnings
    html = <<END_HTML
    <!DOCTYPE html>
    <html><body>
    <img src="#" ismap>
    </body></html>
END_HTML

    [:nokogiri, :hpricot].each do |adapter|
      warnings = get_warnings(html, adapter)
      assert_equal 1, warnings.length
      assert warnings.any? { |w| w[:message] == 'ismap HTML attribute'}
    end
  end

  def test_warn_level
    html = <<END_HTML
    <!DOCTYPE html>
    <html><body>
    <div style="color: red; font-family: sans-serif;">Test</div>
    </body></html>
END_HTML

    [:nokogiri, :hpricot].each do |adapter|
      warnings = get_warnings(html, adapter, Premailer::Warnings::SAFE)
      assert_equal 2, warnings.length
    end

    [:nokogiri, :hpricot].each do |adapter|
      warnings = get_warnings(html, adapter, Premailer::Warnings::POOR)
      assert_equal 1, warnings.length
    end
  end
  
protected
  def get_warnings(html, adapter = :nokogiri, warn_level = Premailer::Warnings::SAFE)
    pm = Premailer.new(html, {:adpater => adapter, :with_html_string => true, :warn_level => warn_level})
    pm.to_inline_css
    pm.check_client_support  
  end
end
