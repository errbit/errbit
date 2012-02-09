ENV['SKIP_RAILS'] = 'true'
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','test_helper'))
require "new_relic/agent/browser_monitoring"

class NewRelic::Agent::BrowserMonitoringTest < Test::Unit::TestCase
  include NewRelic::Agent::BrowserMonitoring
  include NewRelic::Agent::Instrumentation::ControllerInstrumentation
  
  def setup
    NewRelic::Agent.manual_start
    @browser_monitoring_key = "fred"
    @episodes_file = "this_is_my_file"
    NewRelic::Agent.instance.instance_eval do
      @beacon_configuration = NewRelic::Agent::BeaconConfiguration.new({"rum.enabled" => true, "browser_key" => "browserKey", "application_id" => "apId", "beacon"=>"beacon", "episodes_url"=>"this_is_my_file", 'rum.jsonp' => true})
    end
    Thread.current[:last_metric_frame] = nil
    NewRelic::Agent::TransactionInfo.clear
  end

  def teardown
    mocha_teardown
  end

  def test_browser_monitoring_start_time_is_reset_each_request_when_auto_instrument_is_disabled
    controller = Object.new
    def controller.perform_action_without_newrelic_trace(method, options={});
      # noop; instrument me
    end
    def controller.newrelic_metric_path; "foo"; end
    controller.extend ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
    controller.extend ::NewRelic::Agent::BrowserMonitoring
    NewRelic::Control.instance['browser_monitoring'] = { 'auto_instrument' => false }

    controller.perform_action_with_newrelic_trace(:index)
    first_request_start_time = controller.send(:browser_monitoring_start_time)
    controller.perform_action_with_newrelic_trace(:index)
    second_request_start_time = controller.send(:browser_monitoring_start_time)

    # assert that these aren't the same time object
    # the start time should be reinitialized each request to the controller
    assert !(first_request_start_time.equal? second_request_start_time)
  end

  def test_browser_timing_header_with_no_beacon_configuration
    NewRelic::Agent.instance.expects(:beacon_configuration).returns( nil)
    header = browser_timing_header
    assert_equal "", header
  end

  def test_browser_timing_header
    header = browser_timing_header
    assert_equal "<script type=\"text/javascript\">var NREUMQ=NREUMQ||[];NREUMQ.push([\"mark\",\"firstbyte\",new Date().getTime()]);</script>", header
  end

  def test_browser_timing_header_with_rum_enabled_not_specified
    NewRelic::Agent.instance.expects(:beacon_configuration).at_least_once.returns( NewRelic::Agent::BeaconConfiguration.new({"browser_key" => "browserKey", "application_id" => "apId", "beacon"=>"beacon", "episodes_url"=>"this_is_my_file"}))
    header = browser_timing_header
    assert_equal "<script type=\"text/javascript\">var NREUMQ=NREUMQ||[];NREUMQ.push([\"mark\",\"firstbyte\",new Date().getTime()]);</script>", header
  end

  def test_browser_timing_header_with_rum_enabled_false
    NewRelic::Agent.instance.expects(:beacon_configuration).twice.returns( NewRelic::Agent::BeaconConfiguration.new({"rum.enabled" => false, "browser_key" => "browserKey", "application_id" => "apId", "beacon"=>"beacon", "episodes_url"=>"this_is_my_file"}))
    header = browser_timing_header
    assert_equal "", header
  end

  def test_browser_timing_header_disable_all_tracing
    header = nil
    NewRelic::Agent.disable_all_tracing do
      header = browser_timing_header
    end
    assert_equal "", header
  end

  def test_browser_timing_header_disable_transaction_tracing
    header = nil
    NewRelic::Agent.disable_transaction_tracing do
      header = browser_timing_header
    end
    assert_equal "", header
  end

  def test_browser_timing_footer
    browser_timing_header
    NewRelic::Control.instance.expects(:license_key).returns("a" * 13)

    footer = browser_timing_footer
    snippet = '<script type="text/javascript">if (!NREUMQ.f) { NREUMQ.f=function() {
