class ProblemWithCommentsPresenter < ProblemPresenter
  
  def as_json(options={})
    problems.map(&method(:problem_as_json))
  end
  
  def problem_as_json(problem)
    super.merge({
      comments: problem.comments.map { |comment| {
        body: comment.body,
        userEmail: (comment.user.email if comment.user)
      }}
    })
  end
  
end
