# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_watcher, class: "Errbit::Watcher" do
    association :app, factory: :errbit_app
    email { "watcher@example.com" }
    watcher_type { "email" }
  end
end
