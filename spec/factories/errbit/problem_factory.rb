# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_problem, class: "Errbit::Problem" do
    association :app, factory: :errbit_app
    error_class { "RuntimeError" }
    environment { "production" }
    message { "RuntimeError: boom" }
    where { "errors#show" }
  end
end
