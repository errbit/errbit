# encoding: UTF-8

require './test_helper'
require 'test/unit'
require 'stringio'

class TestError < Test::Unit::TestCase
  def test_error_codes
    assert_equal(4, XML::Error::DTD)
    assert_equal(4, XML::Error.const_get('DTD'))

    assert_equal(4, XML::Error::DOCUMENT_EMPTY)
    assert_equal(4, XML::Error.const_get('DOCUMENT_EMPTY'))
  end

  def test_invalid_handler
    assert_raise(RuntimeError) do
      XML::Error.set_handler
    end
  end

  def test_handler
    exception = nil
    XML::Error.set_handler do |error|
      exception = error
    end

    # Raise the error
    error = assert_raise(XML::Error) do
      XML::Reader.string('<foo').read
    end
    assert_equal(exception, error)

    # Check the handler worked
    assert_not_nil(exception)
    assert_kind_of(XML::Error, exception)
    assert_equal("Fatal error: Couldn't find end of Start Tag foo at :1.", exception.message)
    assert_equal(XML::Error::PARSER, exception.domain)
    assert_equal(XML::Error::GT_REQUIRED, exception.code)
    assert_equal(XML::Error::FATAL, exception.level)
    assert_nil(exception.file)
    assert_equal(1, exception.line)
    assert_equal('foo', exception.str1)
    assert_nil(exception.str2)
    assert_nil(exception.str3)
    assert_equal(0, exception.int1)
    assert_equal(5, exception.int2)
    assert_nil(exception.node)
  end

  def test_reset_handler
    exception = nil
    XML::Error.set_handler do |error|
      exception = error
    end

    XML::Error.reset_handler
    XML::Reader.string('<foo')
    assert_nil(exception)
  end

  def test_verbose_handler
    XML::Error.set_handler(&XML::Error::VERBOSE_HANDLER)
    output = StringIO.new
    original_stderr = Object::STDERR

    Object.const_set(:STDERR, output)
    begin
      assert_raise(XML::Error) do
        XML::Parser.string('<foo><bar/></foz>').parse
      end
    ensure
      Object.const_set(:STDERR, original_stderr)
    end
    assert_equal("Fatal error: Opening and ending tag mismatch: foo line 1 and foz at :1.\n", output.string)
  end

  def test_no_hanlder
    XML::Error.reset_handler
    output = StringIO.new
    original_stderr = Object::STDERR

    Object.const_set(:STDERR, output)
    begin
      assert_raise(XML::Error) do
        XML::Parser.string('<foo><bar/></foz>').parse
      end
    ensure
      Object.const_set(:STDERR, original_stderr)
    end
    assert_equal('', output.string)
  end

  def test_parse_error
    exception = assert_raise(XML::Error) do
      XML::Parser.string('<foo><bar/></foz>').parse
    end

    assert_instance_of(XML::Error, exception)
    assert_equal("Fatal error: Opening and ending tag mismatch: foo line 1 and foz at :1.", exception.message)
    assert_equal(XML::Error::PARSER, exception.domain)
    assert_equal(XML::Error::TAG_NAME_MISMATCH, exception.code)
    assert_equal(XML::Error::FATAL, exception.level)
    assert_nil(exception.file)
    assert_equal(1, exception.line)
  end

  def test_xpath_error
    doc = XML::Document.file(File.join(File.dirname(__FILE__), 'model/soap.xml'))

    exception = assert_raise(XML::Error) do
      doc.find('/foo[bar=test')
    end

    assert_instance_of(XML::Error, exception)
    assert_equal("Error: Invalid predicate.", exception.message)
    assert_equal(XML::Error::XPATH, exception.domain)
    assert_equal(XML::Error::XPATH_INVALID_PREDICATE_ERROR, exception.code)
    assert_equal(XML::Error::ERROR, exception.level)
    assert_nil(exception.file)
    assert_nil(nil)
  end

  def test_double_parse
    XML::Parser.register_error_handler(lambda {|msg| nil })
    parser = XML::Parser.string("<test>something</test>")
    parser.parse

    error = assert_raise(XML::Error) do
      # Try parsing a second time
      parser.parse
    end

    assert_equal(" LibXML::XML::Error.", error.to_s)
  end

  def test_libxml_parser_empty_string
    xp = XML::Parser.new

    error = assert_raise(TypeError) do
      xp.string = nil
    end
    assert_equal('wrong argument type nil (expected String)', error.to_s)

    error = assert_raise(ArgumentError) do
      xp.string = ''
    end
    assert_equal('Must specify a string with one or more characters', error.to_s)
  end
end