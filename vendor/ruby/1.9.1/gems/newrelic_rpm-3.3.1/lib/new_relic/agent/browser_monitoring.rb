require 'base64'
require 'new_relic/agent/beacon_configuration'
module NewRelic
  module Agent
    # This module contains support for Real User Monitoring - the
    # javascript generation and configuration
    module BrowserMonitoring
      
     
      class DummyMetricFrame
        def initialize
          @attributes = {}
        end
        
        def user_attributes
          @attributes
        end
        
        def queue_time
          0.0
        end
      end
            
      @@dummy_metric_frame = DummyMetricFrame.new
      
      
      # This method returns a string suitable for inclusion in a page
      # - known as 'manual instrumentation' for Real User
      # Monitoring. Can return either a script tag with associated
      # javascript, or in the case of disabled Real User Monitoring,
      # an empty string
      #
      # This is the header string - it should be placed as high in the
      # page as is reasonably possible - that is, before any style or
      # javascript inclusions, but after any header-related meta tags
      def browser_timing_header
        return "" if NewRelic::Agent.instance.beacon_configuration.nil?
        return "" if !NewRelic::Agent.is_transaction_traced? || !NewRelic::Agent.is_execution_traced?

        NewRelic::Agent.instance.beacon_configuration.browser_timing_header
      end

      # This method returns a string suitable for inclusion in a page
      # - known as 'manual instrumentation' for Real User
      # Monitoring. Can return either a script tag with associated
      # javascript, or in the case of disabled Real User Monitoring,
      # an empty string
      #
      # This is the footer string - it should be placed as low in the
      # page as is reasonably possible.
      def browser_timing_footer
        config = NewRelic::Agent.instance.beacon_configuration
        return "" if config.nil? || !config.rum_enabled || config.browser_monitoring_key.nil?
        return "" if !NewRelic::Agent.is_transaction_traced? || !NewRelic::Agent.is_execution_traced?
        generate_footer_js(config)
      end

      private

      def generate_footer_js(config)
        if browser_monitoring_start_time
          application_id = config.application_id
          beacon = config.beacon
          license_key = config.browser_monitoring_key

          footer_js_string(config, beacon, license_key, application_id)
        else
          ''
        end
      end

      def browser_monitoring_transaction_name
        NewRelic::Agent::TransactionInfo.get.transaction_name
      end

      def browser_monitoring_start_time
        NewRelic::Agent::TransactionInfo.get.start_time
      end
            
      def metric_frame_attribute(key)
        current_metric_frame.user_attributes[key] || ""
      end
      
      def current_metric_frame
        Thread.current[:last_metric_frame] || @@dummy_metric_frame      
      end
      
      def tt_guid
        txn = NewRelic::Agent::TransactionInfo.get
        return txn.guid if txn.include_guid?
        ""
      end
      
      def tt_token
        return NewRelic::Agent::TransactionInfo.get.token
      end
      
      def clamp_to_positive(value)
        return 0.0 if value < 0
        value
      end

      def browser_monitoring_app_time
        clamp_to_positive(((Time.now - browser_monitoring_start_time).to_f * 1000.0).round)
      end

      def browser_monitoring_queue_time
        clamp_to_positive((current_metric_frame.queue_time.to_f * 1000.0).round)
      end

      def footer_js_string(config, beacon, license_key, application_id)
        obfuscated_transaction_name = obfuscate(config, browser_monitoring_transaction_name)
        
        user = obfuscate(config, metric_frame_attribute(:user))
        account = obfuscate(config, metric_frame_attribute(:account))
        product = obfuscate(config, metric_frame_attribute(:product))
        
        html_safe_if_needed("<script type=\"text/javascript\">#{config.browser_timing_static_footer}NREUMQ.push([\"#{config.finish_command}\",\"#{beacon}\",\"#{license_key}\",#{application_id},\"#{obfuscated_transaction_name}\",#{browser_monitoring_queue_time},#{browser_monitoring_app_time},new Date().getTime(),\"#{tt_guid}\",\"#{tt_token}\",\"#{user}\",\"#{account}\",\"#{product}\"])</script>")
      end

      def html_safe_if_needed(string)
        if string.respond_to?(:html_safe)
          string.html_safe
        else
          string
        end
      end

      def obfuscate(config, text)
        obfuscated = ""
        key_bytes = config.license_bytes
        index = 0
        text.each_byte{|byte|
          obfuscated.concat((byte ^ key_bytes[index % 13].to_i))
          index+=1
        }

        [obfuscated].pack("m0").gsub("\n", '')
      end
    end
  end
end
