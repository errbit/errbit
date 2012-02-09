# encoding: UTF-8

require './test_helper'
require 'stringio'
require 'test/unit'

class DocTypeCallback
  include XML::SaxParser::Callbacks
  def on_start_element(element, attributes)
  end
end

class TestCaseCallbacks
  include XML::SaxParser::Callbacks

  attr_accessor :result

  def initialize
    @result = Array.new
  end

  def on_cdata_block(cdata)
    @result << "cdata: #{cdata}"
  end

  def on_characters(chars)
    @result << "characters: #{chars}"
  end

  def on_comment(text)
    @result << "comment: #{text}"
  end

  def on_end_document
    @result << "end_document"
  end

  def on_end_element(name)
    @result << "end_element: #{name}"
  end

  def on_end_element_ns(name, prefix, uri)
    @result << "end_element_ns #{name}, prefix: #{prefix}, uri: #{uri}"
  end

  # Called for parser errors.
  def on_error(error)
    @result << "error: #{error}"
  end

  def on_processing_instruction(target, data)
    @result << "pi: #{target} #{data}"
  end

  def on_start_document
    @result << "startdoc"
  end

  def on_start_element(name, attributes)
    attributes ||= Hash.new
    @result << "start_element: #{name}, attr: #{attributes.inspect}"
  end

  def on_start_element_ns(name, attributes, prefix, uri, namespaces)
    attributes ||= Hash.new
    namespaces ||= Hash.new
    @result << "start_element_ns: #{name}, attr: #{attributes.inspect}, prefix: #{prefix}, uri: #{uri}, ns: #{namespaces.inspect}"
  end
end

