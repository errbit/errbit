# encoding: UTF-8

require './test_helper'
require 'stringio'
require 'test/unit'

class HTMLParserTest < Test::Unit::TestCase
  def html_file
    File.expand_path(File.join(File.dirname(__FILE__), 'model/ruby-lang.html'))
  end

  # -----  Sources  ------
  def test_file
    xp = XML::HTMLParser.file(html_file)
    assert_instance_of(XML::HTMLParser, xp)
    doc = xp.parse
    assert_not_nil(doc)
  end

  def test_noexistent_file
    error = assert_raise(XML::Error) do
      XML::HTMLParser.file('i_dont_exist.xml')
    end

    assert_equal('Warning: failed to load external entity "i_dont_exist.xml".', error.to_s)
  end

  def test_nil_file
    error = assert_raise(TypeError) do
      XML::HTMLParser.file(nil)
    end

    assert_equal("can't convert nil into String", error.to_s)
  end

  def test_io
    File.open(html_file) do |io|
      xp = XML::HTMLParser.io(io)
      assert_instance_of(XML::HTMLParser, xp)

      doc = xp.parse
      assert_instance_of(XML::Document, doc)
    end
  end

  def test_io_gc
    # Test that the reader keeps a reference
    # to the io object
    file = File.open(html_file)
    parser = XML::HTMLParser.io(file)
    file = nil
    GC.start
    assert(parser.parse)
  end

  def test_nil_io
    error = assert_raise(TypeError) do
      XML::HTMLParser.io(nil)
    end

    assert_equal("Must pass in an IO object", error.to_s)
  end

  def test_string_io
    data = File.read(html_file)
    io = StringIO.new(data)
    xp = XML::HTMLParser.io(io)
    assert_instance_of(XML::HTMLParser, xp)

    doc = xp.parse
    assert_instance_of(XML::Document, doc)
  end

  def test_string
    str = '<html><body><p>hi</p></body></html>'
    xp = XML::HTMLParser.string(str)

    assert_instance_of(XML::HTMLParser, xp)
    assert_instance_of(XML::HTMLParser, xp)

    doc = xp.parse
    assert_instance_of(XML::Document, doc)
  end

  def test_nil_string
    error = assert_raise(TypeError) do
      XML::HTMLParser.string(nil)
    end

    assert_equal("wrong argument type nil (expected String)", error.to_s)
  end

  def test_parse
    html = <<-EOS
      <html>
        <head>
          <meta name=keywords content=nasty>
        </head>
        <body>Hello<br>World</html>
   EOS

    parser = XML::HTMLParser.string(html)
    doc = parser.parse
    assert_instance_of XML::Document, doc

    root = doc.root
    assert_instance_of XML::Node, root
    assert_equal 'html', root.name

    head = root.child
    assert_instance_of XML::Node, head
    assert_equal 'head', head.name

    meta = head.child
    assert_instance_of XML::Node, meta
    assert_equal 'meta', meta.name
    assert_equal 'keywords', meta[:name]
    assert_equal 'nasty', meta[:content]

    body = head.next
    assert_instance_of XML::Node, body
    assert_equal 'body', body.name

    hello = body.child
    # It appears that some versions of libxml2 add a layer of <p>
    # cant figure our why or how, so this skips it if there
    hello = hello.child if hello.name == "p"

    assert_instance_of XML::Node, hello
    assert_equal 'Hello', hello.content

    br = hello.next
    assert_instance_of XML::Node, br
    assert_equal 'br', br.name

    world = br.next
    assert_instance_of XML::Node, world
    assert_equal 'World', world.content
  end

  def test_no_implied
    html = "hello world"
    parser = XML::HTMLParser.string(html, :options => XML::HTMLParser::Options::NOIMPLIED)
    doc = parser.parse
    assert_equal("<p>#{html}</p>", doc.root.to_s)
  end

  def test_open_many_files
    1000.times do
      doc = XML::HTMLParser.file('model/ruby-lang.html').parse
    end
  end
end