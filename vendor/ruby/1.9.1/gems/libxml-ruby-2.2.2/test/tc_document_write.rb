# encoding: UTF-8

require './test_helper'
require 'tmpdir'
require 'test/unit'

class TestDocumentWrite < Test::Unit::TestCase
  def setup
    @file_name = "model/bands.utf-8.xml"

    # Strip spaces to make testing easier
    XML.default_keep_blanks = false
    file = File.join(File.dirname(__FILE__), @file_name)
    @doc = XML::Document.file(file)
  end

  def teardown
    XML.default_keep_blanks = true
    @doc = nil
  end

  # ---  to_s tests  ---
  def test_to_s_default
    # Default to_s has indentation
    if defined?(Encoding)
      assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<bands genre=\"metal\">\n  <m\u00F6tley_cr\u00FCe country=\"us\">M\u00F6tley Cr\u00FCe is an American heavy metal band formed in Los Angeles, California in 1981.</m\u00F6tley_cr\u00FCe>\n  <iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden>\n</bands>\n",
                   @doc.to_s)
    else
      assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<bands genre=\"metal\">\n  <m\303\266tley_cr\303\274e country=\"us\">M\303\266tley Cr\303\274e is an American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e>\n  <iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden>\n</bands>\n",
                   @doc.to_s)
    end
  end

  def test_to_s_no_global_indentation
    # No indentation due to global setting
    XML.indent_tree_output = false
    value = @doc.to_s

    if defined?(Encoding)
      assert_equal(Encoding::UTF_8, value.encoding)
      assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<bands genre=\"metal\">\n<m\u00F6tley_cr\u00FCe country=\"us\">M\u00F6tley Cr\u00FCe is an American heavy metal band formed in Los Angeles, California in 1981.</m\u00F6tley_cr\u00FCe>\n<iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden>\n</bands>\n",
                   value)
    else
      assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<bands genre=\"metal\">\n<m\303\266tley_cr\303\274e country=\"us\">M\303\266tley Cr\303\274e is an American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e>\n<iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden>\n</bands>\n",
                   value)
    end
  ensure
    XML.indent_tree_output = true
  end

  def test_to_s_no_indentation
    # No indentation due to local setting
    value = @doc.to_s(:indent => false)
    if defined?(Encoding)
      assert_equal(Encoding::UTF_8, value.encoding)
      assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<bands genre=\"metal\"><m\u00F6tley_cr\u00FCe country=\"us\">M\u00F6tley Cr\u00FCe is an American heavy metal band formed in Los Angeles, California in 1981.</m\u00F6tley_cr\u00FCe><iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden></bands>\n",
                   value)
    else
      assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<bands genre=\"metal\"><m\303\266tley_cr\303\274e country=\"us\">M\303\266tley Cr\303\274e is an American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e><iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden></bands>\n",
                   value)
    end
  end

  def test_to_s_encoding
    # Test encodings

    # UTF8:
    # ö - c3 b6 in hex, \303\266 in octal
    # ü - c3 bc in hex, \303\274 in octal
    value = @doc.to_s(:encoding => XML::Encoding::UTF_8)
    if defined?(Encoding)
      assert_equal(Encoding::UTF_8, value.encoding)
      assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<bands genre=\"metal\">\n  <m\u00F6tley_cr\u00FCe country=\"us\">M\u00F6tley Cr\u00FCe is an American heavy metal band formed in Los Angeles, California in 1981.</m\u00F6tley_cr\u00FCe>\n  <iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden>\n</bands>\n",
                   value)
    else
      assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<bands genre=\"metal\">\n  <m\303\266tley_cr\303\274e country=\"us\">M\303\266tley Cr\303\274e is an American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e>\n  <iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden>\n</bands>\n",
                   value)
    end

    # ISO_8859_1:
    # ö - f6 in hex, \366 in octal
    # ü - fc in hex, \374 in octal
    value = @doc.to_s(:encoding => XML::Encoding::ISO_8859_1)
    if defined?(Encoding)
      assert_equal(Encoding::ISO8859_1, value.encoding)
      assert_equal("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<bands genre=\"metal\">\n  <m\xF6tley_cr\xFCe country=\"us\">M\xF6tley Cr\xFCe is an American heavy metal band formed in Los Angeles, California in 1981.</m\xF6tley_cr\xFCe>\n  <iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden>\n</bands>\n".force_encoding(Encoding::ISO8859_1),
                   @doc.to_s(:encoding => XML::Encoding::ISO_8859_1))
    else
      assert_equal("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<bands genre=\"metal\">\n  <m\366tley_cr\374e country=\"us\">M\366tley Cr\374e is an American heavy metal band formed in Los Angeles, California in 1981.</m\366tley_cr\374e>\n  <iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden>\n</bands>\n",
                   @doc.to_s(:encoding => XML::Encoding::ISO_8859_1))
    end

    # Invalid encoding
    error = assert_raise(ArgumentError) do
      @doc.to_s(:encoding => -9999)
    end
    assert_equal('Unknown encoding value: -9999', error.to_s)
  end

  # --- save tests -----
  def test_save_utf8
    temp_filename = File.join(Dir.tmpdir, "tc_document_write_test_save_utf8.xml")

    bytes = @doc.save(temp_filename)
    assert_equal(305, bytes)

    if defined?(Encoding)
      contents = File.read(temp_filename, nil, nil, :encoding => Encoding::UTF_8)
      assert_equal(Encoding::UTF_8, contents.encoding)
      assert_equal("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<bands genre=\"metal\">\n  <m\u00F6tley_cr\u00FCe country=\"us\">M\u00F6tley Cr\u00FCe is an American heavy metal band formed in Los Angeles, California in 1981.</m\u00F6tley_cr\u00FCe>\n  <iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden>\n</bands>\n",
                    contents)
    else
      contents = File.read(temp_filename)
      assert_equal("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<bands genre=\"metal\">\n  <m\303\266tley_cr\303\274e country=\"us\">M\303\266tley Cr\303\274e is an American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e>\n  <iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden>\n</bands>\n",
                 contents)
    end
  ensure
    File.delete(temp_filename)
  end

  def test_save_utf8_no_indents
    temp_filename = File.join(Dir.tmpdir, "tc_document_write_test_save_utf8_no_indents.xml")

    bytes = @doc.save(temp_filename, :indent => false)
    assert_equal(298, bytes)

    if defined?(Encoding)
      contents = File.read(temp_filename, nil, nil, :encoding => Encoding::UTF_8)
      assert_equal("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<bands genre=\"metal\"><m\u00F6tley_cr\u00FCe country=\"us\">M\u00F6tley Cr\u00FCe is an American heavy metal band formed in Los Angeles, California in 1981.</m\u00F6tley_cr\u00FCe><iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden></bands>\n",
                 contents)
    else
      contents = File.read(temp_filename)
      assert_equal("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<bands genre=\"metal\"><m\303\266tley_cr\303\274e country=\"us\">M\303\266tley Cr\303\274e is an American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e><iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden></bands>\n",
                 contents)
    end
  ensure
    File.delete(temp_filename)
  end

  def test_save_iso_8859_1
    temp_filename = File.join(Dir.tmpdir, "tc_document_write_test_save_iso_8859_1.xml")
    bytes = @doc.save(temp_filename, :encoding => XML::Encoding::ISO_8859_1)
    assert_equal(304, bytes)

    if defined?(Encoding)
      contents = File.read(temp_filename, nil, nil, :encoding => Encoding::ISO8859_1)
      assert_equal(Encoding::ISO8859_1, contents.encoding)
      assert_equal("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<bands genre=\"metal\">\n  <m\xF6tley_cr\xFCe country=\"us\">M\xF6tley Cr\xFCe is an American heavy metal band formed in Los Angeles, California in 1981.</m\xF6tley_cr\xFCe>\n  <iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden>\n</bands>\n".force_encoding(Encoding::ISO8859_1),
                 contents)
    else
      contents = File.read(temp_filename)
      assert_equal("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<bands genre=\"metal\">\n  <m\xF6tley_cr\xFCe country=\"us\">M\xF6tley Cr\xFCe is an American heavy metal band formed in Los Angeles, California in 1981.</m\xF6tley_cr\xFCe>\n  <iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden>\n</bands>\n",
                 contents)
    end
  ensure
    File.delete(temp_filename)
  end

  def test_save_iso_8859_1_no_indent
    temp_filename = File.join(Dir.tmpdir, "tc_document_write_test_save_iso_8859_1_no_indent.xml")
    bytes = @doc.save(temp_filename, :indent => false, :encoding => XML::Encoding::ISO_8859_1)
    assert_equal(297, bytes)

    if defined?(Encoding)
      contents = File.read(temp_filename, nil, nil, :encoding => Encoding::ISO8859_1)
      assert_equal(Encoding::ISO8859_1, contents.encoding)
      assert_equal("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<bands genre=\"metal\"><m\xF6tley_cr\xFCe country=\"us\">M\xF6tley Cr\xFCe is an American heavy metal band formed in Los Angeles, California in 1981.</m\xF6tley_cr\xFCe><iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden></bands>\n".force_encoding(Encoding::ISO8859_1),
                   contents)
    else
      contents = File.read(temp_filename)
      assert_equal("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<bands genre=\"metal\"><m\xF6tley_cr\xFCe country=\"us\">M\xF6tley Cr\xFCe is an American heavy metal band formed in Los Angeles, California in 1981.</m\xF6tley_cr\xFCe><iron_maiden country=\"uk\">Iron Maiden is a British heavy metal band formed in 1975.</iron_maiden></bands>\n",
                   contents)
    end
  ensure
    File.delete(temp_filename)
  end

  def test_thread_set_root
    # Previously a segmentation fault occurred when running libxml in
    # background threads.
    thread = Thread.new do
      100000.times do |i|
        document = LibXML::XML::Document.new
        node = LibXML::XML::Node.new('test')
        document.root = node
      end
    end
    thread.join
    assert(true)
  end

  # --- Debug ---
  def test_debug
    assert(@doc.debug)
  end
end