# Override the 'hoptoad_notifier' gem's 'send_notice' method for internal errors.
# Find or create a 'Self.Errbit' app, and save the error internally
# unless errors should be sent to a different Errbit instance.

HoptoadNotifier.module_eval do
  class << self
    private
      def send_notice_with_internal(notice)
        if Errbit::Config.report_self_errors.to_s == "true"
          # Using the original method, send notice to a different Errbit instance.
          send_notice_without_internal(notice)
        else
          # Otherwise, if we are not in a development environment, log the error internally.
          if configuration.public?
            begin
              app = App.find_or_initialize_by(:name => "Self.Errbit")
              if app.new?
                app.github_url = "https://github.com/errbit/errbit.git"
                app.save!
              end
              notice.send("api_key=", app.api_key)
              # Create notice internally.
              # 'to_xml ~> from_xml' provides a data bridge between hoptoad_notifier and Errbit.
              ::Notice.from_xml(notice.to_xml)
              logger.info "Internal error was logged to 'Self.Errbit' app."
            rescue
              logger.error "-- Errbit crashed while processing an internal error!" if logger
            end
          end
        end
      end
      alias_method_chain :send_notice, :internal
  end
end

