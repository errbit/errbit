# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_issue_tracker, class: "Errbit::IssueTracker" do
    association :app, factory: :errbit_app

    type_tracker { "mock" }
    options { {foo: "one", bar: "two"} }
  end
end
