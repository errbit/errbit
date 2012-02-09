# encoding: UTF-8
require './test_helper'
require 'test/unit'

class TestFoo < Test::Unit::TestCase
  def namespaces
    {'kml' => 'http://earth.google.com/kml/2.2'}
  end

  def doc
    path = File.expand_path(File.join('model', 'kml_sample.xml'))
    data = File.read(path)
    parser = LibXML::XML::Parser.string(data)
    doc = parser.parse
    result = doc.root
    doc = nil
    GC.start
  end

  def test_read
    1000.times do
      read_placemarks
      GC.start
    end
  end

  def read_placemarks
    root = doc.root
    result = Array.new
    root.find('//kml:Placemark', self.namespaces).each do |entry|
      result << self.read_placemark(entry)
    end
    result
  end

  def read_placemark(entry)
    geometries = read_geoms(entry)
    #stop processing this placemark if there aren't any geometries.
    return if geometries.empty?
  end

  def read_geoms(entry)

    geoms = []
    entry.find('//kml:Point', self.namespaces).each do |point_entry|
      geoms << parse_point(point_entry)
    end

    entry.find('//kml:LineString', self.namespaces).each do |point_entry|
      geoms << parse_point(point_entry)
    end

    entry.find('//kml:Polygon', self.namespaces).each do |point_entry|
      geoms << parse_polygon(point_entry)
    end

    geoms
  end

  def parse_point(entry)
    coordinate_entry = entry.find('//kml:coordinates',self.namespaces).first
    coordinate_entry.content.split(",")
  end

  def parse_coordinate_string(entry)
    coordinates = entry.content.split
  end

  def parse_line_string(entry)
    coord_sequence = parse_coordinate_string(entry.find('kml:coordinates',self.namespaces).first)
  end

  def parse_linear_ring(entry)
    coord_sequence = parse_coordinate_string(entry.find('kml:coordinates',self.namespaces).first)
  end

  def parse_polygon(entry)
    exterior_ring = parse_linear_ring(entry.find('kml:outerBoundaryIs/kml:LinearRing', self.namespaces).first)

    interior_rings = []
    entry.find('kml:innerBoundaryIs/kml:LinearRing', self.namespaces).each do |interior_ring|
      interior_rings << parse_linear_ring(interior_ring)
    end
    interior_rings
  end
end
