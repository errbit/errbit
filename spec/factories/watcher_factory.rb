# frozen_string_literal: true

FactoryBot.define do
  factory :watcher do
    app

    watcher_type { "email" }

    sequence(:email) { |n| "email#{n}@example.com" }
  end

  factory :user_watcher, parent: :watcher do
    user

    watcher_type { "user" }
  end
end
