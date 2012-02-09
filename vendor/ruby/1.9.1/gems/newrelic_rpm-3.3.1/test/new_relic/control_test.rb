require File.expand_path(File.join(File.dirname(__FILE__),'/../test_helper'))
class NewRelic::ControlTest < Test::Unit::TestCase

  attr_reader :control

  def setup
    NewRelic::Agent.manual_start(:dispatcher_instance_id => 'test')
    @control =  NewRelic::Control.instance
    raise 'oh geez, wrong class' unless NewRelic::Control.instance.is_a?(::NewRelic::Control::Frameworks::Test)
  end

  def shutdown
    NewRelic::Agent.shutdown
  end

  def test_cert_file_path
    assert @control.cert_file_path
    assert_equal File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'cert', 'cacert.pem')), @control.cert_file_path
  end
  
  # This test does not actually use the ruby agent in any way - it's
  # testing that the CA file we ship actually validates our server's
  # certificate. It's used for customers who enable verify_certificate
  def test_cert_file
    return if ::RUBY_VERSION == '1.9.3'
    require 'socket'
    require 'openssl'

    s   = TCPSocket.new 'collector.newrelic.com', 443
    ctx = OpenSSL::SSL::SSLContext.new
    ctx.ca_file = @control.cert_file_path
    ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER
    s   = OpenSSL::SSL::SSLSocket.new s, ctx
    s.connect
    # should not raise an error
  end
  
  # see above, but for staging, as well. This allows us to test new
  # certificates in a non-customer-facing place before setting them
  # live.
  def test_staging_cert_file
    return if ::RUBY_VERSION == '1.9.3'
    require 'socket'
    require 'openssl'

    s   = TCPSocket.new 'staging-collector.newrelic.com', 443
    ctx = OpenSSL::SSL::SSLContext.new
    ctx.ca_file = @control.cert_file_path
    ctx.verify_mode = OpenSSL::SSL::VERIFY_PEER
    s   = OpenSSL::SSL::SSLSocket.new s, ctx
    s.connect
    # should not raise an error
  end

  def test_monitor_mode
    assert ! @control.monitor_mode?
    @control.settings.delete 'enabled'
    @control.settings.delete 'monitor_mode'
    assert !@control.monitor_mode?
    @control['enabled'] = false
    assert ! @control.monitor_mode?
    @control['enabled'] = true
    assert @control.monitor_mode?
    @control['monitor_mode'] = nil
    assert !@control.monitor_mode?
    @control['monitor_mode'] = false
    assert !@control.monitor_mode?
    @control['monitor_mode'] = true
    assert @control.monitor_mode?
  ensure
    @control['enabled'] = false
    @control['monitor_mode'] = false
  end

  def test_test_config
    if defined?(Rails) && Rails::VERSION::MAJOR.to_i == 3
      assert_equal :rails3, control.app
    elsif defined?(Rails)
      assert_equal :rails, control.app
    else
      assert_equal :test, control.app
    end
    assert_equal :test, control.framework
    assert_match /test/i, control.dispatcher_instance_id
    assert("" == control.dispatcher.to_s, "Expected dispatcher to be empty, but was #{control.dispatcher.to_s}")
    assert !control['enabled']
    assert_equal false, control['monitor_mode']
    control.local_env
  end

  def test_root
    assert File.directory?(NewRelic::Control.newrelic_root), NewRelic::Control.newrelic_root
    if defined?(Rails)
      assert File.directory?(File.join(NewRelic::Control.newrelic_root, "lib")), NewRelic::Control.newrelic_root +  "/lib"
    end
  end

  def test_info
    props = NewRelic::Control.instance.local_env.snapshot
    if defined?(Rails)
      assert_match /jdbc|postgres|mysql|sqlite/, props.assoc('Database adapter').last, props.inspect
    end
  end

  def test_resolve_ip
    assert_equal nil, control.send(:convert_to_ip_address, 'localhost')
    assert_equal nil, control.send(:convert_to_ip_address, 'q1239988737.us')
    # This will fail if you don't have a valid, accessible, DNS server
    assert_equal '204.93.223.153', control.send(:convert_to_ip_address, 'collector.newrelic.com')
  end

  class FakeResolv
    def self.getaddress(host)
      raise 'deliberately broken'
    end
  end

  def test_resolve_ip_with_broken_dns
    # Here be dragons: disable the ruby DNS lookup methods we use so
    # that it will actually fail to resolve.
    old_resolv = Resolv
    old_ipsocket = IPSocket
    Object.instance_eval { remove_const :Resolv}
    Object.instance_eval {remove_const:'IPSocket' }
    assert_equal(nil, control.send(:convert_to_ip_address, 'collector.newrelic.com'), "DNS is down, should be no IP for server")

    Object.instance_eval {const_set('Resolv', old_resolv); const_set('IPSocket', old_ipsocket)}
    # these are here to make sure that the constant tomfoolery above
    # has not broket the system unduly
    assert_equal old_resolv, Resolv
    assert_equal old_ipsocket, IPSocket
  end

  def test_config_yaml_erb
    assert_equal 'heyheyhey', control['erb_value']
    assert_equal '', control['message']
    assert_equal '', control['license_key']
  end

  def test_appnames
    assert_equal %w[a b c], NewRelic::Control.instance.app_names
  end

  def test_config_booleans
    assert_equal control['tval'], true
    assert_equal control['fval'], false
    assert_nil control['not_in_yaml_val']
    assert_equal control['yval'], true
    assert_equal control['sval'], 'sure'
  end

  def test_config_apdex
    assert_equal 1.1, control.apdex_t
  end

