# require this in your env.rb file after you require cucumber/rails/world

# Global Setup
if defined?(ActionMailer)
  unless [:test, :activerecord, :cache, :file].include?(ActionMailer::Base.delivery_method)
    ActionMailer::Base.register_observer(EmailSpec::TestObserver)
  end
  ActionMailer::Base.perform_deliveries = true

  Before do
    # Scenario setup
    case ActionMailer::Base.delivery_method
      when :test then ActionMailer::Base.deliveries.clear
      when :cache then ActionMailer::Base.clear_cache
    end
  end
end

After do
  EmailSpec::EmailViewer.save_and_open_all_raw_emails if ENV['SHOW_EMAILS']
  EmailSpec::EmailViewer.save_and_open_all_html_emails if ENV['SHOW_HTML_EMAILS']
  EmailSpec::EmailViewer.save_and_open_all_text_emails if ENV['SHOW_TEXT_EMAILS']
end

World(EmailSpec::Helpers)
World(EmailSpec::Matchers)
