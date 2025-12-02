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
      build_list(:comment, 3, err: problem)
    end
  end

  factory :problem_with_errs, parent: :problem do
    after(:build) do |problem|
      build_list(:err, 3, problem: problem)
    end
  end

  # factory :problem_resolved, parent: :problem do
  #
  # end

  # Fabricator(:problem_resolved, from: :problem) do
  #   after_create do |pr|
  #     Fabricate(:notice, err: Fabricate(:err, problem: pr))
  #
  #     pr.resolve!
  #   end
  # end
end
