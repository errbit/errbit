# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_err, class: "Errbit::Err" do
    association :problem, factory: :errbit_problem

    sequence(:fingerprint) { |n| "fingerprint-#{n}" }
  end
end
