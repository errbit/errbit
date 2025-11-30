# frozen_string_literal: true

FactoryBot.define do
  factory :problem do
    app

    comments { [] }

    error_class { "FooError" }

    environment { "production" }
  end
end