class TestSaxParser < Test::Unit::TestCase
  def saxtest_file
    File.join(File.dirname(__FILE__), 'model/atom.xml')
  end

  def verify(parser)
    result = parser.callbacks.result

    i = -1
    assert_equal("startdoc", result[i+=1])
    assert_equal("pi: xml-stylesheet type=\"text/xsl\" href=\"my_stylesheet.xsl\"", result[i+=1])
    assert_equal("start_element: feed, attr: {}", result[i+=1])
    assert_equal("start_element_ns: feed, attr: {}, prefix: , uri: http://www.w3.org/2005/Atom, ns: {nil=>\"http://www.w3.org/2005/Atom\"}", result[i+=1])
    assert_equal("characters: \n  ", result[i+=1])
    assert_equal("comment:  Not a valid atom entry ", result[i+=1])
    assert_equal("characters: \n  ", result[i+=1])
    assert_equal("start_element: entry, attr: {}", result[i+=1])
    assert_equal("start_element_ns: entry, attr: {}, prefix: , uri: http://www.w3.org/2005/Atom, ns: {}", result[i+=1])
    assert_equal("characters: \n    ", result[i+=1])
    assert_equal("start_element: title, attr: {\"type\"=>\"html\"}", result[i+=1])
    assert_equal("start_element_ns: title, attr: {\"type\"=>\"html\"}, prefix: , uri: http://www.w3.org/2005/Atom, ns: {}", result[i+=1])
    assert_equal("cdata: <<strong>>", result[i+=1])
    assert_equal("end_element: title", result[i+=1])
    assert_equal("end_element_ns title, prefix: , uri: http://www.w3.org/2005/Atom", result[i+=1])
    assert_equal("characters: \n    ", result[i+=1])
    assert_equal("start_element: content, attr: {\"type\"=>\"xhtml\"}", result[i+=1])
    assert_equal("start_element_ns: content, attr: {\"type\"=>\"xhtml\"}, prefix: , uri: http://www.w3.org/2005/Atom, ns: {}", result[i+=1])
    assert_equal("characters: \n      ", result[i+=1])
    assert_equal("start_element: xhtml:div, attr: {}", result[i+=1])
    assert_equal("start_element_ns: div, attr: {}, prefix: xhtml, uri: http://www.w3.org/1999/xhtml, ns: {\"xhtml\"=>\"http://www.w3.org/1999/xhtml\"}", result[i+=1])
    assert_equal("characters: \n        ", result[i+=1])
    assert_equal("start_element: xhtml:p, attr: {}", result[i+=1])
    assert_equal("start_element_ns: p, attr: {}, prefix: xhtml, uri: http://www.w3.org/1999/xhtml, ns: {}", result[i+=1])
    assert_equal("characters: hi there", result[i+=1])
    assert_equal("end_element: xhtml:p", result[i+=1])
    assert_equal("end_element_ns p, prefix: xhtml, uri: http://www.w3.org/1999/xhtml", result[i+=1])
    assert_equal("characters: \n      ", result[i+=1])
    assert_equal("end_element: xhtml:div", result[i+=1])
    assert_equal("end_element_ns div, prefix: xhtml, uri: http://www.w3.org/1999/xhtml", result[i+=1])
    assert_equal("characters: \n    ", result[i+=1])
    assert_equal("end_element: content", result[i+=1])
    assert_equal("end_element_ns content, prefix: , uri: http://www.w3.org/2005/Atom", result[i+=1])
    assert_equal("characters: \n  ", result[i+=1])
    assert_equal("end_element: entry", result[i+=1])
    assert_equal("end_element_ns entry, prefix: , uri: http://www.w3.org/2005/Atom", result[i+=1])
    assert_equal("characters: \n", result[i+=1])
    assert_equal("end_element: feed", result[i+=1])
    assert_equal("end_element_ns feed, prefix: , uri: http://www.w3.org/2005/Atom", result[i+=1])
    assert_equal("end_document", result[i+=1])
  end

  def test_file
    parser = XML::SaxParser.file(saxtest_file)
    parser.callbacks = TestCaseCallbacks.new
    parser.parse
    verify(parser)
  end

  def test_file_no_callbacks
    parser = XML::SaxParser.file(saxtest_file)
    assert_equal true, parser.parse
  end

  def test_noexistent_file
    error = assert_raise(XML::Error) do
      XML::SaxParser.file('i_dont_exist.xml')
    end

    assert_equal('Warning: failed to load external entity "i_dont_exist.xml".', error.to_s)
  end

  def test_nil_file
    error = assert_raise(TypeError) do
      XML::SaxParser.file(nil)
    end

    assert_equal("can't convert nil into String", error.to_s)
  end

  def test_io
    File.open(saxtest_file) do |file|
      parser = XML::SaxParser.io(file)
      parser.callbacks = TestCaseCallbacks.new
      parser.parse
      verify(parser)
    end
  end

  def test_nil_io
    error = assert_raise(TypeError) do
      XML::HTMLParser.io(nil)
    end

    assert_equal("Must pass in an IO object", error.to_s)
  end

  def test_string_no_callbacks
    xml = File.read(saxtest_file)
    parser = XML::SaxParser.string(xml)
    assert_equal true, parser.parse
  end

  def test_string
    xml = File.read(saxtest_file)
    parser = XML::SaxParser.string(xml)
    parser.callbacks = TestCaseCallbacks.new
    parser.parse
    verify(parser)
  end

  def test_string_io
    xml = File.read(saxtest_file)
    io = StringIO.new(xml)
    parser = XML::SaxParser.io(io)
    
    parser.callbacks = TestCaseCallbacks.new
    parser.parse
    verify(parser)
  end

  def test_nil_string
    error = assert_raise(TypeError) do
      XML::SaxParser.string(nil)
    end

    assert_equal("wrong argument type nil (expected String)", error.to_s)
  end

  def test_doctype
    xml = <<-EOS
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE Results SYSTEM "results.dtd">
<Results>
<a>a1</a>
</Results>
EOS
    parser = XML::SaxParser.string(xml)
    parser.callbacks = DocTypeCallback.new
    doc = parser.parse
    assert_not_nil(doc)
  end

  def test_parse_warning
    # Two xml PIs is a warning
    xml = <<-EOS
