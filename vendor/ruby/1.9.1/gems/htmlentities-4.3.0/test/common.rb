$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'test/unit'
require 'htmlentities'

ENCODING_AWARE_RUBY = "1.9".respond_to?(:encoding)
$KCODE = 'u' unless ENCODING_AWARE_RUBY
