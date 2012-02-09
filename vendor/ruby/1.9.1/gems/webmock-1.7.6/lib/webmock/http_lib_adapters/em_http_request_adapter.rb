begin
  require 'em-http-request'
rescue LoadError
  # em-http-request not found
end

if defined?(EventMachine::HttpConnection)
  require File.expand_path(File.dirname(__FILE__) + '/em_http_request/em_http_request_1_x')
else
  require File.expand_path(File.dirname(__FILE__) + '/em_http_request/em_http_request_0_x')
end