#  def test_transaction_threshold
#    assert_equal 'Apdex_f', c['transaction_tracer']['transaction_threshold']
#    assert_equal 4.4, NewRelic::Agent::Agent.instance.instance_variable_get('@slowest_transaction_threshold')
#  end

  def test_log_file_name
    NewRelic::Control.instance.setup_log
    assert_match /newrelic_agent.log$/, control.instance_variable_get('@log_file')
  end

#  def test_transaction_threshold__apdex
#    forced_start
#    assert_equal 'Apdex_f', c['transaction_tracer']['transaction_threshold']
#    assert_equal 4.4, NewRelic::Agent::Agent.instance.instance_variable_get('@slowest_transaction_threshold')
#  end

  def test_transaction_threshold__default
    forced_start :transaction_tracer => { :transaction_threshold => nil}
    assert_nil control['transaction_tracer']['transaction_threshold']
    assert_equal 2.0, NewRelic::Agent::Agent.instance.instance_variable_get('@slowest_transaction_threshold')
  end

  def test_transaction_threshold__override
    forced_start :transaction_tracer => { :transaction_threshold => 1}
    assert_equal 1, control['transaction_tracer']['transaction_threshold']
    assert_equal 1, NewRelic::Agent::Agent.instance.instance_variable_get('@slowest_transaction_threshold')
  end

  def test_transaction_tracer_disabled
    forced_start(:transaction_tracer => { :enabled => false },
                 :developer_mode => false, :monitor_mode => true)
    NewRelic::Agent::Agent.instance.check_transaction_sampler_status
    
    assert(!NewRelic::Agent::Agent.instance.transaction_sampler.enabled?,
           'transaction tracer enabled when config calls for disabled')
    
    @control['developer_mode'] = true
    @control['monitor_mode'] = false
  end
  
  def test_sql_tracer_disabled
    forced_start(:slow_sql => { :enabled => false }, :monitor_mode => true)
    NewRelic::Agent::Agent.instance.check_sql_sampler_status
    
    assert(!NewRelic::Agent::Agent.instance.sql_sampler.enabled?,
           'sql tracer enabled when config calls for disabled')
    
    @control['monitor_mode'] = false
  end
  
  def test_sql_tracer_disabled_with_record_sql_false
    forced_start(:slow_sql => { :enabled => true, :record_sql => 'off' })
    NewRelic::Agent::Agent.instance.check_sql_sampler_status
    
    assert(!NewRelic::Agent::Agent.instance.sql_sampler.enabled?,
           'sql tracer enabled when config calls for disabled')
  end

  def test_sql_tracer_disabled_when_tt_disabled
    forced_start(:transaction_tracer => { :enabled => false },
                 :slow_sql => { :enabled => true },
                 :developer_mode => false, :monitor_mode => true)
    NewRelic::Agent::Agent.instance.check_sql_sampler_status
    
    assert(!NewRelic::Agent::Agent.instance.sql_sampler.enabled?,
           'sql enabled when transaction tracer disabled')
    
    @control['developer_mode'] = true
    @control['monitor_mode'] = false    
  end

  def test_sql_tracer_disabled_when_tt_disabled_by_server
    forced_start(:slow_sql => { :enabled => true },
                 :transaction_tracer => { :enabled => true },
                 :monitor_mode => true)
    NewRelic::Agent::Agent.instance.check_sql_sampler_status
    NewRelic::Agent::Agent.instance.finish_setup('collect_traces' => false)    
    
    assert(!NewRelic::Agent::Agent.instance.sql_sampler.enabled?,
           'sql enabled when tracing disabled by server')
    
    @control['monitor_mode'] = false        
  end

  def test_merging_options
    NewRelic::Control.send :public, :merge_options
    @control.merge_options :api_port => 66, :transaction_tracer => { :explain_threshold => 2.0 }
    assert_equal 66, NewRelic::Control.instance['api_port']
    assert_equal 2.0, NewRelic::Control.instance['transaction_tracer']['explain_threshold']
    assert_equal 'raw', NewRelic::Control.instance['transaction_tracer']['record_sql']
  end

  private

  def forced_start overrides = {}
    NewRelic::Agent.manual_start overrides
    # This is to force the agent to start again.
    NewRelic::Agent.instance.stubs(:started?).returns(nil)
    NewRelic::Agent.instance.start
  end
end
