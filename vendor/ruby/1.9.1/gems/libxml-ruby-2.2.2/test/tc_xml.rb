# encoding: UTF-8

require './test_helper'
require 'test/unit'
require 'stringio'

class TestXml < Test::Unit::TestCase
  # -----  Constants  ------
  def test_lib_versions
    assert(XML.check_lib_versions)
  end

  def test_debug_entities
    XML.debug_entities = false
    assert(!XML.debug_entities)

    XML.debug_entities = true
    assert(XML.debug_entities)

    XML.debug_entities = false
    assert(!XML.debug_entities)
  end

  def test_default_compression
    return unless XML.default_compression

    0.upto(9) do |i|
      XML.default_compression = i
      assert_equal(i, XML.default_compression)
    end

    9.downto(0) do |i|
      assert_equal(i, XML.default_compression = i)
      assert_equal(i, XML.default_compression)
    end

    0.downto(-10) do |i|
      assert_equal(i, XML.default_compression = i)
      assert_equal(0, XML.default_compression)
    end

    10.upto(20) do |i|
      assert_equal(i, XML.default_compression = i)
      assert_equal(9, XML.default_compression)
    end
  end

  def test_default_keep_blanks
    XML.default_keep_blanks = false
    assert(!XML.default_keep_blanks)
    assert_equal(XML::Parser::Options::NOBLANKS, XML.default_options)

    XML.default_keep_blanks = true
    assert(XML.default_keep_blanks)
    assert_equal(0, XML.default_options)

    XML.default_keep_blanks = false
    assert(!XML.default_keep_blanks)

    # other tests depend on keeping blanks by default,
    # which is the default default behaviour anyway.
    XML.default_keep_blanks = true
  end

  def test_default_line_numbers
    XML.default_line_numbers = false
    assert(!XML.default_line_numbers)

    XML.default_line_numbers = true
    assert(XML.default_line_numbers)

    XML.default_line_numbers = false
    assert(!XML.default_line_numbers)
  end

  def test_default_substitute_entities
    XML.default_substitute_entities = false
    assert(!XML.default_substitute_entities)
    assert_equal(0, XML.default_options)

    XML.default_substitute_entities = true
    assert(XML.default_substitute_entities)
    assert_equal(XML::Parser::Options::NOENT, XML.default_options)

    XML.default_substitute_entities = false
    assert(!XML.default_substitute_entities)
  end

  def test_default_tree_indent_string
    s = XML.default_tree_indent_string
    assert_instance_of(String, s)
    assert_equal('  ', s)
    XML.default_tree_indent_string = 'uga'
    s = XML.default_tree_indent_string
    assert_instance_of(String, s)
    assert_equal('uga', s)
    XML.default_tree_indent_string = '  '
    s = XML.default_tree_indent_string
    assert_instance_of(String, s)
    assert_equal('  ', s)
  end

  def test_default_validity_checking
    XML.default_validity_checking = false
    assert(!XML.default_validity_checking)
    assert_equal(0, XML.default_options)

    XML.default_validity_checking = true
    assert(XML.default_validity_checking)
    assert_equal(XML::Parser::Options::DTDVALID, XML.default_options)

    XML.default_validity_checking = false
    assert(!XML.default_validity_checking)
  end

  def test_default_warnings
    XML.default_warnings = false
    assert(!XML.default_warnings)
    assert_equal(XML::Parser::Options::NOWARNING, XML.default_options)

    XML.default_warnings = true
    assert(XML.default_warnings)
    assert_equal(0, XML.default_options)

    XML.default_warnings = false
    assert(!XML.default_warnings)
  end

  def test_enabled_automata
    assert_equal(true, XML.enabled_automata?)
  end

  def test_enabled_c14n
    assert_equal(true, XML.enabled_c14n?)
  end

  def test_enabled_catalog
    assert_equal(true, XML.enabled_catalog?)
  end

  def test_enabled_debug
    assert_equal(true, XML.enabled_debug?)
  end

  def test_enabled_docbook
    assert_equal(true, XML.enabled_docbook?)
  end

  def test_enabled_ftp
    assert_equal(true, XML.enabled_ftp?)
  end

  def test_enabled_http
    assert_equal(true, XML.enabled_http?)
  end

  def test_enabled_html
    assert_equal(true, XML.enabled_html?)
  end

  def test_enabled_iconv
    assert_equal(true, XML.enabled_iconv?)
  end

  def test_enabled_memory_debug
    assert_equal(false, XML.enabled_memory_debug?)
  end

  def test_enabled_regexp
    assert_equal(true, XML.enabled_regexp?)
  end

  def test_enabled_schemas
    assert_equal(true, XML.enabled_schemas?)
  end

  def test_enabled_thread
    assert_equal(true, XML.enabled_thread?)
  end

  def test_enabled_unicode
    assert_equal(true, XML.enabled_unicode?)
  end

  def test_enabled_xinclude
    assert_equal(true, XML.enabled_xinclude?)
  end

  def test_enabled_xpath
    assert_equal(true, XML.enabled_xpath?)
  end

  def test_enabled_xpointer
    assert_equal(true, XML.enabled_xpointer?)
  end

  def test_enabled_zlib
    assert_equal(true, XML.enabled_zlib?)
  end

  def test_intent_tree_output
    assert(TrueClass, XML.indent_tree_output)

    XML.indent_tree_output = false
    assert(FalseClass, XML.indent_tree_output)

    XML.indent_tree_output = true
    assert(TrueClass, XML.indent_tree_output)
  end

  def test_version
    assert_instance_of(String, XML::VERSION)
  end

  def test_vernum
    assert_instance_of(Fixnum, XML::VERNUM)
  end

  def test_libxml_parser_features
    assert_instance_of(Array, XML.features)
  end

  def test_default_options
    assert_equal(0, XML.default_options)
  end
end