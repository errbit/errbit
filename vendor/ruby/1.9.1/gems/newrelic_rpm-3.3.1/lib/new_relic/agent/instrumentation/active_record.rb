module NewRelic
  module Agent
    module Instrumentation
      module ActiveRecord
        def self.included(instrumented_class)
          instrumented_class.class_eval do
            unless instrumented_class.method_defined?(:log_without_newrelic_instrumentation)
              alias_method :log_without_newrelic_instrumentation, :log
              alias_method :log, :log_with_newrelic_instrumentation
              protected :log
            end
          end
        end
                
        def log_with_newrelic_instrumentation(*args, &block)
          if !NewRelic::Agent.is_execution_traced?
            return log_without_newrelic_instrumentation(*args, &block)
          end
          
          sql, name, binds = args
          metric = metric_for_name(name) || metric_for_sql(sql)
          
          if !metric
            log_without_newrelic_instrumentation(*args, &block)
          else
            metrics = [metric, remote_service_metric].compact
            metrics += rollup_metrics_for(metric)
            self.class.trace_execution_scoped(metrics) do
              t0 = Time.now
              begin
                log_without_newrelic_instrumentation(*args, &block)
              ensure
                elapsed_time = (Time.now - t0).to_f
                NewRelic::Agent.instance.transaction_sampler.notice_sql(sql,
                                                         @config, elapsed_time)
                NewRelic::Agent.instance.sql_sampler.notice_sql(sql, metric,
                                                         @config, elapsed_time)
              end
            end
          end
        end
        
        def remote_service_metric
          if @config && @config[:adapter]
            type = @config[:adapter].sub(/\d*/, '')
            host = @config[:host] || 'localhost'
            "RemoteService/sql/#{type}/#{host}"
          end                      
        end
        
        def metric_for_name(name)
          if name && (parts = name.split " ") && parts.size == 2
            model = parts.first
            operation = parts.last.downcase
            op_name = case operation
                          when 'load', 'count', 'exists' then 'find'
                          when 'indexes', 'columns' then nil # fall back to DirectSQL
                          when 'destroy', 'find', 'save', 'create' then operation
                          when 'update' then 'save'
                          else
                            if model == 'Join'
                              operation
                            end
                          end
            "ActiveRecord/#{model}/#{op_name}" if op_name
          end
        end

        def metric_for_sql(sql)
          metric = NewRelic::Agent::Instrumentation::MetricFrame.database_metric_name
          if metric.nil?
            if sql =~ /^(select|update|insert|delete|show)/i
              # Could not determine the model/operation so let's find a better
              # metric.  If it doesn't match the regex, it's probably a show
              # command or some DDL which we'll ignore.
              metric = "Database/SQL/#{$1.downcase}"
            else
              metric = "Database/SQL/other"
            end
          end
          metric
        end
        
        def rollup_metrics_for(metric)
          metrics = ["ActiveRecord/all"]
          metrics << "ActiveRecord/#{$1}" if metric =~ /ActiveRecord\/\w+\/(\w+)/
          metrics
        end
      end
    end
  end
end

DependencyDetection.defer do
  @name = :active_record
  
  depends_on do
    defined?(ActiveRecord) && defined?(ActiveRecord::Base)
  end

  depends_on do
    !NewRelic::Control.instance['skip_ar_instrumentation']
  end

  depends_on do
    !NewRelic::Control.instance['disable_activerecord_instrumentation']
  end
  
  executes do
    NewRelic::Agent.logger.debug 'Installing ActiveRecord instrumentation'
  end
  
  executes do
    if defined?(::Rails) && ::Rails::VERSION::MAJOR.to_i == 3
      Rails.configuration.after_initialize do
        insert_instrumentation
      end
    else
      insert_instrumentation
    end
  end

  def insert_instrumentation
    ActiveRecord::ConnectionAdapters::AbstractAdapter.module_eval do
      include ::NewRelic::Agent::Instrumentation::ActiveRecord
    end
    
    ActiveRecord::Base.class_eval do
      class << self
        add_method_tracer(:find_by_sql, 'ActiveRecord/#{self.name}/find_by_sql',
                          :metric => false)
        add_method_tracer(:transaction, 'ActiveRecord/#{self.name}/transaction',
                          :metric => false)
      end
    end          
  end
end
