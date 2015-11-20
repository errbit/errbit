require 'problem_destroy'

class ProblemMerge
  def initialize(*problems)
    problems = problems.flatten.uniq
    @merged_problem = problems[0]
    @child_problems = problems[1..-1]
    fail ArgumentError, "need almost 2 uniq different problems" if @child_problems.empty?
  end
  attr_reader :merged_problem, :child_problems

  def merge
    child_problems.each do |problem|
      merged_problem.errs.concat problem.errs
      merged_problem.comments.concat problem.comments
      problem.reload # deference all associate objet to avoid delete him after
      ProblemDestroy.execute(problem)
    end
    merged_problem.recache
    merged_problem
  end
end