NREUMQ.push(["load",new Date().getTime()]);
var e=document.createElement("script");'
    assert footer.include?(snippet), "Expected footer to include snippet: #{snippet}, but instead was #{footer}"
  end

  def test_browser_timing_footer_with_no_browser_key_rum_enabled
    browser_timing_header
    NewRelic::Agent.instance.expects(:beacon_configuration).returns( NewRelic::Agent::BeaconConfiguration.new({"rum.enabled" => true, "application_id" => "apId", "beacon"=>"beacon", "episodes_url"=>"this_is_my_file"}))
    footer = browser_timing_footer
    assert_equal "", footer
  end

  def test_browser_timing_footer_with_no_browser_key_rum_disabled
    browser_timing_header
    NewRelic::Agent.instance.expects(:beacon_configuration).returns( NewRelic::Agent::BeaconConfiguration.new({"rum.enabled" => false, "application_id" => "apId", "beacon"=>"beacon", "episodes_url"=>"this_is_my_file"}))
    footer = browser_timing_footer
    assert_equal "", footer
  end

  def test_browser_timing_footer_with_rum_enabled_not_specified
    browser_timing_header

    license_bytes = [];
    ("a" * 13).each_byte {|byte| license_bytes << byte}
    config =  NewRelic::Agent::BeaconConfiguration.new({"browser_key" => "browserKey", "application_id" => "apId", "beacon"=>"beacon", "episodes_url"=>"this_is_my_file", "license_bytes" => license_bytes})
    config.expects(:license_bytes).returns(license_bytes).at_least_once
    NewRelic::Agent.instance.expects(:beacon_configuration).returns(config).at_least_once
    footer = browser_timing_footer
    beginning_snippet = '<script type="text/javascript">if (!NREUMQ.f) { NREUMQ.f=function() {
