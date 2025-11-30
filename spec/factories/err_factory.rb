# frozen_string_literal: true

FactoryBot.define do
  factory :err do
    problem

    fingerprint { "some-finger-print" }
  end
end
