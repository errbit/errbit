# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_notice, class: "Errbit::Notice" do
    association :app, factory: :errbit_app
    association :err, factory: :errbit_err
    association :backtrace, factory: :errbit_backtrace
    message { "RuntimeError: boom" }
    server_environment { {"environment-name" => "production"} }
    request { {"url" => "https://example.com/errors", "component" => "errors", "action" => "show", "cgi-data" => {"HTTP_USER_AGENT" => "Firefox"}} }
    notifier { {"name" => "rspec"} }
    framework { "rails" }
    error_class { "RuntimeError" }

    after(:build) do |notice|
      notice.app = notice.err.app if notice.err && notice.app != notice.err.app
    end
  end
end
