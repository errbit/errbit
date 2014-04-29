class ProblemWithCommentsPresenter < ProblemPresenter
  
  def problem_as_json(problem)
    super.merge({
      comments: problem.comments.map { |comment| {
        body: comment.body,
        userEmail: (comment.user.email if comment.user)
      }}
    })
  end
  
end
