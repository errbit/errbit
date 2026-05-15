# frozen_string_literal: true

module Errbit
  class ResolvedProblemClearer
    ##
    # Clear all problems that have been resolved.
    #
    def execute
      nb_problem_resolved.tap do |nb|
        if nb > 0
          criteria.each do |problem|
            Errbit::ProblemDestroy.new(problem).execute
          end
        end
      end
    end

    private

    def nb_problem_resolved
      @count ||= criteria.count
    end

    def criteria
      @criteria ||= Errbit::Problem.resolved
    end
  end
end
