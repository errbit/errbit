# encoding: UTF-8

if defined?(Encoding)
require './test_helper'
require 'test/unit'

# Code  UTF8        Latin1      Hex
# m      109          109        6D
# ö      195 182      246        C3 B6 / F6
# t      116          116        74
# l      108          108        6C
# e      101          101        65
# y      121          121        79
# _       95           95        5F
# c       99           99        63
# r      114          114        72
# ü      195 188      252        C3 BC / FC
# e      101          101        65

# See:
#  http://en.wikipedia.org/wiki/ISO/IEC_8859-1
#  http://en.wikipedia.org/wiki/List_of_Unicode_characters

class TestEncoding < Test::Unit::TestCase
  def setup
    Encoding.default_internal = nil
  end

  def load_encoding(encoding)
    @encoding = encoding
    file_name = "model/bands.#{@encoding.name.downcase}.xml"

    # Strip spaces to make testing easier
    XML.default_keep_blanks = false
    file = File.join(File.dirname(__FILE__), file_name)
    @doc = XML::Document.file(file)
  end
  
  def test_encoding
    doc = XML::Document.new
    assert_equal(XML::Encoding::NONE, doc.encoding)
    assert_equal(Encoding::ASCII_8BIT, doc.rb_encoding) if defined?(Encoding)

    file = File.expand_path(File.join(File.dirname(__FILE__), 'model/bands.xml'))
    doc = XML::Document.file(file)
    assert_equal(XML::Encoding::UTF_8, doc.encoding)
    assert_equal(Encoding::UTF_8, doc.rb_encoding) if defined?(Encoding)

    doc.encoding = XML::Encoding::ISO_8859_1
    assert_equal(XML::Encoding::ISO_8859_1, doc.encoding)
    assert_equal(Encoding::ISO8859_1, doc.rb_encoding) if defined?(Encoding)
  end

  def test_no_internal_encoding_iso_8859_1
    Encoding.default_internal = nil
    load_encoding(Encoding::ISO_8859_1)
    node = @doc.root.children.first

    name = node.name
    assert_equal(Encoding::UTF_8, name.encoding)
    assert_equal("m\u00F6tley_cr\u00FCe", name)
    assert_equal("109 195 182 116 108 101 121 95 99 114 195 188 101",
                 name.bytes.to_a.join(" "))
    assert_equal("M\u00F6tley Cr\u00FCe is an American heavy metal band formed in Los Angeles, California in 1981.",
                 node.content)

    name = name.encode(Encoding::ISO_8859_1)
    assert_equal(Encoding::ISO_8859_1, name.encoding)
    assert_equal("m\xF6tley_cr\xFCe".force_encoding(Encoding::ISO_8859_1), name)
    assert_equal("109 246 116 108 101 121 95 99 114 252 101",
                 name.bytes.to_a.join(" "))
    assert_equal("M\xF6tley Cr\xFCe is an American heavy metal band formed in Los Angeles, California in 1981.".force_encoding(Encoding::ISO_8859_1),
                node.content.encode(Encoding::ISO_8859_1))
  end

  def test_internal_encoding_iso_8859_1
    Encoding.default_internal = Encoding::ISO_8859_1
    load_encoding(Encoding::ISO_8859_1)
    node = @doc.root.children.first

    name = node.name
    assert_equal(Encoding::ISO_8859_1, name.encoding)
    assert_equal("109 246 116 108 101 121 95 99 114 252 101",
                 name.bytes.to_a.join(" "))
    assert_equal("m\xF6tley_cr\xFCe".force_encoding(Encoding::ISO_8859_1), name)
    assert_equal("109 246 116 108 101 121 95 99 114 252 101",
                 name.bytes.to_a.join(" "))
    assert_equal("M\xF6tley Cr\xFCe is an American heavy metal band formed in Los Angeles, California in 1981.".force_encoding(Encoding::ISO_8859_1),
                node.content.encode(Encoding::ISO_8859_1))
  end

  def test_no_internal_encoding_utf_8
    Encoding.default_internal = nil
    load_encoding(Encoding::UTF_8)
    node = @doc.root.children.first

    name = node.name
    assert_equal(@encoding, name.encoding)
    assert_equal("109 195 182 116 108 101 121 95 99 114 195 188 101",
                 name.bytes.to_a.join(" "))

    name = name.encode(Encoding::ISO_8859_1)
    assert_equal(Encoding::ISO_8859_1, name.encoding)
    assert_equal("109 246 116 108 101 121 95 99 114 252 101",
                 name.bytes.to_a.join(" "))
  end

  def test_internal_encoding_utf_8
    Encoding.default_internal = Encoding::ISO_8859_1
    load_encoding(Encoding::UTF_8)
    node = @doc.root.children.first

    name = node.name
    assert_equal(Encoding::ISO_8859_1, name.encoding)
    assert_equal("109 246 116 108 101 121 95 99 114 252 101",
                 name.bytes.to_a.join(" "))
  end
end
end