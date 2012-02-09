# ENV['SKIP_RAILS'] = 'true'
require File.expand_path(File.join(File.dirname(__FILE__),'..', '..',
                                   'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','..','ui',
                                   'helpers','developer_mode_helper.rb'))

ENV['RACK_ENV'] = 'test'
class DeveloperModeTest < Test::Unit::TestCase
  include NewRelic::DeveloperModeHelper
  
  
  def test_application_caller
    assert_equal "/opt/ruby/lib/ruby/1.8/net/protocol.rb:135:in `rbuf_fill'", application_caller(Fixtures::NORMAL_TRACE)
    assert_equal "c:/Ruby192/lib/ruby/1.9.1/erb.rb:753:in `eval'", application_caller(Fixtures::WINDOWS_TRACE)
  end

  def test_application_stack_trace
    trace = application_stack_trace(Fixtures::NORMAL_TRACE)
    assert_equal 29, trace.size
    trace = application_stack_trace(Fixtures::WINDOWS_TRACE)
    assert_equal 14, trace.size
    
  end
  
  def test_url_for_source
    for line in Fixtures::NORMAL_TRACE + Fixtures::WINDOWS_TRACE do
      line = url_for_source(line)
      assert line =~ /^show_source\?file=.*&amp;line=\d+&amp;/, line
    end
  end
  
  private
  def params; {} end
  module Fixtures
    WINDOWS_TRACE = <<-EOF.split("\n")
