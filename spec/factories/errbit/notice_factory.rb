# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_notice, class: "Errbit::Notice" do
    association :app, factory: :errbit_app
    association :err, factory: :errbit_err
    association :backtrace, factory: :errbit_backtrace

    error_class { "FooError" }
    message { "FooError: Too Much Bar" }

    server_environment { {"environment-name" => "production"} }
    request { {"component" => "foo", "action" => "bar"} }
    notifier { {"name" => "Notifier", "version" => "1", "url" => "http://toad.com"} }
  end
end
