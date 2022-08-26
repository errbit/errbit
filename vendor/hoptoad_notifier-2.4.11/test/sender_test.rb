require File.dirname(__FILE__) + '/helper'

class SenderTest < Test::Unit::TestCase

  def setup
    reset_config
  end

  def build_sender(opts = {})
    config = HoptoadNotifier::Configuration.new
    opts.each {|opt, value| config.send(:"#{opt}=", value) }
    HoptoadNotifier::Sender.new(config)
  end

  def send_exception(args = {})
    notice = args.delete(:notice) || build_notice_data
    sender = args.delete(:sender) || build_sender(args)
    sender.send_to_hoptoad(notice)
  end

  def stub_http(options = {})
    response = stub(:body => options[:body] || 'body')
    http = stub(:post          => response,
                :read_timeout= => nil,
                :open_timeout= => nil,
                :use_ssl=      => nil)
    Net::HTTP.stubs(:new => http)
    http
  end

  should "post to Hoptoad when using an HTTP proxy" do
    response = stub(:body => 'body')
    http     = stub(:post          => response,
                    :read_timeout= => nil,
                    :open_timeout= => nil,
                    :use_ssl=      => nil)
    proxy    = stub(:new => http)
    Net::HTTP.stubs(:Proxy => proxy)

    url = "http://hoptoadapp.com:80#{HoptoadNotifier::Sender::NOTICES_URI}"
    uri = URI.parse(url)

    proxy_host = 'some.host'
    proxy_port = 88
    proxy_user = 'login'
    proxy_pass = 'passwd'

    send_exception(:proxy_host => proxy_host,
                   :proxy_port => proxy_port,
                   :proxy_user => proxy_user,
                   :proxy_pass => proxy_pass)
    assert_received(http, :post) do |expect| 
      expect.with(uri.path, anything, HoptoadNotifier::HEADERS)
    end
    assert_received(Net::HTTP, :Proxy) do |expect|
      expect.with(proxy_host, proxy_port, proxy_user, proxy_pass)
    end
  end

  should "return the created group's id on successful posting" do
    http = stub_http(:body => '<error-id type="integer">3799307</error-id>')
    assert_equal "3799307", send_exception(:secure => false)
  end

  should "return nil on failed posting" do
    http = stub_http
    http.stubs(:post).raises(Errno::ECONNREFUSED)
    assert_equal nil, send_exception(:secure => false)
  end

  should "not fail when posting and a timeout exception occurs" do
    http = stub_http
    http.stubs(:post).raises(TimeoutError)
    assert_nothing_thrown do
      send_exception(:secure => false)
    end
  end

  should "not fail when posting and a connection refused exception occurs" do
    http = stub_http
    http.stubs(:post).raises(Errno::ECONNREFUSED)
    assert_nothing_thrown do
      send_exception(:secure => false)
    end
  end

  should "not fail when posting any http exception occurs" do
    http = stub_http
    HoptoadNotifier::Sender::HTTP_ERRORS.each do |error|
      http.stubs(:post).raises(error)
      assert_nothing_thrown do
        send_exception(:secure => false)
      end
    end
  end

  should "post to the right url for non-ssl" do
    http = stub_http
    url = "http://hoptoadapp.com:80#{HoptoadNotifier::Sender::NOTICES_URI}"
    uri = URI.parse(url)
    send_exception(:secure => false)
    assert_received(http, :post) {|expect| expect.with(uri.path, anything, HoptoadNotifier::HEADERS) }
  end

  should "post to the right path for ssl" do
    http = stub_http
    send_exception(:secure => true)
    assert_received(http, :post) {|expect| expect.with(HoptoadNotifier::Sender::NOTICES_URI, anything, HoptoadNotifier::HEADERS) }
  end

  should "default the open timeout to 2 seconds" do
    http = stub_http
    send_exception
    assert_received(http, :open_timeout=) {|expect| expect.with(2) }
  end

  should "default the read timeout to 5 seconds" do
    http = stub_http
    send_exception
    assert_received(http, :read_timeout=) {|expect| expect.with(5) }
  end

  should "allow override of the open timeout" do
    http = stub_http
    send_exception(:http_open_timeout => 4)
    assert_received(http, :open_timeout=) {|expect| expect.with(4) }
  end

  should "allow override of the read timeout" do
    http = stub_http
    send_exception(:http_read_timeout => 10)
    assert_received(http, :read_timeout=) {|expect| expect.with(10) }
  end

  should "connect to the right port for ssl" do
    stub_http
    send_exception(:secure => true)
    assert_received(Net::HTTP, :new) {|expect| expect.with("hoptoadapp.com", 443) }
  end

  should "connect to the right port for non-ssl" do
    stub_http
    send_exception(:secure => false)
    assert_received(Net::HTTP, :new) {|expect| expect.with("hoptoadapp.com", 80) }
  end

  should "use ssl if secure" do
    stub_http
    send_exception(:secure => true, :host => 'example.org')
    assert_received(Net::HTTP, :new) {|expect| expect.with('example.org', 443) }
  end

  should "not use ssl if not secure" do
    stub_http
    send_exception(:secure => false, :host => 'example.org')
    assert_received(Net::HTTP, :new) {|expect| expect.with('example.org', 80) }
  end

end
