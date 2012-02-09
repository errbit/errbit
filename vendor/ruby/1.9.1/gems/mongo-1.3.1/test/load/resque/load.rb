require File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'mongo')
require 'logger'
require 'rubygems'
require 'resque'
require 'sinatra'
require File.join(File.dirname(__FILE__), 'processor')

$con = Mongo::Connection.new
$db = $con['foo']


configure do
  LOGGER = Logger.new("sinatra.log")
  enable :logging, :dump_errors
  set :raise_errors, true
end

get '/' do
  Processor.perform(1)
  true
end
