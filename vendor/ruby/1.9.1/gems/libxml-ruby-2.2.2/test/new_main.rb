# encoding: utf-8

string1 = "(ISC)²"
puts string1.encoding
puts string1.bytes.to_a.join(' ')
puts string1

puts ""
string2 = string1.encode('iso-8859-1')
puts string2.encoding
puts string2.bytes.to_a.join(' ')
puts string2

puts ""
string3 = string1.force_encoding('iso-8859-1').encode('utf-8')
puts string3.encoding
puts string3.bytes.to_a.join(' ')
puts string3

#UTF-8
#40 73 83 67 41 194 178
#(ISC)Â²
#
#ISO-8859-1
#40 73 83 67 41 178
#(ISC)²


#40 73 83 67 41 195 130 194 178