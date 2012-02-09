# coding: iso-8859-1
require File.expand_path(File.dirname(__FILE__) + '/test_helper')

# Test cases for CSS regular expressions
#
# see http://www.w3.org/TR/CSS21/syndata.html and
# http://www.w3.org/TR/CSS21/grammar.html
class CssParserRegexpTests < Test::Unit::TestCase
  def test_strings
    # complete matches
    ['"abcd"', '" A sd sédrcv \'dsf\' asd rfg asd"', '"A\ d??ef 123!"',
     "\"this is\\\n a test\"", '"back\67round"', '"r\000065 ed"',
     "'abcd'", "' A sd sedrcv \"dsf\" asd rf—&23$%#%$g asd'", "'A\\\n def 123!'",
     "'this is\\\n a test'", "'back\\67round'", "'r\\000065 ed'"     
    ].each do |str|
      assert_equal str, str.match(CssParser::RE_STRING).to_s
    end

    test_string = "p { background: red url(\"url\\.'p'ng\"); }"
    assert_equal "\"url\\.'p'ng\"", test_string.match(CssParser::RE_STRING).to_s
  
  end

  def test_unicode
    ['back\67round', 'r\000065 ed', '\00006C'].each do |str|
      assert_match(Regexp.new(CssParser::RE_UNICODE), str)
    end
  end

  def test_colour
    ['color: #fff', 'color:#f0a09c;', 'color: #04A', 'color: #04a9CE',
     'color: rgb(100, -10%, 300);', 'color: rgb(10,10,10)', 'color:rgb(12.7253%, -12%,0)',
     'color: black', 'color:Red;', 'color: AqUa;', 'color: blue   ', 'color: transparent'
    ].each do |colour|
      assert_match(CssParser::RE_COLOUR, colour)
    end

    ['color: #fa', 'color:#f009c;', 'color: #04G', 'color: #04a9Cq',
     'color: rgb 100, -10%, 300;', 'color: rgb 10,10,10', 'color:rgb(12px, -12%,0)',
     'color:fuscia;', 'color: thick'
    ].each do |colour|
      assert_no_match(CssParser::RE_COLOUR, colour)
    end
  end

  def test_uris
    crazy_uri = 'http://www.example.com:80/~/redb%20all.png?test=test&test;test+test#test!'
    
    assert_equal "url('#{crazy_uri}')", 
                  "li { list-style: url('#{crazy_uri}') disc }".match(CssParser::RE_URI).to_s

    assert_equal "url(#{crazy_uri})", 
                  "li { list-style: url(#{crazy_uri}) disc }".match(CssParser::RE_URI).to_s

    assert_equal "url(\"#{crazy_uri}\")", 
                 "li { list-style: url(\"#{crazy_uri}\") disc }".match(CssParser::RE_URI).to_s
  end


protected
  def load_test_file(filename)
    fh = File.new("fixtures/#{filename}", 'r')
    test_file = fh.read
    fh.close

    return test_file
   end

end
