# frozen_string_literal: true

FactoryBot.define do
  factory :problem do
    app

    comments { [] }

    error_class { "FooError" }

    environment { "production" }
  end

  factory :problem_with_comments, parent: :problem do
    after(:create) do |problem|
      create_list(:comment, 3, err: problem)
    end
  end

  factory :problem_with_errs, parent: :problem do
    after(:create) do |problem|
      create_list(:err, 3, problem: problem)
    end
  end

  factory :problem_resolved, parent: :problem do
    after(:create) do |problem|
      err = create(:err, problem: problem)

      create(:notice, err: err)

      problem.resolve!
    end
  end
end
