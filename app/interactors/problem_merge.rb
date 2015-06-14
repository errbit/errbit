class ProblemMerge
  attr_reader :problems, :merged_problem, :child_problems

  def initialize(*problems)
    @problems = problems.flatten.uniq.sort_by(&:opened_at)
    @merged_problem = @problems[0]
    @child_problems = @problems[1..-1]
    raise ArgumentError.new("need almost 2 uniq different problems") if @child_problems.empty?
  end

  def merge
    child_problems.each do |problem|
      merged_problem.errs.concat problem.errs
      problem.reload # deference all associate objet to avoid delete him after
      ProblemDestroy.execute(problem)
    end
    attributes = {}
    attributes[:resolved] = false unless @problems.all?(&:resolved?)
    merged_problem.update_attributes(attributes)
    reset_cached_attributes
    merged_problem
  end

private

  def reset_cached_attributes
    ProblemUpdaterCache.new(merged_problem).update
  end

end
