# encoding: UTF-8

require './test_helper'
require 'test/unit'
require 'stringio'

class TestParser < Test::Unit::TestCase
  def setup
    XML::Error.set_handler(&XML::Error::QUIET_HANDLER)
  end

  def teardown
    GC.start
    GC.start
    GC.start
  end
      
  # -----  Sources  -------
  def test_document
    file = File.expand_path(File.join(File.dirname(__FILE__), 'model/bands.utf-8.xml'))
    parser = XML::Parser.file(file)
    doc = parser.parse

    parser = XML::Parser.document(doc)

    doc = parser.parse

    assert_instance_of(XML::Document, doc)
    assert_instance_of(XML::Parser::Context, parser.context)
  end

  def test_nil_document
    error = assert_raise(TypeError) do
      XML::Parser.document(nil)
    end

    assert_equal("Must pass an XML::Document object", error.to_s)
  end

  def test_file
    file = File.expand_path(File.join(File.dirname(__FILE__), 'model/rubynet.xml'))

    parser = XML::Parser.file(file)
    doc = parser.parse
    assert_instance_of(XML::Document, doc)
    assert_instance_of(XML::Parser::Context, parser.context)
  end

  def test_noexistent_file
    error = assert_raise(XML::Error) do
      XML::Parser.file('i_dont_exist.xml')
    end

    assert_equal('Warning: failed to load external entity "i_dont_exist.xml".', error.to_s)
  end

  def test_nil_file
    error = assert_raise(TypeError) do
      XML::Parser.file(nil)
    end

    assert_equal("can't convert nil into String", error.to_s)
  end

  def test_file_encoding
    file = File.expand_path(File.join(File.dirname(__FILE__), 'model/bands.utf-8.xml'))
    parser = XML::Parser.file(file, :encoding => XML::Encoding::ISO_8859_1)

    error = assert_raise(XML::Error) do
      doc = parser.parse
    end

    assert(error.to_s.match(/Fatal error: Extra content at the end of the document/))

    parser = XML::Parser.file(file, :encoding => XML::Encoding::UTF_8)
    doc = parser.parse
    assert_not_nil(doc)
  end

  def test_file_base_uri
    file = File.expand_path(File.join(File.dirname(__FILE__), 'model/bands.utf-8.xml'))

    parser = XML::Parser.file(file)
    doc = parser.parse
    assert(doc.child.base_uri.match(/test\/model\/bands.utf-8.xml/))

    parser = XML::Parser.file(file, :base_uri => "http://libxml.org")
    doc = parser.parse
    assert(doc.child.base_uri.match(/test\/model\/bands.utf-8.xml/))
  end

  def test_io
    File.open(File.join(File.dirname(__FILE__), 'model/rubynet.xml')) do |io|
      parser = XML::Parser.io(io)
      assert_instance_of(XML::Parser, parser)

      doc = parser.parse
      assert_instance_of(XML::Document, doc)
      assert_instance_of(XML::Parser::Context, parser.context)
    end
  end

  def test_io_gc
    # Test that the reader keeps a reference
    # to the io object
    file = File.open(File.join(File.dirname(__FILE__), 'model/rubynet.xml'))
    parser = XML::Parser.io(file)
    file = nil
    GC.start
    assert(parser.parse)
  end

  def test_nil_io
    error = assert_raise(TypeError) do
      XML::Parser.io(nil)
    end

    assert_equal("Must pass in an IO object", error.to_s)
  end

  def test_string_io
    data = File.read(File.join(File.dirname(__FILE__), 'model/rubynet.xml'))
    string_io = StringIO.new(data)
    parser = XML::Parser.io(string_io)

    doc = parser.parse
    assert_instance_of(XML::Document, doc)
    assert_instance_of(XML::Parser::Context, parser.context)
  end

  def test_string_io_thread
    thread = Thread.new do
      data = File.read(File.join(File.dirname(__FILE__), 'model/rubynet.xml'))
      string_io = StringIO.new(data)
      parser = XML::Parser.io(string_io)

      doc = parser.parse
      assert_instance_of(XML::Document, doc)
      assert_instance_of(XML::Parser::Context, parser.context)
    end

    thread.join
    assert(true)
  end
  
  def test_string
    str = '<ruby_array uga="booga" foo="bar"><fixnum>one</fixnum><fixnum>two</fixnum></ruby_array>'

    parser = XML::Parser.string(str)
    assert_instance_of(XML::Parser, parser)

    doc = parser.parse
    assert_instance_of(XML::Document, doc)
    assert_instance_of(XML::Parser::Context, parser.context)
  end

  def test_nil_string
    error = assert_raise(TypeError) do
      XML::Parser.string(nil)
    end

    assert_equal("wrong argument type nil (expected String)", error.to_s)
  end

  def test_string_options
    xml = <<-EOS
      <!DOCTYPE foo [<!ENTITY foo 'bar'>]>
      <test>
        <cdata><![CDATA[something]]></cdata>
        <entity>&foo;</entity>
      </test>
    EOS

    XML::default_substitute_entities = false

    # Parse normally
    parser = XML::Parser.string(xml)
    doc = parser.parse
    assert_nil(doc.child.base_uri)

    # Cdata section should be cdata nodes
    node = doc.find_first('/test/cdata').child
    assert_equal(XML::Node::CDATA_SECTION_NODE, node.node_type)

    # Entities should not be subtituted
    node = doc.find_first('/test/entity')
    assert_equal('&foo;', node.child.to_s)

    # Parse with options
    parser = XML::Parser.string(xml, :base_uri => 'http://libxml.rubyforge.org',
                                     :options => XML::Parser::Options::NOCDATA | XML::Parser::Options::NOENT)
    doc = parser.parse
    assert_equal(doc.child.base_uri, 'http://libxml.rubyforge.org')

    # Cdata section should be text nodes
    node = doc.find_first('/test/cdata').child
    assert_equal(XML::Node::TEXT_NODE, node.node_type)

    # Entities should be subtituted
    node = doc.find_first('/test/entity')
    assert_equal('bar', node.child.to_s)
  end

  def test_string_encoding
    # ISO_8859_1:
    # ö - f6 in hex, \366 in octal
    # ü - fc in hex, \374 in octal

    xml = <<-EOS
      <bands>
        <metal>m\366tley_cr\374e</metal>
      </bands>
    EOS

    # Parse as UTF_8
    parser = XML::Parser.string(xml, :encoding => XML::Encoding::UTF_8)

    error = assert_raise(XML::Error) do
      doc = parser.parse
    end

    assert_equal("Fatal error: Input is not proper UTF-8, indicate encoding !\nBytes: 0xF6 0x74 0x6C 0x65 at :2.",
                 error.to_s)

    # Parse as ISO_8859_1:
    parser = XML::Parser.string(xml, :encoding => XML::Encoding::ISO_8859_1)
    doc = parser.parse
    node = doc.find_first('//metal')
    if defined?(Encoding)
      assert_equal(Encoding::UTF_8, node.content.encoding)
      assert_equal("m\303\266tley_cr\303\274e", node.content)
    else
      assert_equal("m\303\266tley_cr\303\274e", node.content)
    end
  end

  def test_fd_gc
    # Test opening # of documents up to the file limit for the OS.
    # Ideally it should run until libxml emits a warning,
    # thereby knowing we've done a GC sweep. For the time being,
    # re-open the same doc `limit descriptors` times.
    # If we make it to the end, then we've succeeded,
    # otherwise an exception will be thrown.
    XML::Error.set_handler {|error|}

    max_fd = if RUBY_PLATFORM.match(/mswin32|mingw/i)
      500
    else
      (`ulimit -n`.chomp.to_i) + 1
    end

    file = File.join(File.dirname(__FILE__), 'model/rubynet.xml')
    max_fd.times do
       XML::Parser.file(file).parse
    end
    XML::Error.reset_handler {|error|}
  end

  def test_open_many_files
    1000.times do
      doc = XML::Parser.file('model/atom.xml').parse
    end
  end

  # -----  Errors  ------
  def test_error
    error = assert_raise(XML::Error) do
      XML::Parser.string('<foo><bar/></foz>').parse
    end

    assert_not_nil(error)
    assert_kind_of(XML::Error, error)
    assert_equal("Fatal error: Opening and ending tag mismatch: foo line 1 and foz at :1.", error.message)
    assert_equal(XML::Error::PARSER, error.domain)
    assert_equal(XML::Error::TAG_NAME_MISMATCH, error.code)
    assert_equal(XML::Error::FATAL, error.level)
    assert_nil(error.file)
    assert_equal(1, error.line)
    assert_equal('foo', error.str1)
    assert_equal('foz', error.str2)
    assert_nil(error.str3)
    assert_equal(1, error.int1)
    assert_equal(20, error.int2)
    assert_nil(error.node)
  end

  def test_bad_xml
    parser = XML::Parser.string('<ruby_array uga="booga" foo="bar"<fixnum>one</fixnum><fixnum>two</fixnum></ruby_array>')
    error = assert_raise(XML::Error) do
      assert_not_nil(parser.parse)
    end

    assert_not_nil(error)
    assert_kind_of(XML::Error, error)
    assert_equal("Fatal error: Extra content at the end of the document at :1.", error.message)
    assert_equal(XML::Error::PARSER, error.domain)
    assert_equal(XML::Error::DOCUMENT_END, error.code)
    assert_equal(XML::Error::FATAL, error.level)
    assert_nil(error.file)
    assert_equal(1, error.line)
    assert_nil(error.str1)
    assert_nil(error.str2)
    assert_nil(error.str3)
    assert_equal(0, error.int1)
    assert_equal(20, error.int2)
    assert_nil(error.node)
  end

  # Deprecated methods
  def test_document_deprecated
    file = File.expand_path(File.join(File.dirname(__FILE__), 'model/bands.utf-8.xml'))
    parser = XML::Parser.file(file)
    doc = parser.parse

    parser = XML::Parser.new
    parser.document = doc
    doc = parser.parse

    assert_instance_of(XML::Document, doc)
    assert_instance_of(XML::Parser::Context, parser.context)
  end

  def test_file_deprecated
    file = File.expand_path(File.join(File.dirname(__FILE__), 'model/rubynet.xml'))

    parser = XML::Parser.new
    parser.file = file
    doc = parser.parse
    assert_instance_of(XML::Document, doc)
    assert_instance_of(XML::Parser::Context, parser.context)
  end

  def test_io_deprecated
    File.open(File.join(File.dirname(__FILE__), 'model/rubynet.xml')) do |io|
      parser = XML::Parser.new
      assert_instance_of(XML::Parser, parser)
      parser.io = io

      doc = parser.parse
      assert_instance_of(XML::Document, doc)
      assert_instance_of(XML::Parser::Context, parser.context)
    end
  end

  def test_string_deprecated
    str = '<ruby_array uga="booga" foo="bar"><fixnum>one</fixnum><fixnum>two</fixnum></ruby_array>'

    parser = XML::Parser.new
    parser.string = str
    assert_instance_of(XML::Parser, parser)

    doc = parser.parse
    assert_instance_of(XML::Document, doc)
    assert_instance_of(XML::Parser::Context, parser.context)
  end
end