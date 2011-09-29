# Override the 'hoptoad_notifier' gem's 'send_notice' method for internal errors.
# Find or create a 'Self.Errbit' app, and save the error internally
# unless errors should be sent to a different Errbit instance.

HoptoadNotifier.module_eval do
  class << self
    private
      def send_notice(notice)
        # Log the error internally if we are not in a development environment.
        if configuration.public?
          app = App.find_or_initialize_by(:name => "Self.Errbit")
          if app.new?
            app.github_url = "https://github.com/errbit/errbit.git"
            app.save!
          end
          notice.send("api_key=", app.api_key)

          # Create notice internally.
          report = ErrorReport.new(notice.to_xml)
          report.generate_notice!

          logger.info "Internal error was logged to 'Self.Errbit' app."
        end
      end
  end
end

