# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_watcher, class: "Errbit::Watcher" do
    association :app, factory: :errbit_app

    watcher_type { "email" }

    sequence(:email) { |n| "email#{n}@example.com" }
  end

  factory :errbit_user_watcher, parent: :errbit_watcher do
    association :user, factory: :errbit_user

    watcher_type { "user" }
  end
end
