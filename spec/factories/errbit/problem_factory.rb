# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_problem, class: "Errbit::Problem" do
    app factory: :errbit_app

    # comments { [] }

    error_class { "FooError" }

    environment { "production" }
  end
end
