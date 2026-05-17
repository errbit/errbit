# frozen_string_literal: true

FactoryBot.define do
  factory :errbit_problem, class: "Errbit::Problem" do
    association :app, factory: :errbit_app

    environment { "production" }
    error_class { "RuntimeError" }
  end

  factory :errbit_problem_with_comments, parent: :errbit_problem do
    after(:create) do |problem|
      create_list(:errbit_comment, 3, err: problem)
    end
  end
end
