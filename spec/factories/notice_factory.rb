# frozen_string_literal: true

FactoryBot.define do
  factory :notice do
    app

    err

    error_class { "FooError" }

    message { "FooError: Too Much Bar" }

    backtrace

    server_environment { {"environment-name" => "production"} }

    request { {"component" => "foo", "action" => "bar"} }

    notifier { {"name" => "Notifier", "version" => "1", "url" => "http://toad.com"} }

    after(:create) do |notice|
      Problem.cache_notice(notice.err.problem_id, notice)

      notice.problem.reload
    end
  end
end
