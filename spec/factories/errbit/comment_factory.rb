# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_comment, class: "Errbit::Comment" do
    association :user, factory: :errbit_user
    association :err, factory: :errbit_problem

    body { "Test comment" }
  end
end
