require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'webmock/test_unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'redmine_client'

class Test::Unit::TestCase
end
