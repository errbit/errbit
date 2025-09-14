# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_user, class: "Errbit::User" do
    email { Faker::Internet.unique.email }

    name { Faker::Name.unique.name }

    password { Faker::Internet.password }

    admin { [true, false].sample }
  end
end
