# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }

    name { Faker::Name.unique.name }
  end
end
