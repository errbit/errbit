require 'rubygems'
require 'action_mailer'
require 'rspec'
require 'mail'
require File.expand_path(File.dirname(__FILE__) + '/../lib/email_spec.rb')

class Mail::Message
  def with_inspect_stub(str = "email")
    stub!(:inspect).and_return(str)
    self
  end
end

  RSpec.configure do |config|
  config.mock_with :rspec
end