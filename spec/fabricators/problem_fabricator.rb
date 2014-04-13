Fabricator(:problem) do
  app { Fabricate(:app) }
  comments { [] }
  error_class 'FooError'
  environment 'production'
end

Fabricator(:problem_with_err, :from => :problem) do
  after_create { |problem| Fabricate(:err, :problem => problem) }
end

Fabricator(:problem_with_comments, :from => :problem_with_err) do
  after_create do |problem|
    err = problem.errs.first
    3.times do
      Fabricate(:comment, :err => err)
    end
    problem.comments(true)
  end
end

Fabricator(:problem_with_errs, :from => :problem) do
  after_create do |problem|
    3.times do
      Fabricate(:err, :problem => problem)
    end
  end
end

Fabricator(:problem_resolved, :from => :problem) do
  after_create do |problem|
    Fabricate(:notice, :err => Fabricate(:err, :problem => problem))
    problem.resolve!
  end
end