<?xml version="1.0" encoding="utf-8"?>
<?xml-invalid?>
<Test/>
EOS

    parser = XML::SaxParser.string(xml)
    parser.callbacks = TestCaseCallbacks.new

    parser.parse

    # Check callbacks
    result = parser.callbacks.result
    i = -1
    assert_equal("startdoc", result[i+=1])
    assert_equal("error: Warning: xmlParsePITarget: invalid name prefix 'xml' at :2.", result[i+=1])
    assert_equal("pi: xml-invalid ", result[i+=1])
    assert_equal("start_element: Test, attr: {}", result[i+=1])
    assert_equal("start_element_ns: Test, attr: {}, prefix: , uri: , ns: {}", result[i+=1])
    assert_equal("end_element: Test", result[i+=1])
    assert_equal("end_element_ns Test, prefix: , uri: ", result[i+=1])
    assert_equal("end_document", result[i+=1])
  end

  def test_parse_error
    xml = <<-EOS
      <Results>
    EOS
    parser = XML::SaxParser.string(xml)
    parser.callbacks = TestCaseCallbacks.new

    error = assert_raise(XML::Error) do
      doc = parser.parse
    end

    # Check callbacks
    result = parser.callbacks.result

    i = -1
    assert_equal("startdoc", result[i+=1])
    assert_equal("start_element: Results, attr: {}", result[i+=1])
    assert_equal("start_element_ns: Results, attr: {}, prefix: , uri: , ns: {}", result[i+=1])
    assert_equal("characters: \n", result[i+=1])
    assert_equal("error: Fatal error: Premature end of data in tag Results line 1 at :2.", result[i+=1])
    assert_equal("end_document", result[i+=1])

    assert_not_nil(error)
    assert_kind_of(XML::Error, error)
    assert_equal("Fatal error: Premature end of data in tag Results line 1 at :2.", error.message)
    assert_equal(XML::Error::PARSER, error.domain)
    assert_equal(XML::Error::TAG_NOT_FINISHED, error.code)
    assert_equal(XML::Error::FATAL, error.level)
    assert_nil(error.file)
    assert_equal(2, error.line)
    assert_equal('Results', error.str1)
    assert_nil(error.str2)
    assert_nil(error.str3)
    assert_equal(1, error.int1)
    assert_equal(1, error.int2)
    assert_nil(error.node)
  end

  def test_parse_seg_fail
    xml = <<-EOS
      <?xml version="1.0" encoding="ISO-8859-1" ?>
      <Products>
        <Product>
          <ProductDescription>
            AQUALIA THERMAL Lichte cr├иme - Versterkende & kalmerende 24 u hydraterende verzorging<br />
            Huid wordt continu gehydrateerd, intens versterkt en gekalmeerd.<br />
            Hypoallergeen. Geschikt voor de gevoelige huid.<br />
            <br />
            01.EFFECTIVITEIT<br />
            Intensief gehydrateerd, de huid voelt gekalmeerd. Ze voelt de hele dag soepel en fluweelzacht aan, zonder een trekkerig gevoel. De huid is elastischer, soepeler en stralender. Doeltreffendheid getest onder dermatologisch toezicht. <br />
            <br />
            02.GEBRUIK<br />
            's Morgens en/ of 's avonds aanbrengen. <br />
            <br />
            03.ACTIEVE INGREDIENTEN<br />
            Technologische innovatie: 24 u continue cellulaire vochtnevel. Voor de 1ste keer worden Thermaal Bronwater van Vichy, rijk aan zeldzame mineralen en Actief HyaluronineтДв verwerkt in microcapsules, die deze vervolgens verspreiden in de cellen. <br />
            <br />
            04.TEXTUUR<br />
            De lichte cr├иme is verfrissend en trekt makkelijk in. Niet vet en niet kleverig. Zonder 'maskereffect'. <br />
            <br />
            05.GEUR<br />
            Geparfumeerd <br />
            <br />
            06.INHOUD<br />
            40 ml tube <br />
          </ProductDescription>
        </Product>
      </Products>
    EOS

    parser = XML::SaxParser.string(xml)
    parser.callbacks = TestCaseCallbacks.new

    error = assert_raise(XML::Error) do
      parser.parse
    end
    assert_equal("Fatal error: xmlParseEntityRef: no name at :5.", error.to_s)

    # Check callbacks
    result = parser.callbacks.result
  end
end