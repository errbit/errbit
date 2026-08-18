# frozen_string_literal: true

RSpec.configure do |config|
  # Mongoid remains the runtime ORM while the SQL model layer is introduced.
  config.use_active_record = false if config.respond_to?(:use_active_record=)

  config.before(:suite) do
    ActiveRecord::Base.connection.disable_referential_integrity do
      load Rails.root.join("db/schema.rb")
    end
  end

  config.before do
    [
      Errbit::Comment,
      Errbit::Notice,
      Errbit::Err,
      Errbit::Problem,
      Errbit::Backtrace,
      Errbit::Watcher,
      Errbit::IssueTracker,
      Errbit::NotificationService,
      Errbit::NoticeFingerprinter,
      Errbit::App,
      Errbit::SiteConfig,
      Errbit::User
    ].each(&:delete_all)
  end
end
