# frozen_string_literal: true

FactoryBot.define do
  factory :app do
    name { Faker::App.unique.name }

    repository_branch { "main" }
  end
end
