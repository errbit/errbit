# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_comment, class: "Errbit::Comment" do
    association :err, factory: :errbit_problem
    association :user, factory: :errbit_user
    body { "Looks broken" }
  end
end
