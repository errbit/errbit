# frozen_string_literal: true

# Override the 'hoptoad_notifier' gem's 'send_notice' method for internal errors.
# Find or create a 'Self.Errbit' app, and save the error internally
# unless errors should be sent to a different Errbit instance.
HoptoadNotifier.module_eval do
  class << self
    private def send_notice(notice)
      # Log the error internally if we are not in a development environment.
      return unless configuration.public?

      app = App.find_or_initialize_by(name: "Self.Errbit")
      app.github_repo = "errbit/errbit"
      app.save!
      notice.send("api_key=", app.api_key)

      # Create notice internally.
      report = ErrorReport.new(notice.to_xml)
      report.generate_notice!

      logger.info "Internal error was logged to 'Self.Errbit' app."
    end
  end
end

HoptoadNotifier.configure do |config|
  # Internal Errbit errors are stored locally, but we need
  # to set a dummy API key so that HoptoadNotifier doesn't complain.
  config.api_key = "---------"

  # Don't log error that causes 404 page
  config.ignore << "Mongoid::Errors::DocumentNotFound"
end
