# frozen_string_literal: true

FactoryBot.define do
  factory :issue_tracker do
    app

    type_tracker { "mock" }

    options { {foo: "one", bar: "two"} }
  end
end
