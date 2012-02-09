# encoding: UTF-8

require './test_helper'
require 'test/unit'

class TestNodeWrite < Test::Unit::TestCase
  def setup
    load_encoding("utf-8")
  end
  
  def teardown
    XML.default_keep_blanks = true
    @doc = nil
  end
  
  def load_encoding(name)
    @encoding = Encoding.find(name) if defined?(Encoding)
    @file_name = "model/bands.#{name.downcase}.xml"

    # Strip spaces to make testing easier
    XML.default_keep_blanks = false
    file = File.join(File.dirname(__FILE__), @file_name)
    @doc = XML::Document.file(file)
  end

  def test_to_s_default
    # Default to_s has indentation
    node = @doc.root
    assert_equal(Encoding::UTF_8, node.to_s.encoding) if defined?(Encoding)
    assert_equal("<bands genre=\"metal\">\n  <m\303\266tley_cr\303\274e country=\"us\">M\303\266tley Cr\303\274e is an American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e>\n  <iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden>\n</bands>",
                 node.to_s)
  end

  def test_to_s_no_global_indentation
    # No indentation due to global setting
    node = @doc.root
    XML.indent_tree_output = false
    assert_equal("<bands genre=\"metal\">\n<m\303\266tley_cr\303\274e country=\"us\">M\303\266tley Cr\303\274e is an American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e>\n<iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden>\n</bands>",
                 node.to_s)
  ensure
    XML.indent_tree_output = true
  end

  def test_to_s_no_indentation
    # No indentation due to local setting
    node = @doc.root
    assert_equal("<bands genre=\"metal\"><m\303\266tley_cr\303\274e country=\"us\">M\303\266tley Cr\303\274e is an American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e><iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden></bands>",
                 node.to_s(:indent => false))
  end

  def test_to_s_level
    # No indentation due to local setting
    node = @doc.root
    assert_equal("<bands genre=\"metal\">\n    <m\303\266tley_cr\303\274e country=\"us\">M\303\266tley Cr\303\274e is an American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e>\n    <iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden>\n  </bands>",
                 node.to_s(:level => 1))
  end

  def test_to_s_encoding
    # Test encodings
    node = @doc.root

    # UTF8:
    # ö - c3 b6 in hex, \303\266 in octal
    # ü - c3 bc in hex, \303\274 in octal
    value = node.to_s(:encoding => XML::Encoding::UTF_8)
    assert_equal(Encoding::UTF_8, node.to_s.encoding) if defined?(Encoding)
    assert_equal("<bands genre=\"metal\">\n  <m\303\266tley_cr\303\274e country=\"us\">M\303\266tley Cr\303\274e is an American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e>\n  <iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden>\n</bands>",
                 value)

    # ISO_8859_1:
    # ö - f6 in hex, \366 in octal
    # ü - fc in hex, \374 in octal
    value = node.to_s(:encoding => XML::Encoding::ISO_8859_1)
    if defined?(Encoding)
      assert_equal(Encoding::ISO8859_1, value.encoding)
      assert_equal("<bands genre=\"metal\">\n  <m\xF6tley_cr\xFCe country=\"us\">M\xF6tley Cr\xFCe is an American heavy metal band formed in Los Angeles, California in 1981.</m\xF6tley_cr\xFCe>\n  <iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden>\n</bands>".force_encoding(Encoding::ISO8859_1),
                   value)
    else
      assert_equal("<bands genre=\"metal\">\n  <m\xF6tley_cr\xFCe country=\"us\">M\xF6tley Cr\xFCe is an American heavy metal band formed in Los Angeles, California in 1981.</m\xF6tley_cr\xFCe>\n  <iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden>\n</bands>",
                 value)
    end

    # Invalid encoding
    error = assert_raise(ArgumentError) do
      node.to_s(:encoding => -9999)
    end
    assert_equal('Unknown encoding value: -9999', error.to_s)
  end

  def test_inner_xml
    # Default to_s has indentation
    node = @doc.root

    if defined?(Encoding)
      assert_equal(Encoding::UTF_8, node.inner_xml.encoding)
      assert_equal("<m\u00F6tley_cr\u00FCe country=\"us\">M\u00F6tley Cr\u00FCe is an American heavy metal band formed in Los Angeles, California in 1981.</m\u00F6tley_cr\u00FCe><iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden>",
                   node.inner_xml)
    else
      assert_equal("<m\303\266tley_cr\303\274e country=\"us\">M\303\266tley Cr\303\274e is an American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e><iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden>",
                   node.inner_xml)
    end
  end

  # --- Debug ---
  def test_debug
    assert(@doc.root.debug)
  end
end