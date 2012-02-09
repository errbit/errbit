# encoding: UTF-8

require './test_helper'

require 'test/unit'

class TestDtd < Test::Unit::TestCase
  def setup
    xp = XML::Parser.string(<<-EOS)
      <root>
        <head a="ee" id="1">Colorado</head>
        <descr>Lots of nice mountains</descr>
      </root>
    EOS
    @doc = xp.parse
  end

  def teardown
    @doc = nil
  end
  
  def dtd
    XML::Dtd.new(<<-EOS)
      <!ELEMENT root (head, descr)>
      <!ELEMENT head (#PCDATA)>
      <!ATTLIST head
        id NMTOKEN #REQUIRED
        a CDATA #IMPLIED
      >
      <!ELEMENT descr (#PCDATA)>
    EOS
  end
  
  def test_internal_subset
    xhtml_dtd = XML::Dtd.new "-//W3C//DTD XHTML 1.0 Transitional//EN", "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd", nil, nil, true
		assert xhtml_dtd.name.nil?
		assert_equal "-//W3C//DTD XHTML 1.0 Transitional//EN", xhtml_dtd.external_id
		assert_equal "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd", xhtml_dtd.uri
		assert_equal "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd", xhtml_dtd.system_id

    xhtml_dtd = XML::Dtd.new "-//W3C//DTD XHTML 1.0 Transitional//EN", "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd", "xhtml1", nil, true
		assert_equal "xhtml1", xhtml_dtd.name
		assert_equal "-//W3C//DTD XHTML 1.0 Transitional//EN", xhtml_dtd.external_id
		assert_equal "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd", xhtml_dtd.uri
		assert_equal "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd", xhtml_dtd.system_id
	end

  def test_external_subset
    xhtml_dtd = XML::Dtd.new "-//W3C//DTD XHTML 1.0 Transitional//EN", "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd", nil
		assert xhtml_dtd.name.nil?
		assert_equal "-//W3C//DTD XHTML 1.0 Transitional//EN", xhtml_dtd.external_id
		assert_equal "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd", xhtml_dtd.uri
		assert_equal "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd", xhtml_dtd.system_id

    xhtml_dtd = XML::Dtd.new "-//W3C//DTD XHTML 1.0 Transitional//EN", "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd", "xhtml1"
		assert_equal "xhtml1", xhtml_dtd.name
		assert_equal "-//W3C//DTD XHTML 1.0 Transitional//EN", xhtml_dtd.external_id
		assert_equal "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd", xhtml_dtd.uri
		assert_equal "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd", xhtml_dtd.system_id
	end

  def test_valid
    assert(@doc.validate(dtd))
  end

  def test_invalid
    new_node = XML::Node.new('invalid', 'this will mess up validation')
    @doc.root << new_node

    error = assert_raise(XML::Error) do
      @doc.validate(dtd)
    end

    # Check the error worked
    assert_not_nil(error)
    assert_kind_of(XML::Error, error)
    assert_equal("Error: No declaration for element invalid.", error.message)
    assert_equal(XML::Error::VALID, error.domain)
    assert_equal(XML::Error::DTD_UNKNOWN_ELEM, error.code)
    assert_equal(XML::Error::ERROR, error.level)
    assert_nil(error.file)
    assert_nil(error.line)
    assert_equal('invalid', error.str1)
    assert_equal('invalid', error.str2)
    assert_nil(error.str3)
    assert_equal(0, error.int1)
    assert_equal(0, error.int2)
    assert_not_nil(error.node)
    assert_equal('invalid', error.node.name)
  end

  def test_external_dtd
    xml = <<-EOS
      <!DOCTYPE test PUBLIC "-//TEST" "test.dtd" []>
      <test>
        <title>T1</title>
      </test>
    EOS

    errors = Array.new
    XML::Error.set_handler do |error|
      errors << error
    end

    XML.default_load_external_dtd = false
    doc = XML::Parser.string(xml).parse
    assert_equal(0, errors.length)

    errors.clear
    XML.default_load_external_dtd = true
    doc = XML::Parser.string(xml).parse
    assert_equal(1, errors.length)
    assert_equal("Warning: failed to load external entity \"test.dtd\" at :1.",
                 errors[0].to_s)

    errors = Array.new
    doc = XML::Parser.string(xml, :options => XML::Parser::Options::DTDLOAD).parse
    assert_equal(1, errors.length)
    assert_equal("Warning: failed to load external entity \"test.dtd\" at :1.",
                 errors[0].to_s)
  ensure
    XML.default_load_external_dtd = false
    XML::Error.reset_handler
  end
end
