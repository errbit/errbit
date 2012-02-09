require 'spec_helper'
require 'ostruct'
require 'acceptance/webmock_shared'
require 'acceptance/net_http/net_http_spec_helper'
require 'acceptance/net_http/net_http_shared'

include NetHTTPSpecHelper

describe "Net:HTTP" do
  include_examples "with WebMock"

  let(:port){ WebMockServer.instance.port }

  describe "marshalling" do
    class TestMarshalingInWebMockNetHTTP
      attr_accessor :r
    end
    before(:each) do
      @b = TestMarshalingInWebMockNetHTTP.new
    end
    after(:each) do
      WebMock.enable!
    end
    it "should be possible to load object marshalled when webmock was disabled" do
      WebMock.disable!
      original_constants = [
        Net::HTTP::Get,
        Net::HTTP::Post,
        Net::HTTP::Put,
        Net::HTTP::Delete,
        Net::HTTP::Head,
        Net::HTTP::Options
      ]
      @b.r = original_constants
      original_serialized = Marshal.dump(@b)
      Marshal.load(original_serialized)
      WebMock.enable!
      Marshal.load(original_serialized)
    end

    it "should be possible to load object marshalled when webmock was enabled"  do
      WebMock.enable!
      new_constants = [
        Net::HTTP::Get,
        Net::HTTP::Post,
        Net::HTTP::Put,
        Net::HTTP::Delete,
        Net::HTTP::Head,
        Net::HTTP::Options
      ]
      @b.r = new_constants
      new_serialized = Marshal.dump(@b)
      Marshal.load(new_serialized)
      WebMock.disable!
      Marshal.load(new_serialized)
    end
  end

  describe "constants" do
    it "should still have const Get defined on replaced Net::HTTP" do
      Object.const_get("Net").const_get("HTTP").const_defined?("Get").should be_true
    end

    it "should still have const Get within constants on replaced Net::HTTP" do
      Object.const_get("Net").const_get("HTTP").constants.map(&:to_s).should include("Get")
    end

    it "should still have const Get within constants on replaced Net::HTTP" do
      Object.const_get("Net").const_get("HTTP").const_get("Get").should_not be_nil
    end

    if Module.method(:const_defined?).arity != 1
      it "should still have const Get defined (and not inherited) on replaced Net::HTTP" do
        Object.const_get("Net").const_get("HTTP").const_defined?("Get", false).should be_true
      end
    end

    if Module.method(:const_get).arity != 1
      it "should still be able to get non inherited constant Get on replaced Net::HTTP" do
        Object.const_get("Net").const_get("HTTP").const_get("Get", false).should_not be_nil
      end
    end

    if Module.method(:constants).arity != 0
      it "should still Get within non inherited constants on replaced Net::HTTP" do
        Object.const_get("Net").const_get("HTTP").constants(false).map(&:to_s).should include("Get")
      end
    end
  end

  it "should work with block provided" do
    stub_http_request(:get, "www.example.com").to_return(:body => "abc"*100000)
    Net::HTTP.start("www.example.com") { |query| query.get("/") }.body.should == "abc"*100000
  end

  it "should handle multiple values for the same response header" do
    stub_http_request(:get, "www.example.com").to_return(:headers => { 'Set-Cookie' => ['foo=bar', 'bar=bazz'] })
    response = Net::HTTP.get_response(URI.parse("http://www.example.com/"))
    response.get_fields('Set-Cookie').should == ['bar=bazz', 'foo=bar']
  end

  it "should yield block on response" do
    stub_http_request(:get, "www.example.com").to_return(:body => "abc")
    response_body = ""
    http_request(:get, "http://www.example.com/") do |response|
      response_body = response.body
    end
    response_body.should == "abc"
  end

  it "should handle Net::HTTP::Post#body" do
    stub_http_request(:post, "www.example.com").with(:body => "my_params").to_return(:body => "abc")
    req = Net::HTTP::Post.new("/")
    req.body = "my_params"
    Net::HTTP.start("www.example.com") { |http| http.request(req)}.body.should == "abc"
  end

  it "should handle Net::HTTP::Post#body_stream" do
    stub_http_request(:post, "www.example.com").with(:body => "my_params").to_return(:body => "abc")
    req = Net::HTTP::Post.new("/")
    req.body_stream = StringIO.new("my_params")
    Net::HTTP.start("www.example.com") { |http| http.request(req)}.body.should == "abc"
  end

  it "should behave like Net::HTTP and raise error if both request body and body argument are set" do
    stub_http_request(:post, "www.example.com").with(:body => "my_params").to_return(:body => "abc")
    req = Net::HTTP::Post.new("/")
    req.body = "my_params"
    lambda {
      Net::HTTP.start("www.example.com") { |http| http.request(req, "my_params")}
    }.should raise_error("both of body argument and HTTPRequest#body set")
  end

  it "should return a Net::ReadAdapter from response.body when a stubbed request is made with a block and #read_body" do
    WebMock.stub_request(:get, 'http://example.com/').to_return(:body => "the body")
    response = Net::HTTP.new('example.com', 80).request_get('/') { |r| r.read_body { } }
    response.body.should be_a(Net::ReadAdapter)
  end

  it "should have request 1 time executed in registry after 1 real request", :net_connect => true do
    WebMock.allow_net_connect!
    http = Net::HTTP.new('localhost', port)
    http.get('/') {}
    WebMock::RequestRegistry.instance.requested_signatures.hash.size.should == 1
    WebMock::RequestRegistry.instance.requested_signatures.hash.values.first.should == 1
  end

  describe "connecting on Net::HTTP.start" do
    before(:each) do
      @http = Net::HTTP.new('www.google.com', 443)
      @http.use_ssl = true
      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    describe "when net http is allowed" do
      it "should not connect to the server until the request", :net_connect => true do
        WebMock.allow_net_connect!
        @http.start {|conn|
          conn.peer_cert.should be_nil
        }
      end

      it "should connect to the server on start", :net_connect => true do
        WebMock.allow_net_connect!(:net_http_connect_on_start => true)
        @http.start {|conn|
          cert = OpenSSL::X509::Certificate.new conn.peer_cert
          cert.should be_a(OpenSSL::X509::Certificate)
        }
      end

    end

    describe "when net http is disabled and allowed only for some hosts" do
      it "should not connect to the server until the request", :net_connect => true do
        WebMock.disable_net_connect!(:allow => "www.google.com")
        @http.start {|conn|
          conn.peer_cert.should be_nil
        }
      end

      it "should connect to the server on start", :net_connect => true do
        WebMock.disable_net_connect!(:allow => "www.google.com", :net_http_connect_on_start => true)
        @http.start {|conn|
          cert = OpenSSL::X509::Certificate.new conn.peer_cert
          cert.should be_a(OpenSSL::X509::Certificate)
        }
      end
    end
  end

  describe "when net_http_connect_on_start is true" do
    before(:each) do
      WebMock.allow_net_connect!(:net_http_connect_on_start => true)
    end
    it_should_behave_like "Net::HTTP"
  end

  describe "when net_http_connect_on_start is false" do
    before(:each) do
      WebMock.allow_net_connect!(:net_http_connect_on_start => false)
    end
    it_should_behave_like "Net::HTTP"
  end

  describe 'after_request callback support', :net_connect => true do
    let(:expected_body_regex) { /hello world/ }

    before(:each) do
      WebMock.allow_net_connect!
      @callback_invocation_count = 0
      WebMock.after_request do |_, response|
        @callback_invocation_count += 1
        @callback_response = response
      end
    end

    after(:each) do
      WebMock.reset_callbacks
    end

    def perform_get_with_returning_block
      http_request(:get, "http://localhost:#{port}/") do |response|
        return response.body
      end
    end

    it "should support the after_request callback on an request with block and read_body" do
      response_body = ''
      http_request(:get, "http://localhost:#{port}/") do |response|
        response.read_body { |fragment| response_body << fragment }
      end
      response_body.should =~ expected_body_regex

      @callback_response.body.should == response_body
    end

    it "should support the after_request callback on a request with a returning block" do
      response_body = perform_get_with_returning_block
      response_body.should =~ expected_body_regex
      @callback_response.should be_instance_of(WebMock::Response)
      @callback_response.body.should == response_body
    end

    it "should only invoke the after_request callback once, even for a recursive post request" do
      Net::HTTP.new('localhost', port).post('/', nil)
      @callback_invocation_count.should == 1
    end
  end
end
