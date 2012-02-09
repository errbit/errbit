# encoding: UTF-8

require './test_helper'
require 'test/unit'

class AttrNodeTest < Test::Unit::TestCase
  def setup
    xp = XML::Parser.string(<<-EOS)
    <CityModel
      xmlns="http://www.opengis.net/examples"
      xmlns:city="http://www.opengis.net/examples"
      xmlns:gml="http://www.opengis.net/gml"
      xmlns:xlink="http://www.w3.org/1999/xlink"
      xmlns:xsi="http://www.w3.org/2000/10/XMLSchema-instance"
      xsi:schemaLocation="http://www.opengis.net/examples city.xsd">
      <type>City</type>
      <cityMember name="Cambridge" 
                  xlink:type="simple"
                  xlink:title="Trinity Lane"
                  xlink:href="http://www.foo.net/cgi-bin/wfs?FeatureID=C10239"
                  gml:remoteSchema="city.xsd#xpointer(//complexType[@name='RoadType'])"/>
    </CityModel>
    EOS
    
    @doc = xp.parse
  end
  
  def teardown
    @doc = nil
    GC.start
  end
  
  def city_member
    @doc.find('/city:CityModel/city:cityMember').first
  end

  def test_doc
    assert_not_nil(@doc)
    assert_equal(XML::Encoding::NONE, @doc.encoding)
  end

  def test_types
    attribute = city_member.attributes.get_attribute('name')
    assert_instance_of(XML::Attr, attribute)
    assert_equal('attribute', attribute.node_type_name)
  end

  def test_name
    attribute = city_member.attributes.get_attribute('name')
    assert_equal('name', attribute.name)
    assert_equal(Encoding::UTF_8, attribute.name.encoding) if defined?(Encoding)

    attribute = city_member.attributes.get_attribute('href')
    assert_equal('href', attribute.name)
    assert_equal('xlink', attribute.ns.prefix)
    assert_equal('http://www.w3.org/1999/xlink', attribute.ns.href)

    attribute = city_member.attributes.get_attribute_ns('http://www.w3.org/1999/xlink', 'href')
    assert_equal('href', attribute.name)
    assert_equal('xlink', attribute.ns.prefix)
    assert_equal('http://www.w3.org/1999/xlink', attribute.ns.href)
  end

  def test_value
    attribute = city_member.attributes.get_attribute('name')
    assert_equal('Cambridge', attribute.value)
    assert_equal(Encoding::UTF_8, attribute.value.encoding) if defined?(Encoding)

    attribute = city_member.attributes.get_attribute('href')
    assert_equal('http://www.foo.net/cgi-bin/wfs?FeatureID=C10239', attribute.value)
  end

  def test_set_value
    attribute = city_member.attributes.get_attribute('name')
    attribute.value = 'London'
    assert_equal('London', attribute.value)
    assert_equal(Encoding::UTF_8, attribute.value.encoding) if defined?(Encoding)

    attribute = city_member.attributes.get_attribute('href')
    attribute.value = 'http://i.have.changed'
    assert_equal('http://i.have.changed', attribute.value)
    assert_equal(Encoding::UTF_8, attribute.value.encoding) if defined?(Encoding)
  end

  def test_set_nil
    attribute = city_member.attributes.get_attribute('name')
    assert_raise(TypeError) do
      attribute.value = nil
    end
  end

  def test_create
    attributes = city_member.attributes
    assert_equal(5, attributes.length)

    attr = XML::Attr.new(city_member, 'size', '50,000')
    assert_instance_of(XML::Attr, attr)

    attributes = city_member.attributes
    assert_equal(6, attributes.length)

    assert_equal(attributes['size'], '50,000')
  end

  def test_create_on_node
    attributes = city_member.attributes
    assert_equal(5, attributes.length)

    attributes['country'] = 'England'

    attributes = city_member.attributes
    assert_equal(6, attributes.length)

    assert_equal(attributes['country'], 'England')
  end

  def test_create_ns
    assert_equal(5, city_member.attributes.length)

    ns = XML::Namespace.new(city_member, 'my_namepace', 'http://www.mynamespace.com')
    attr = XML::Attr.new(city_member, 'rating', 'rocks', ns)
    assert_instance_of(XML::Attr, attr)
    assert_equal('rating', attr.name)
    assert_equal('rocks', attr.value)

    attributes = city_member.attributes
    assert_equal(6, attributes.length)

    assert_equal('rocks', city_member['rating'])
  end

  def test_remove
    attributes = city_member.attributes
    assert_equal(5, attributes.length)

    attribute = attributes.get_attribute('name')
    assert_not_nil(attribute.parent)
    assert(attribute.parent?)

    attribute.remove!
    assert_equal(4, attributes.length)

    attribute = attributes.get_attribute('name')
    assert_nil(attribute)
  end

  def test_first
    attribute = city_member.attributes.first
    assert_instance_of(XML::Attr, attribute)
    assert_equal('name', attribute.name)
    assert_equal('Cambridge', attribute.value)

    attribute = attribute.next
    assert_instance_of(XML::Attr, attribute)
    assert_equal('type', attribute.name)
    assert_equal('simple', attribute.value)

    attribute = attribute.next
    assert_instance_of(XML::Attr, attribute)
    assert_equal('title', attribute.name)
    assert_equal('Trinity Lane', attribute.value)

    attribute = attribute.next
    assert_instance_of(XML::Attr, attribute)
    assert_equal('href', attribute.name)
    assert_equal('http://www.foo.net/cgi-bin/wfs?FeatureID=C10239', attribute.value)

    attribute = attribute.next
    assert_instance_of(XML::Attr, attribute)
    assert_equal('remoteSchema', attribute.name)
    assert_equal("city.xsd#xpointer(//complexType[@name='RoadType'])", attribute.value)

    attribute = attribute.next
    assert_nil(attribute)
  end

  def test_no_attributes
    element = @doc.find('/city:CityModel/city:type').first

    assert_not_nil(element.attributes)
    assert_equal(0, element.attributes.length)
  end
end