newrelic_rpm (3.1.1) ui/helpers/developer_mode_helper.rb:234:in `file_and_line'
newrelic_rpm (3.1.1) ui/helpers/developer_mode_helper.rb:30:in `block in application_caller'
newrelic_rpm (3.1.1) ui/helpers/developer_mode_helper.rb:29:in `each'
newrelic_rpm (3.1.1) ui/helpers/developer_mode_helper.rb:29:in `application_caller'
newrelic_rpm (3.1.1) ui/helpers/developer_mode_helper.rb:111:in `link_to_source'
(erb):5:in `render'
c:/Ruby192/lib/ruby/1.9.1/erb.rb:753:in `eval'
c:/Ruby192/lib/ruby/1.9.1/erb.rb:753:in `result'
newrelic_rpm (3.1.1) lib/new_relic/rack/developer_mode.rb:155:in `render_without_layout'
newrelic_rpm (3.1.1) lib/new_relic/rack/developer_mode.rb:136:in `render'
newrelic_rpm (3.1.1) lib/new_relic/rack/developer_mode.rb:121:in `block in render'
newrelic_rpm (3.1.1) lib/new_relic/rack/developer_mode.rb:120:in `map'
newrelic_rpm (3.1.1) lib/new_relic/rack/developer_mode.rb:120:in `render'
(erb):22:in `render'
c:/Ruby192/lib/ruby/1.9.1/erb.rb:753:in `eval'
c:/Ruby192/lib/ruby/1.9.1/erb.rb:753:in `result'
newrelic_rpm (3.1.1) lib/new_relic/rack/developer_mode.rb:155:in `render_without_layout'
newrelic_rpm (3.1.1) lib/new_relic/rack/developer_mode.rb:136:in `render'
(erb):77:in `block in render'
(erb):74:in `collect'
(erb):74:in `render'
c:/Ruby192/lib/ruby/1.9.1/erb.rb:753:in `eval'
c:/Ruby192/lib/ruby/1.9.1/erb.rb:753:in `result'
newrelic_rpm (3.1.1) lib/new_relic/rack/developer_mode.rb:155:in `render_without_layout'
newrelic_rpm (3.1.1) lib/new_relic/rack/developer_mode.rb:133:in `block in render'
(erb):38:in `render_with_layout'
c:/Ruby192/lib/ruby/1.9.1/erb.rb:753:in `eval'
c:/Ruby192/lib/ruby/1.9.1/erb.rb:753:in `result'
newrelic_rpm (3.1.1) lib/new_relic/rack/developer_mode.rb:149:in `render_with_layout'
newrelic_rpm (3.1.1) lib/new_relic/rack/developer_mode.rb:132:in `render'
newrelic_rpm (3.1.1) lib/new_relic/rack/developer_mode.rb:232:in `show_sample_data'
newrelic_rpm (3.1.1) lib/new_relic/rack/developer_mode.rb:47:in `_call'
newrelic_rpm (3.1.1) lib/new_relic/rack/developer_mode.rb:25:in `call'
warden (1.0.5) lib/warden/manager.rb:35:in `block in call'
warden (1.0.5) lib/warden/manager.rb:34:in `catch'
warden (1.0.5) lib/warden/manager.rb:34:in `call'
actionpack (3.0.9) lib/action_dispatch/middleware/best_standards_support.rb:17:in `call'
actionpack (3.0.9) lib/action_dispatch/middleware/head.rb:14:in `call'
rack (1.2.3) lib/rack/methodoverride.rb:24:in `call'
actionpack (3.0.9) lib/action_dispatch/middleware/params_parser.rb:21:in `call'
actionpack (3.0.9) lib/action_dispatch/middleware/flash.rb:182:in `call'
actionpack (3.0.9) lib/action_dispatch/middleware/session/abstract_store.rb:149:in `call'
actionpack (3.0.9) lib/action_dispatch/middleware/cookies.rb:302:in `call'
activerecord (3.0.9) lib/active_record/query_cache.rb:32:in `block in call'
activerecord (3.0.9) lib/active_record/connection_adapters/abstract/query_cache.rb:28:in `cache'
activerecord (3.0.9) lib/active_record/query_cache.rb:12:in `cache'
activerecord (3.0.9) lib/active_record/query_cache.rb:31:in `call'
activerecord (3.0.9) lib/active_record/connection_adapters/abstract/connection_pool.rb:354:in `call'
actionpack (3.0.9) lib/action_dispatch/middleware/callbacks.rb:46:in `block in call'
activesupport (3.0.9) lib/active_support/callbacks.rb:416:in `_run_call_callbacks'
actionpack (3.0.9) lib/action_dispatch/middleware/callbacks.rb:44:in `call'
rack (1.2.3) lib/rack/sendfile.rb:107:in `call'
actionpack (3.0.9) lib/action_dispatch/middleware/remote_ip.rb:48:in `call'
actionpack (3.0.9) lib/action_dispatch/middleware/show_exceptions.rb:47:in `call'
railties (3.0.9) lib/rails/rack/logger.rb:13:in `call'
rack (1.2.3) lib/rack/runtime.rb:17:in `call'
activesupport (3.0.9) lib/active_support/cache/strategy/local_cache.rb:72:in `call'
rack (1.2.3) lib/rack/lock.rb:11:in `block in call'
<internal:prelude>:10:in `synchronize'
rack (1.2.3) lib/rack/lock.rb:11:in `call'
actionpack (3.0.9) lib/action_dispatch/middleware/static.rb:30:in `call'
railties (3.0.9) lib/rails/application.rb:168:in `call'
railties (3.0.9) lib/rails/application.rb:77:in `method_missing'
railties (3.0.9) lib/rails/rack/log_tailer.rb:14:in `call'
rack (1.2.3) lib/rack/content_length.rb:13:in `call'
rack (1.2.3) lib/rack/handler/webrick.rb:52:in `service'
c:/Ruby192/lib/ruby/1.9.1/webrick/httpserver.rb:111:in `service'
c:/Ruby192/lib/ruby/1.9.1/webrick/httpserver.rb:70:in `run'
c:/Ruby192/lib/ruby/1.9.1/webrick/server.rb:183:in `block in start_thread'  
  EOF
    
    NORMAL_TRACE = <<-EOF.split("\n")
/opt/ruby/lib/ruby/1.8/net/protocol.rb:135:in `rbuf_fill'
/opt/ruby/lib/ruby/1.8/timeout.rb:101:in `timeout'
/opt/ruby/lib/ruby/1.8/net/protocol.rb:126:in `readline'
/opt/ruby/lib/ruby/1.8/net/http.rb:2028:in `read_status_line'
/opt/ruby/lib/ruby/1.8/net/http.rb:1051:in `request_without_newrelic_trace'
/opt/bundler/gems/ruby_agent-705a7cf29207/lib/new_relic/agent/instrumentation/net.rb:20:in `request_without_fakeweb'
/opt/bundler/gems/ruby_agent-705a7cf29207/lib/new_relic/agent/method_tracer.rb:242:in `trace_execution_scoped'
/opt/bundler/gems/ruby_agent-705a7cf29207/lib/new_relic/agent/instrumentation/net.rb:19:in `request_without_fakeweb'
/opt/ruby/gems/fakeweb-1.3.0/lib/fake_web/ext/net_http.rb:50:in `request'
/opt/ruby/lib/ruby/1.8/net/http.rb:1037:in `request_without_newrelic_trace'
/opt/ruby/lib/ruby/1.8/net/http.rb:543:in `start'
/opt/ruby/lib/ruby/1.8/net/http.rb:1035:in `request_without_newrelic_trace'
/opt/bundler/gems/ruby_agent-705a7cf29207/lib/new_relic/agent/instrumentation/net.rb:20:in `request_without_fakeweb'
/opt/bundler/gems/ruby_agent-705a7cf29207/lib/new_relic/agent/method_tracer.rb:242:in `trace_execution_scoped'
/opt/bundler/gems/ruby_agent-705a7cf29207/lib/new_relic/agent/instrumentation/net.rb:19:in `request_without_fakeweb'
/opt/ruby/gems/fakeweb-1.3.0/lib/fake_web/ext/net_http.rb:50:in `request'
/opt/ruby/lib/ruby/1.8/net/http.rb:992:in `post2'
/opt/ruby/gems/rforce-0.4.1/lib/rforce/binding.rb:141:in `call_remote'
/opt/ruby/gems/rforce-0.4.1/lib/rforce/binding.rb:208:in `method_missing'
/Users/joe/dev/workspace/lib/lead_lover/base.rb:135:in `update'
/Users/joe/dev/workspace/lib/lead_lover/base.rb:123:in `update_filtered_attributes'
/Users/joe/dev/workspace/lib/lead_lover/lead.rb:62:in `assign_to_owner'
/Users/joe/dev/workspace/app/models/account.rb:1968:in `link_to_leadlover_lead'
/Users/joe/dev/workspace/app/models/account.rb:1956:in `link_to_leadlover'
/opt/ruby/gems/activerecord-2.3.14/lib/active_record/associations/association_proxy.rb:215:in `send'
/opt/ruby/gems/activerecord-2.3.14/lib/active_record/associations/association_proxy.rb:215:in `method_missing'
/Users/joe/dev/workspace/app/models/subscription.rb:883:in `link_to_leadlover'
/opt/ruby/gems/delayed_job-2.0.6/lib/delayed/performable_method.rb:35:in `send'
/opt/ruby/gems/delayed_job-2.0.6/lib/delayed/performable_method.rb:35:in `perform'
/Users/joe/dev/workspace/config/initializers/delayed_job_with_shards.rb:17:in `perform'
/opt/ruby/gems/delayed_job-2.0.6/lib/delayed/backend/base.rb:74:in `invoke_job'
  EOF
  end  
end
