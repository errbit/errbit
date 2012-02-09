require File.expand_path(File.join(File.dirname(__FILE__),'..', '..',
                                   'test_helper'))
require 'rack/test'
require 'new_relic/rack/browser_monitoring'

ENV['RACK_ENV'] = 'test'

# we should expand the environments we support, any rack app could
# benefit from auto-rum, but the truth of the matter is that atm
# we only support Rails >= 2.3
def middleware_supported?
  ::Rails::VERSION::MAJOR >= 2 && ::Rails::VERSION::MINOR >= 3
end

if middleware_supported?
class BrowserMonitoringTest < Test::Unit::TestCase
  include Rack::Test::Methods
  
  class TestApp
    def self.doc=(other)
      @@doc = other
    end

    def call(env)
      @@doc ||= <<-EOL
<html>
  <head>
    <title>im a title</title>
    <meta some-crap="1"/>
    <script>
      junk
    </script>
  </head>
  <body>im some body text</body>
</html>
EOL
      [200, {'Content-Type' => 'text/html'}, Rack::Response.new(@@doc)]
    end
    include NewRelic::Agent::Instrumentation::Rack
  end
  
  def app
    NewRelic::Rack::BrowserMonitoring.new(TestApp.new)
  end
  
  def setup
    super
    clear_cookies
    NewRelic::Agent.manual_start
    config = NewRelic::Agent::BeaconConfiguration.new("browser_key" => "browserKey",
                                                      "application_id" => "apId",
                                                      "beacon"=>"beacon",
                                                      "episodes_url"=>"this_is_my_file")
    NewRelic::Agent.instance.stubs(:beacon_configuration).returns(config)
    NewRelic::Agent.stubs(:is_transaction_traced?).returns(true)
  end
  
  def teardown
    super
    clear_cookies
    mocha_teardown
    TestApp.doc = nil
  end
  
  def test_make_sure_header_is_set
    assert NewRelic::Agent.browser_timing_header.size > 0
  end
  
  def test_make_sure_footer_is_set
    assert NewRelic::Agent.browser_timing_footer.size > 0
  end
  
  def test_should_only_instrument_successfull_html_requests
    assert app.should_instrument?(200, {'Content-Type' => 'text/html'})
    assert !app.should_instrument?(500, {'Content-Type' => 'text/html'})
    assert !app.should_instrument?(200, {'Content-Type' => 'text/xhtml'})
  end

  def test_insert_timing_header_right_after_open_head_if_no_meta_tags
    get '/'
    
    assert(last_response.body.include?("head>#{NewRelic::Agent.browser_timing_header}"),
           last_response.body)
    TestApp.doc = nil
  end  
  
  def test_insert_timing_header_right_before_head_close_if_ua_compatible_found
    TestApp.doc = <<-EOL
<html>
  <head>
    <title>im a title</title>
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/>
    <script>
      junk
    </script>
  </head>
  <body>im some body text</body>
</html>
EOL
    get '/'
    
    assert(last_response.body.include?("#{NewRelic::Agent.browser_timing_header}</head>"),
           last_response.body)
  end
  
  def test_insert_timing_footer_right_before_html_body_close
    get '/'
    
    assert_match(/.*NREUMQ\.push.*new Date\(\)\.getTime\(\),"","","","",""\]\)<\/script><\/body>/,
                 last_response.body)
  end
  
  def test_should_not_throw_exception_on_empty_reponse
    TestApp.doc = ''
    get '/'

    assert last_response.ok?
  end
  
  def test_token_is_set_in_footer_when_set_by_cookie
    token = '1234567890987654321'
    set_cookie "NRAGENT=tk=#{token}"
    get '/'
    
    assert(last_response.body.include?(token), last_response.body)
  end

  def test_guid_is_set_in_footer_when_token_is_set
    guid = 'abcdefgfedcba'
    NewRelic::TransactionSample.any_instance.stubs(:generate_guid).returns(guid)
    NewRelic::Control.instance.stubs(:apdex_t).returns(0.0001)
    set_cookie "NRAGENT=tk=token"
    get '/'

    assert(last_response.body.include?(guid), last_response.body)
  end
end
end
