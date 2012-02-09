require 'new_relic/agent/instrumentation/controller_instrumentation'

DependencyDetection.defer do
  @name = :delayed_job
  
  depends_on do
    !NewRelic::Control.instance['disable_dj']
  end

  depends_on do
    # double check because of old JRuby bug 
    defined?(::Delayed) && defined?(::Delayed::Job) &&
      Delayed::Job.method_defined?(:invoke_job)
  end
  
  executes do
    NewRelic::Agent.logger.debug 'Installing DelayedJob instrumentation'
  end
  
  executes do
    Delayed::Job.class_eval do
      include NewRelic::Agent::Instrumentation::ControllerInstrumentation
      if self.instance_methods.include?('name') || self.instance_methods.include?(:name)
        add_transaction_tracer "invoke_job", :category => 'OtherTransaction/DelayedJob', :path => '#{self.name}'
      else
        add_transaction_tracer "invoke_job", :category => 'OtherTransaction/DelayedJob'
      end
    end
  end

  executes do
    Delayed::Job.instance_eval do
      if self.respond_to?('after_fork')
        if method_defined?(:after_fork)
          def after_fork_with_newrelic
            NewRelic::Agent.after_fork(:force_reconnect => true)
            after_fork_without_newrelic
          end

          alias_method :after_fork_without_newrelic, :after_fork
          alias_method :after_fork, :after_fork_with_newrelic
        else
          def after_fork
            NewRelic::Agent.after_fork(:force_reconnect => true)
            super
          end
        end
      end
    end
  end
end

