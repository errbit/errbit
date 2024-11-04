require File.dirname(__FILE__) + '/helper'

class LoggerTest < Test::Unit::TestCase
  def stub_http(response, body = nil)
    response.stubs(:body => body) if body
    @http = stub(:post => response,
                 :read_timeout= => nil,
                 :open_timeout= => nil,
                 :use_ssl= => nil)
    Net::HTTP.stubs(:new).returns(@http)
  end

  def send_notice
    HoptoadNotifier.sender.send_to_hoptoad('data')
  end

  def stub_verbose_log
    HoptoadNotifier.stubs(:write_verbose_log)
  end

  def assert_logged(expected)
    assert_received(HoptoadNotifier, :write_verbose_log) do |expect|
      expect.with {|actual| actual =~ expected }
    end
  end

  def assert_not_logged(expected)
    assert_received(HoptoadNotifier, :write_verbose_log) do |expect|
      expect.with {|actual| actual =~ expected }.never
    end
  end

  def configure
    HoptoadNotifier.configure { |config| }
  end

  should "report that notifier is ready when configured" do
    stub_verbose_log
    configure
    assert_logged /Notifier (.*) ready/
  end

  should "not report that notifier is ready when internally configured" do
    stub_verbose_log
    HoptoadNotifier.configure(true) { |config| }
    assert_not_logged /.*/
  end

  should "print environment info a successful notification without a body" do
    reset_config
    stub_verbose_log
    stub_http(Net::HTTPSuccess)
    send_notice
    assert_logged /Environment Info:/
    assert_not_logged /Response from Hoptoad:/
  end

  should "print environment info on a failed notification without a body" do
    reset_config
    stub_verbose_log
    stub_http(Net::HTTPError)
    send_notice
    assert_logged /Environment Info:/
    assert_not_logged /Response from Hoptoad:/
  end

  should "print environment info and response on a success with a body" do
    reset_config
    stub_verbose_log
    stub_http(Net::HTTPSuccess, 'test')
    send_notice
    assert_logged /Environment Info:/
    assert_logged /Response from Hoptoad:/
  end

  should "print environment info and response on a failure with a body" do
    reset_config
    stub_verbose_log
    stub_http(Net::HTTPError, 'test')
    send_notice
    assert_logged /Environment Info:/
    assert_logged /Response from Hoptoad:/
  end

end
