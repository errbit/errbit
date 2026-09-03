# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_user, class: "Errbit::User" do
    sequence(:email) { |n| "sql-user-#{n}@example.com" }
    name { "SQL User" }
    password { "password" }
  end
end
