# encoding: UTF-8

require 'libxml'

100.times do
  doc = XML::Document.new
  doc.encoding = 'UTF-8'

  root = XML::Node.new 'gpx'
  root['version'] = '1.0'
  root['creator'] = 'OpenStreetMap.org'
  root['xmlns'] = "http://www.topografix.com/GPX/1/0/"

  doc.root = root

  track = XML::Node.new 'trk'
  doc.root << track

  trkseg = XML::Node.new 'trkseg'
  track << trkseg

  1.upto(1000) do |n|
    trkpt = XML::Node.new 'trkpt'
    trkpt['lat'] = n.to_s
    trkpt['lon'] = n.to_s
    trkseg << trkpt
  end
end
