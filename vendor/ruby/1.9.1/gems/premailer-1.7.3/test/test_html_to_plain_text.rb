# encoding: utf-8
require File.expand_path(File.dirname(__FILE__)) + '/helper'

class TestHtmlToPlainText < Test::Unit::TestCase
  include HtmlToPlainText

  def test_to_plain_text_with_fragment
    premailer = Premailer.new('<p>Test</p>', :with_html_string => true)
    assert_match /Test/, premailer.to_plain_text
  end

  def test_to_plain_text_with_body
    html = <<END_HTML
    <html>
    <title>Ignore me</title>
    <body>
		<p>Test</p>
		</body>
		</html>
END_HTML

    premailer = Premailer.new(html, :with_html_string => true)
    assert_match /Test/, premailer.to_plain_text
  end

  def test_to_plain_text_with_malformed_body
    html = <<END_HTML
    <html>
    <title>Ignore me</title>
    <body>
		<p>Test
END_HTML

    premailer = Premailer.new(html, :with_html_string => true)
    assert_match /Test/, premailer.to_plain_text
  end

  def test_specialchars
    assert_plaintext 'cédille garçon & à ñ', 'c&eacute;dille gar&#231;on &amp; &agrave; &ntilde;'
  end

  def test_stripping_whitespace
    assert_plaintext "text\ntext", "  \ttext\ntext\n"
    assert_plaintext "a\na", "  \na \n a \t"
    assert_plaintext "a\n\na", "  \na \n\t \n \n a \t"
    assert_plaintext "test text", "test text&nbsp;"
    assert_plaintext "test text", "test        text"
  end

  def test_wrapping_spans
    html = <<END_HTML
    <html>
    <body>
		<p><span>Test</span>
		<span>line 2</span>
		</p>
END_HTML

    premailer = Premailer.new(html, :with_html_string => true)
    assert_match /Test line 2/, premailer.to_plain_text
  end

  def test_line_breaks
    assert_plaintext "Test text\nTest text", "Test text\r\nTest text"
    assert_plaintext "Test text\nTest text", "Test text\rTest text"
  end

  def test_lists
    assert_plaintext "* item 1\n* item 2", "<li class='123'>item 1</li> <li>item 2</li>\n"
    assert_plaintext "* item 1\n* item 2\n* item 3", "<li>item 1</li> \t\n <li>item 2</li> <li> item 3</li>\n"
  end
  
  def test_stripping_html
    assert_plaintext 'test text', "<p class=\"123'45 , att\" att=tester>test <span class='te\"st'>text</span>\n"
  end

  def test_paragraphs_and_breaks
    assert_plaintext "Test text\n\nTest text", "<p>Test text</p><p>Test text</p>"
    assert_plaintext "Test text\n\nTest text", "\n<p>Test text</p>\n\n\n\t<p>Test text</p>\n"
    assert_plaintext "Test text\nTest text", "\n<p>Test text<br/>Test text</p>\n"
    assert_plaintext "Test text\nTest text", "\n<p>Test text<br> \tTest text<br></p>\n"
    assert_plaintext "Test text\n\nTest text", "Test text<br><BR />Test text"
  end
  
  def test_headings
    assert_plaintext "****\nTest\n****", "<h1>Test</h1>"
    assert_plaintext "****\nTest\n****", "\t<h1>\nTest</h1> "
    assert_plaintext "***********\nTest line 1\nTest 2\n***********", "\t<h1>\nTest line 1<br>Test 2</h1> "
    assert_plaintext "****\nTest\n****\n\n****\nTest\n****", "<h1>Test</h1> <h1>Test</h1>"
    assert_plaintext "----\nTest\n----", "<h2>Test</h2>"
    assert_plaintext "Test\n----", "<h3> <span class='a'>Test </span></h3>"
  end
  
  def test_wrapping_lines
    raw = ''
    100.times { raw += 'test ' }

    txt = convert_to_text(raw, 20)

    lens = []
    txt.each_line { |l| lens << l.length }
    assert lens.max <= 20
  end

  def test_links
    # basic
    assert_plaintext 'Link ( http://example.com/ )', '<a href="http://example.com/">Link</a>'
    
    # nested html
    assert_plaintext 'Link ( http://example.com/ )', '<a href="http://example.com/"><span class="a">Link</span></a>'
    
    # complex link
    assert_plaintext 'Link ( http://example.com:80/~user?aaa=bb&c=d,e,f#foo )', '<a href="http://example.com:80/~user?aaa=bb&amp;c=d,e,f#foo">Link</a>'
    
    # attributes
    assert_plaintext 'Link ( http://example.com/ )', '<a title=\'title\' href="http://example.com/">Link</a>'
    
    # spacing
    assert_plaintext 'Link ( http://example.com/ )', '<a href="   http://example.com/ "> Link </a>'
    
    # multiple
    assert_plaintext 'Link A ( http://example.com/a/ ) Link B ( http://example.com/b/ )', '<a href="http://example.com/a/">Link A</a> <a href="http://example.com/b/">Link B</a>'

    # merge links
    assert_plaintext 'Link ( %%LINK%% )', '<a href="%%LINK%%">Link</a>'
    assert_plaintext 'Link ( [LINK] )', '<a href="[LINK]">Link</a>'
    assert_plaintext 'Link ( {LINK} )', '<a href="{LINK}">Link</a>'
    
    # unsubscribe
    assert_plaintext 'Link ( [[!unsubscribe]] )', '<a href="[[!unsubscribe]]">Link</a>'
  end
  
  # see https://github.com/alexdunae/premailer/issues/72
  def test_multiple_links_per_line
    assert_plaintext 'This is link1 ( http://www.google.com ) and link2 ( http://www.google.com ) is next.', 
                     '<p>This is <a href="http://www.google.com" >link1</a> and <a href="http://www.google.com" >link2 </a> is next.</p>',
                     nil, 10000
  end

  # see https://github.com/alexdunae/premailer/issues/72
  def test_links_within_headings
    assert_plaintext "****************************\nTest ( http://example.com/ )\n****************************", 
                     "<h1><a href='http://example.com/'>Test</a></h1>"
  end

  def assert_plaintext(out, raw, msg = nil, line_length = 65)
    assert_equal out, convert_to_text(raw, line_length), msg
  end
end
