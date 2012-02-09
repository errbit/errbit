require File.expand_path(File.join(File.dirname(__FILE__),'..','..','..','test_helper'))
class NewRelic::Agent::Agent::StartTest < Test::Unit::TestCase
  require 'new_relic/agent/agent'
  include NewRelic::Agent::Agent::Start

  def test_already_started_positive
    control = mocked_control
    control.expects(:log!).with("Agent Started Already!", :error)
    self.expects(:started?).returns(true)
    assert already_started?, "should have already started"
  end

  def test_already_started_negative
    self.expects(:started?).returns(false)
    assert !already_started?
  end

  def test_disabled_positive
    control = mocked_control
    control.expects(:agent_enabled?).returns(false)
    assert disabled?
  end

  def test_disabled_negative
    control = mocked_control
    control.expects(:agent_enabled?).returns(true)
    assert !disabled?
  end

  def test_log_dispatcher_positive
    control = mocked_control
    log = mocked_log
    control.expects(:dispatcher).returns('Y U NO SERVE WEBPAGE')
    log.expects(:info).with("Dispatcher: Y U NO SERVE WEBPAGE")
    log_dispatcher
  end

  def test_log_dispatcher_negative
    control = mocked_control
    log = mocked_log
    control.expects(:dispatcher).returns('')
    log.expects(:info).with("No dispatcher detected.")
    log_dispatcher
  end

  def test_log_app_names
    control = mocked_control
    log = mocked_log
    control.expects(:app_names).returns(%w(zam zam zabam))
    log.expects(:info).with("Application: zam, zam, zabam")
    log_app_names
  end

  def test_check_config_and_start_agent_disabled
    self.expects(:monitoring?).returns(false)
    check_config_and_start_agent
  end

  def test_check_config_and_start_agent_incorrect_key
    self.expects(:monitoring?).returns(true)
    self.expects(:has_correct_license_key?).returns(false)
    check_config_and_start_agent
  end

  def test_check_config_and_start_agent_forking
    self.expects(:monitoring?).returns(true)
    self.expects(:has_correct_license_key?).returns(true)
    self.expects(:using_forking_dispatcher?).returns(true)
    check_config_and_start_agent
  end

  def test_check_config_and_start_agent_normal
    self.expects(:monitoring?).returns(true)
    self.expects(:has_correct_license_key?).returns(true)
    self.expects(:using_forking_dispatcher?).returns(false)
    control = mocked_control
    control.expects(:sync_startup).returns(false)
    self.expects(:start_worker_thread)
    self.expects(:install_exit_handler)
    check_config_and_start_agent
  end

  def test_check_config_and_start_agent_sync
    self.expects(:monitoring?).returns(true)
    self.expects(:has_correct_license_key?).returns(true)
    self.expects(:using_forking_dispatcher?).returns(false)
    control = mocked_control
    control.expects(:sync_startup).returns(true)
    self.expects(:connect_in_foreground)
    self.expects(:start_worker_thread)
    self.expects(:install_exit_handler)
    check_config_and_start_agent
  end

  def test_connect_in_foreground
    self.expects(:connect).with({:keep_retrying => false })
    connect_in_foreground
  end

  def at_exit
    yield
  end
  private :at_exit

  def test_install_exit_handler_positive
    control = mocked_control
    control.expects(:send_data_on_exit).returns(true)
    NewRelic::LanguageSupport.expects(:using_engine?).with('rbx').returns(false)
    NewRelic::LanguageSupport.expects(:using_engine?).with('jruby').returns(false)
    self.expects(:using_sinatra?).returns(false)
    # we are overriding at_exit above, to immediately return, so we can
    # test the shutdown logic. It's somewhat unfortunate, but we can't
    # kill the interpreter during a test.
    self.expects(:shutdown)
    install_exit_handler
  end

  def test_install_exit_handler_negative
    control = mocked_control
    control.expects(:send_data_on_exit).returns(false)
    install_exit_handler
  end

  def test_install_exit_handler_weird_ruby
    control = mocked_control
    control.expects(:send_data_on_exit).times(3).returns(true)
    NewRelic::LanguageSupport.expects(:using_engine?).with('rbx').returns(false)
    NewRelic::LanguageSupport.expects(:using_engine?).with('jruby').returns(false)
    self.expects(:using_sinatra?).returns(true)
    install_exit_handler
    NewRelic::LanguageSupport.expects(:using_engine?).with('rbx').returns(false)
    NewRelic::LanguageSupport.expects(:using_engine?).with('jruby').returns(true)
    install_exit_handler
    NewRelic::LanguageSupport.expects(:using_engine?).with('rbx').returns(true)
    install_exit_handler
  end

  def test_notify_log_file_location_positive
    log = mocked_log
    NewRelic::Control.instance.expects(:log_file).returns('./')
    log.expects(:send).with(:info, "Agent Log at ./")
    notify_log_file_location
  end

  def test_notify_log_file_location_negative
    log = mocked_log
    NewRelic::Control.instance.expects(:log_file).returns(nil)
    notify_log_file_location
  end

  def test_monitoring_positive
    control = mocked_control
    control.expects(:monitor_mode?).returns(true)
    log = mocked_log
    assert monitoring?
  end

  def test_monitoring_negative
    control = mocked_control
    log = mocked_log
    control.expects(:monitor_mode?).returns(false)
    log.expects(:send).with(:warn, "Agent configured not to send data in this environment - edit newrelic.yml to change this")
    assert !monitoring?
  end

  def test_has_license_key_positive
    control = mocked_control
    control.expects(:license_key).returns("a" * 40)
    assert has_license_key?
  end

  def test_has_license_key_negative
    control = mocked_control
    control.expects(:license_key).returns(nil)
    log = mocked_log
    log.expects(:send).with(:error, 'No license key found.  Please edit your newrelic.yml file and insert your license key.')
    assert !has_license_key?
  end

  def test_has_correct_license_key_positive
    self.expects(:has_license_key?).returns(true)
    self.expects(:correct_license_length).returns(true)
    assert has_correct_license_key?
  end

  def test_has_correct_license_key_negative
    self.expects(:has_license_key?).returns(false)
    assert !has_correct_license_key?
  end

  def test_correct_license_length_positive
    control = mocked_control
    control.expects(:license_key).returns("a" * 40)
    assert correct_license_length
  end

  def test_correct_license_length_negative
    control = mocked_control
    log = mocked_log
    control.expects(:license_key).returns("a"*30)
    log.expects(:send).with(:error, "Invalid license key: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    assert !correct_license_length
  end

  def test_using_forking_dispatcher_positive
    control = mocked_control
    control.expects(:dispatcher).returns(:passenger)
    log = mocked_log
    log.expects(:send).with(:info, "Connecting workers after forking.")
    assert using_forking_dispatcher?
  end

  def test_using_forking_dispatcher_negative
    control = mocked_control
    control.expects(:dispatcher).returns(:frobnitz)
    assert !using_forking_dispatcher?
  end

  def test_log_unless_positive
    # should not log
    assert log_unless(true, :warn, "DURRR")
  end
  def test_log_unless_negative
    # should log
    log = mocked_log
    log.expects(:send).with(:warn, "DURRR")
    assert !log_unless(false, :warn, "DURRR")
  end

  def test_log_if_positive
    log = mocked_log
    log.expects(:send).with(:warn, "WHEE")
    assert log_if(true, :warn, "WHEE")
  end

  def test_log_if_negative
    assert !log_if(false, :warn, "WHEE")
  end

  private

  def mocked_log
    fake_log = mock('log')
    self.stubs(:log).returns(fake_log)
    fake_log
  end


  def mocked_control
    fake_control = mock('control')
    self.stubs(:control).returns(fake_control)
    fake_control
  end
end

