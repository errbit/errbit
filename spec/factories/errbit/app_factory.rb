# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_app, class: "Errbit::App" do
    name { Faker::App.unique.name }

    repository_branch { ["main", "master"].sample }
  end
end
