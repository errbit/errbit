# frozen_string_literal: true

FactoryBot.define do
  factory :app do
    sequence(:name) { |n| "App ##{n}" }

    repository_branch { ["main", "master"].sample }
  end

  factory :app_with_watcher, parent: :app do
    after(:build) do |app|
      build(:watcher, app: app)
    end
  end
end
