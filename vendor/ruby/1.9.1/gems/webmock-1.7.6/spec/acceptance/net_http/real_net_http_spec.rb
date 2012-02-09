require 'rubygems'
require 'rspec'
require 'net/http'
require 'net/https'
require 'stringio'
require 'acceptance/net_http/net_http_shared'
require 'support/webmock_server'

describe "Real Net:HTTP without webmock", :without_webmock => true do
  before(:all) do
    raise "WebMock has no access here!!!" if defined?(WebMock::NetHTTPUtility)
    WebMockServer.instance.start
  end

  after(:all) do
    WebMockServer.instance.stop
  end

  it_should_behave_like "Net::HTTP"
end