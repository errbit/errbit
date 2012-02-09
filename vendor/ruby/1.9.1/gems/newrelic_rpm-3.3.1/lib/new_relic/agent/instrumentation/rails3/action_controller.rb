module NewRelic
  module Agent
    module Instrumentation
      module Rails3
        module ActionController
          def self.newrelic_write_attr(attr_name, value) # :nodoc:
            write_inheritable_attribute(attr_name, value)
          end

          def self.newrelic_read_attr(attr_name) # :nodoc:
            read_inheritable_attribute(attr_name)
          end

          # determine the path that is used in the metric name for
          # the called controller action
          def newrelic_metric_path(action_name_override = nil)
            action_part = action_name_override || action_name
            if action_name_override || self.class.action_methods.include?(action_part)
              "#{self.class.controller_path}/#{action_part}"
            else
              "#{self.class.controller_path}/(other)"
            end
          end

          def process_action(*args)
            # skip instrumentation if we are in an ignored action
            if _is_filtered?('do_not_trace')
              NewRelic::Agent.disable_all_tracing do
                return super
              end
            end

            perform_action_with_newrelic_trace(:category => :controller, :name => self.action_name, :path => newrelic_metric_path, :params => request.filtered_parameters, :class_name => self.class.name)  do
              super
            end
          end

        end

        module ActionView
          def _render_template(template, layout = nil, options = {}) #:nodoc:
            NewRelic::Agent.trace_execution_scoped "View/#{template.virtual_path}/Rendering" do
              super
            end
          end

          module PartialRenderer
          end
        end
      end
    end
  end
end

DependencyDetection.defer do
  @name = :rails3_controller
  
  depends_on do
    defined?(::Rails) && ::Rails::VERSION::MAJOR.to_i == 3
  end

  depends_on do
    defined?(ActionController) && defined?(ActionController::Base)
  end

  executes do
    NewRelic::Agent.logger.debug 'Installing Rails 3 Controller instrumentation'
  end  
  
  executes do
    class ActionController::Base
      include NewRelic::Agent::Instrumentation::ControllerInstrumentation
      include NewRelic::Agent::Instrumentation::Rails3::ActionController
    end
  end
end

DependencyDetection.defer do
  @name = :rails3_view
  
  depends_on do
    defined?(ActionView) && defined?(ActionView::Base) && defined?(ActionView::Partials)
  end

  depends_on do
    defined?(::Rails) && ::Rails::VERSION::MAJOR.to_i == 3 && ::Rails::VERSION::MINOR.to_i >= 1
  end

  depends_on do
    !NewRelic::Control.instance['disable_view_instrumentation']
  end
  
  executes do
    NewRelic::Agent.logger.debug 'Installing Rails 3 view instrumentation'
  end
  
  executes do
    class ActionView::Base
      include NewRelic::Agent::Instrumentation::Rails3::ActionView
    end
    old_klass = ActionView::Partials::PartialRenderer
    ActionView::Partials::PartialRenderer = Class.new(old_klass)
    class ActionView::Partials::PartialRenderer
      def render_partial(*args)
        NewRelic::Agent.trace_execution_scoped "View/#{@template.virtual_path}/Partial" do
          super
        end
      end

      def render_collection(*args)
        name = @template ? @template.virtual_path : "Mixed"
        NewRelic::Agent.trace_execution_scoped "View/#{name}/Collection" do
          super
        end
      end
    end
  end
end
