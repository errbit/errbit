# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_watcher, class: "Errbit::Watcher" do
    app factory: :errbit_app

    user factory: :errbit_user
  end
end
