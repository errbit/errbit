# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_app, class: "Errbit::App" do
    sequence(:name) { |n| "SQL App ##{n}" }
    repository_branch { "main" }
  end
end
