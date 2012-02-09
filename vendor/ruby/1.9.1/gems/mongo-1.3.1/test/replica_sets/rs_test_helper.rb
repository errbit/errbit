$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require './test/test_helper'
require './test/tools/repl_set_manager'

unless defined? RS
  RS = ReplSetManager.new
  RS.start_set
end

class Test::Unit::TestCase

  # Generic code for rescuing connection failures and retrying operations.
  # This could be combined with some timeout functionality.
  def rescue_connection_failure(max_retries=60)
    retries = 0
    begin
      yield
    rescue Mongo::ConnectionFailure => ex
      puts "Rescue attempt #{retries}: from #{ex}"
      retries += 1
      raise ex if retries > max_retries
      sleep(1)
      retry
    end
  end

end
