# frozen_string_literal: true

FactoryBot.define do
  factory :app do
    sequence(:name) { |n| "App ##{n}" }

    repository_branch { ["main", "master"].sample }
  end
end
