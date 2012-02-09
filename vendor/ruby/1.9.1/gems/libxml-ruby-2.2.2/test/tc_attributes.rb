# encoding: UTF-8

require './test_helper'
require 'test/unit'

class AttributesTest < Test::Unit::TestCase
  def setup
    xp = XML::Parser.string(<<-EOS)
    <CityModel name="value"
      xmlns="http://www.opengis.net/examples"
      xmlns:city="http://www.opengis.net/examples"
      xmlns:gml="http://www.opengis.net/gml"
      xmlns:xlink="http://www.w3.org/1999/xlink"
      xmlns:xsi="http://www.w3.org/2000/10/XMLSchema-instance"
      xsi:schemaLocation="http://www.opengis.net/examples city.xsd">
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
  end
  
  def city_member
    @doc.find('/city:CityModel/city:cityMember').first
  end

  def test_attributes
    attributes = city_member.attributes
    assert_instance_of(XML::Attributes, attributes)
    assert_equal(5, attributes.length)
  end

  def test_each
    attributes = city_member.attributes
    length = attributes.inject(0) do |result, attr|
      assert_instance_of(XML::Attr, attr)
      result + 1
    end
    assert_equal(5, length)
  end

  def test_get_attribute
    attributes = city_member.attributes

    attr = attributes.get_attribute('name')
    assert_instance_of(XML::Attr, attr)

    attr = attributes.get_attribute('does_not_exist')
    assert_nil(attr)

    attr = attributes.get_attribute('name')
    assert_instance_of(XML::Attr, attr)

    attr = attributes.get_attribute('href')
    assert_instance_of(XML::Attr, attr)
    assert_instance_of(XML::Namespace, attr.ns)
    assert_equal('xlink', attr.ns.prefix)
    assert_equal('http://www.w3.org/1999/xlink', attr.ns.href)

    attr = attributes.get_attribute_ns('http://www.w3.org/1999/xlink', 'href')
    assert_instance_of(XML::Attr, attr)

    attr = attributes.get_attribute_ns('http://www.opengis.net/gml', 'remoteSchema')
    assert_instance_of(XML::Attr, attr)

    attr = attributes.get_attribute_ns('http://i.dont.exist', 'nor do i')
    assert_nil(attr)
  end

  def test_property
    attr = city_member.property('name')
    assert_instance_of(String, attr)
    assert_equal('Cambridge', attr)
  end

  def test_get_values
    assert_equal('Cambridge', city_member[:name])
    assert_equal('http://www.foo.net/cgi-bin/wfs?FeatureID=C10239', city_member[:href])

    attributes = city_member.attributes
    assert_equal('Cambridge', attributes[:name])
    assert_equal('http://www.foo.net/cgi-bin/wfs?FeatureID=C10239', attributes[:href])
  end

  def test_get_values_gc
    # There used to be a bug caused by accessing an
    # attribute over and over and over again.
    20000.times do
      @doc.root.attributes["key"]
    end
  end

  def test_set_values
    city_member[:name] = 'London'
    assert_equal('London', city_member[:name])

    city_member[:href] = 'foo'
    assert_equal('foo', city_member[:href])

    attributes = city_member.attributes

    attributes[:name] = 'London'
    assert_equal('London', attributes[:name])

    attributes[:href] = 'foo'
    assert_equal('foo', attributes[:href])
  end

  def test_str_sym()
    attributes = city_member.attributes
    assert_equal('Cambridge', attributes[:name])
    assert_equal('Cambridge', attributes['name'])
  end

  def test_remove_first
    attributes = @doc.find_first('/city:CityModel/city:cityMember').attributes
    assert_equal(5, attributes.length)
    attr = attributes.first
    attr.remove!
    assert_equal(4, attributes.length)
  end

  def test_remove_all
    node = @doc.find_first('/city:CityModel/city:cityMember')
    assert_equal(5, node.attributes.length)

    attrs = Array.new
    node.attributes.each do |attr|
      attrs << attr
      attr.remove!
    end
    assert_equal(5, attrs.length)
    assert_equal(0, node.attributes.length)
  end
end