NREUMQ.push(["load",new Date().getTime()]);
var e=document.createElement("script");'
    ending_snippet = "])</script>"
    assert(footer.include?(beginning_snippet), "expected footer to include beginning snippet: #{beginning_snippet}, but was #{footer}")
    assert(footer.include?(ending_snippet), "expected footer to include ending snippet: #{ending_snippet}, but was #{footer}")
  end

  def test_browser_timing_footer_with_no_beacon_configuration
    browser_timing_header
    NewRelic::Agent.instance.expects(:beacon_configuration).returns( nil)
    footer = browser_timing_footer
    assert_equal "", footer
  end


  def test_browser_timing_footer_disable_all_tracing
    browser_timing_header
    footer = nil
    NewRelic::Agent.disable_all_tracing do
      footer = browser_timing_footer
    end
    assert_equal "", footer
  end

  def test_browser_timing_footer_disable_transaction_tracing
    browser_timing_header
    footer = nil
    NewRelic::Agent.disable_transaction_tracing do
      footer = browser_timing_footer
    end
    assert_equal "", footer
  end

  def test_browser_timing_footer_browser_monitoring_key_missing
    fake_config = mock('beacon configuration')
    NewRelic::Agent.instance.expects(:beacon_configuration).returns(fake_config)
    fake_config.expects(:nil?).returns(false)
    fake_config.expects(:rum_enabled).returns(true)
    fake_config.expects(:browser_monitoring_key).returns(nil)
    self.expects(:generate_footer_js).never
    assert_equal('', browser_timing_footer, "should not return a footer when there is no key")
  end

  def test_generate_footer_js_null_case
    self.expects(:browser_monitoring_start_time).returns(nil)
    assert_equal('', generate_footer_js(NewRelic::Agent.instance.beacon_configuration), "should not send javascript when there is no start time")
  end
 
  def test_generate_footer_js_with_start_time
    self.expects(:browser_monitoring_start_time).returns(Time.at(100))
    fake_bc = mock('beacon configuration')
    fake_bc.expects(:application_id).returns(1)
    fake_bc.expects(:beacon).returns('beacon')
    fake_bc.expects(:browser_monitoring_key).returns('a' * 40)
    NewRelic::Agent.instance.stubs(:beacon_configuration).returns(fake_bc)
    self.expects(:footer_js_string).with(NewRelic::Agent.instance.beacon_configuration, 'beacon', 'a' * 40, 1).returns('footer js')
    assert_equal('footer js', generate_footer_js(NewRelic::Agent.instance.beacon_configuration), 'should generate and return the footer JS when there is a start time')
  end

  def test_browser_monitoring_transaction_name_basic
    mock = mock('transaction sample')
    NewRelic::Agent::TransactionInfo.set(mock)
    mock.stubs(:transaction_name).returns('a transaction name')

    assert_equal('a transaction name', browser_monitoring_transaction_name, "should take the value from the thread local")
  end

  def test_browser_monitoring_transaction_name_empty
    mock = mock('transaction sample')
    NewRelic::Agent::TransactionInfo.set(mock)

    mock.stubs(:transaction_name).returns('')
    assert_equal('', browser_monitoring_transaction_name, "should take the value even when it is empty")
  end

  def test_browser_monitoring_transaction_name_nil
    assert_equal('(unknown)', browser_monitoring_transaction_name, "should fill in a default when it is nil")
  end
  
  def test_browser_monitoring_transaction_name_when_tt_disabled
    @sampler = NewRelic::Agent.instance.transaction_sampler
    @sampler.disable

    perform_action_with_newrelic_trace(:name => 'disabled_transactions') do
      self.class.inspect
    end
        
    assert_match(/disabled_transactions/, browser_monitoring_transaction_name,
                 "should name transaction when transaction tracing disabled")
  ensure
    @sampler.enable
  end
  
  
  def test_browser_monitoring_start_time
    mock = mock('transaction info')
    
    NewRelic::Agent::TransactionInfo.set(mock)
    
    mock.stubs(:start_time).returns(Time.at(100))
    mock.stubs(:guid).returns('ABC')
    assert_equal(Time.at(100), browser_monitoring_start_time, "should take the value from the thread local")
  end

  def test_clamp_to_positive
    assert_equal(0.0, clamp_to_positive(-1), "should clamp a negative value to zero")
    assert_equal(1232, clamp_to_positive(1232), "should pass through the value when it is positive")
    assert_equal(0, clamp_to_positive(0), "should not mess with zero when passing it through")
  end

  def test_browser_monitoring_app_time_nonzero
    start = Time.now
    self.expects(:browser_monitoring_start_time).returns(start - 1)
    Time.expects(:now).returns(start)
    assert_equal(1000, browser_monitoring_app_time, 'should return a rounded time')
  end

  def test_browser_monitoring_queue_time_nil
    assert_equal(0.0, browser_monitoring_queue_time, 'should return zero when there is no queue time')
  end

  def test_browser_monitoring_queue_time_zero
    frame = Thread.current[:last_metric_frame] = mock('metric frame')
    frame.expects(:queue_time).returns(0.0)
    assert_equal(0.0, browser_monitoring_queue_time, 'should return zero when there is zero queue time')
  end

  def test_browser_monitoring_queue_time_ducks
    frame = Thread.current[:last_metric_frame] = mock('metric frame')
    frame.expects(:queue_time).returns('a duck')
    assert_equal(0.0, browser_monitoring_queue_time, 'should return zero when there is an incorrect queue time')
  end

  def test_browser_monitoring_queue_time_nonzero
    frame = Thread.current[:last_metric_frame] = mock('metric frame')
    frame.expects(:queue_time).returns(3.00002)
    assert_equal(3000, browser_monitoring_queue_time, 'should return a rounded time')
  end

  def test_footer_js_string_basic
    beacon = ''
    license_key = ''
    application_id = 1

    # mocking this because JRuby thinks that Time.now - Time.now
    # always takes at least 1ms
    self.expects(:browser_monitoring_app_time).returns(0)
    frame = Thread.current[:last_metric_frame] = mock('metric frame')
    user_attributes = {:user => "user", :account => "account", :product => "product"}
    frame.expects(:user_attributes).returns(user_attributes).at_least_once
    frame.expects(:queue_time).returns(0)

    sample = mock('transaction info')
    NewRelic::Agent::TransactionInfo.set(sample)
    
    sample.stubs(:start_time).returns(Time.at(100))
    sample.stubs(:guid).returns('ABC')
    sample.stubs(:transaction_name).returns('most recent transaction')
    sample.stubs(:include_guid?).returns(true)
    sample.stubs(:duration).returns(12.0)
    sample.stubs(:token).returns('0123456789ABCDEF')
    
    self.expects(:obfuscate).with(NewRelic::Agent.instance.beacon_configuration, 'most recent transaction').returns('most recent transaction')
    self.expects(:obfuscate).with(NewRelic::Agent.instance.beacon_configuration, 'user').returns('user')
    self.expects(:obfuscate).with(NewRelic::Agent.instance.beacon_configuration, 'account').returns('account')
    self.expects(:obfuscate).with(NewRelic::Agent.instance.beacon_configuration, 'product').returns('product')

    value = footer_js_string(NewRelic::Agent.instance.beacon_configuration, beacon, license_key, application_id)
    assert_equal("<script type=\"text/javascript\">if (!NREUMQ.f) { NREUMQ.f=function() {\nNREUMQ.push([\"load\",new Date().getTime()]);\nvar e=document.createElement(\"script\");\ne.type=\"text/javascript\";e.async=true;e.src=\"this_is_my_file\";\ndocument.body.appendChild(e);\nif(NREUMQ.a)NREUMQ.a();\n};\nNREUMQ.a=window.onload;window.onload=NREUMQ.f;\n};\nNREUMQ.push([\"nrfj\",\"\",\"\",1,\"most recent transaction\",0,0,new Date().getTime(),\"ABC\",\"0123456789ABCDEF\",\"user\",\"account\",\"product\"])</script>", value, "should return the javascript given some default values")
  end

  def test_html_safe_if_needed_unsafed
    string = mock('string')
    # here to handle 1.9 encoding - we stub this out because it should
    # be handled automatically and is outside the scope of this test
    string.stubs(:respond_to?).with(:encoding).returns(false)
    string.expects(:respond_to?).with(:html_safe).returns(false)
    assert_equal(string, html_safe_if_needed(string))
  end

  def test_html_safe_if_needed_safed
    string = mock('string')
    string.expects(:respond_to?).with(:html_safe).returns(true)
    string.expects(:html_safe).returns(string)
    # here to handle 1.9 encoding - we stub this out because it should
    # be handled automatically and is outside the scope of this test
    string.stubs(:respond_to?).with(:encoding).returns(false)
    assert_equal(string, html_safe_if_needed(string))
  end

  def test_obfuscate_basic
    text = 'a happy piece of small text'
    key = (1..40).to_a
    NewRelic::Agent.instance.beacon_configuration.expects(:license_bytes).returns(key)
    output = obfuscate(NewRelic::Agent.instance.beacon_configuration, text)
    assert_equal('YCJrZXV2fih5Y25vaCFtZSR2a2ZkZSp/aXV1', output, "should output obfuscated text")
  end

  def test_obfuscate_long_string
    text = 'a happy piece of small text' * 5
    key = (1..40).to_a
    NewRelic::Agent.instance.beacon_configuration.expects(:license_bytes).returns(key)
    output = obfuscate(NewRelic::Agent.instance.beacon_configuration, text)
    assert_equal('YCJrZXV2fih5Y25vaCFtZSR2a2ZkZSp/aXV1YyNsZHZ3cSl6YmluZCJsYiV1amllZit4aHl2YiRtZ3d4cCp7ZWhiZyNrYyZ0ZWhmZyx5ZHp3ZSVuZnh5cyt8ZGRhZiRqYCd7ZGtnYC11Z3twZCZvaXl6cix9aGdgYSVpYSh6Z2pgYSF2Znxx', output, "should output obfuscated text")
  end
end
