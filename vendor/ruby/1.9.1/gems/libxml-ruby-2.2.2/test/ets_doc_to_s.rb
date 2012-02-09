# encoding: UTF-8

require './test_helper'

100.times do |count|

  xml_doc = XML::Document.new()
  xml_doc.encoding = "UTF-8"
  xml_doc.root = XML::Node.new("Request")

  1000.times do |index|

    xml_doc.root << node = XML::Node.new("row")
    node["user_id"] = index.to_s
    node << "600445"

  end

  xml_str = xml_doc.to_s
  print "\r#{count}"
  $stdout.flush
end
puts "\n"
