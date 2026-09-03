# frozen_string_literal: true

module Errbit
  class ProblemMerge
    attr_reader :merged_problem, :child_problems

    def initialize(*problems)
      problems = problems.flatten.uniq
      @merged_problem = problems[0]
      @child_problems = problems[1..]
      fail ArgumentError, "need almost 2 uniq different problems" if @child_problems.empty?
    end

    def merge
      child_problems.each do |problem|
        problem.errs.update_all(errbit_problem_id: merged_problem.id)
        problem.comments.update_all(errbit_problem_id: merged_problem.id)
        problem.reload
        Errbit::ProblemDestroy.execute(problem)
      end

      actual_comments = Errbit::Comment.where(errbit_problem_id: merged_problem.id).count
      merged_problem.update_column(:comments_count, actual_comments)
      merged_problem.errs.reset
      merged_problem.comments.reset
      merged_problem.recache
      merged_problem
    end
  end
end
