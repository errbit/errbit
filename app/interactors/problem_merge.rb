require 'problem_destroy'

class ProblemMerge
  def initialize(*problems)
    problems = problems.flatten.uniq
    @merged_problem = problems[0]
    @child_problems = problems[1..-1]
    raise ArgumentError.new("need almost 2 uniq different problems") if @child_problems.empty?
  end
  attr_reader :merged_problem, :child_problems

  def merge
    child_problems.each do |problem|
      merged_problem.errs.concat Err.where(:problem_id => problem.id)
      ProblemDestroy.execute(problem)
    end
    reset_cached_attributes
    merged_problem
  end

  private

  def reset_cached_attributes
    ProblemUpdaterCache.new(merged_problem).update
  end
end
