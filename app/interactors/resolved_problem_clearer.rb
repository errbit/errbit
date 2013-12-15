require 'problem_destroy'

class ResolvedProblemClearer

  ##
  # Clear all problem already resolved
  #
  def execute
    nb_problem_resolved.tap { |nb|
      if nb > 0
        criteria.each do |problem|
          ProblemDestroy.new(problem).execute
        end
      end
    }
  end

  private

  def nb_problem_resolved
    @count ||= criteria.count
  end

  def criteria
    @criteria = Problem.resolved
  end
end
