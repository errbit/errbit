class ProblemWithDeletedPresenter < ProblemPresenter

  def as_json(options={})
    problems.map(&method(:problem_as_json))
  end

  def problem_as_json(problem)
    super.merge({
      deleted_at: problem.deleted_at
    })
  end

end
