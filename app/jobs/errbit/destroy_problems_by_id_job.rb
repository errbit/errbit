# frozen_string_literal: true

module Errbit
  class DestroyProblemsByIdJob < ApplicationJob
    queue_as :default

    # @param problem_ids [Array<Integer>]
    def perform(problem_ids)
      problems = Errbit::Problem.where(id: problem_ids).to_a

      Errbit::ProblemDestroy.execute(problems)
    end
  end
end
