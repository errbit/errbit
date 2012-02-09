dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require File.join(dir, 'happymapper')

file_contents = File.read(dir + '/../spec/fixtures/multi_street_address.xml')

class MultiStreetAddress
  include HappyMapper
  
  tag 'address'
  
  # allow primitive type to be collection
  has_many :street_address, String, :tag => "streetaddress"
  element :city, String
  element :state_or_province, String, :tag => "stateOrProvince"
  element :zip, String
  element :country, String
end

multi = MultiStreetAddress.parse(file_contents)

puts "Street Address:"

multi.street_address.each do |street|
  puts street
end

puts "City: #{multi.city}"
puts "State/Province: #{multi.state_or_province}"
puts "Zip: #{multi.zip}"
puts "Country: #{multi.country}"
