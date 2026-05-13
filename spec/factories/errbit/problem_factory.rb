# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_problem, class: "Errbit::Problem" do
    association :app, factory: :errbit_app

    environment { "production" }
    error_class { "RuntimeError" }
  end
end
