# frozen_string_literal: true

FactoryBot.define do
  factory :problem do
    app

    comments { [] }

    error_class { "FooError" }

    environment { "production" }
  end

  factory :problem_with_comments, parent: :problem do
    after(:build) do |problem|
      create_list(:comment, 3, err: problem)
    end
  end
end
