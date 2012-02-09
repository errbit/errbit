require File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'mongo')
require 'logger'

$con = Mongo::Connection.new
$db = $con['foo']

class Load < Sinatra::Base

  configure do
    LOGGER = Logger.new("sinatra.log")
    enable :logging, :dump_errors
    set :raise_errors, true
  end

  get '/' do
    3.times do |n|
      if (v=$db.eval("1 + #{n}")) != 1 + n
        STDERR << "#{1 + n} expected but got #{v}"
        raise StandardError, "#{1 + n} expected but got #{v}"
      end
    end
  end

end
