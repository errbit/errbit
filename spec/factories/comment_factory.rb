# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    user

    body { "Test comment" }

    err factory: :problem
  end
end
