unless defined?(Pony) or defined?(ActionMailer)
  Kernel.warn("Neither Pony nor ActionMailer appear to be loaded so email-spec is requiring ActionMailer.")
  require 'action_mailer'
end

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__))) unless $LOAD_PATH.include?(File.expand_path(File.dirname(__FILE__)))

require 'rspec'
require 'email_spec/background_processes'
require 'email_spec/deliveries'
require 'email_spec/address_converter'
require 'email_spec/email_viewer'
require 'email_spec/helpers'
require 'email_spec/matchers'
require 'email_spec/mail_ext'
require 'email_spec/test_observer'