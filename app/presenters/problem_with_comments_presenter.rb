class ProblemWithCommentsPresenter < ProblemPresenter
  include MarkdownHelper
  
  def as_json(options={})
    problems.map(&method(:problem_as_json))
  end
  
  def problem_as_json(problem)
    super.merge({
      comments: problem.comments.map { |comment| {
        body: mdown(comment.body),
        userEmail: (comment.user.email if comment.user)
      }}
    })
  end
  
end
