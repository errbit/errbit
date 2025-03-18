# frozen_string_literal: true

class DestroyProblemsByIdJob < ActiveJob::Base
  queue_as :default

  def perform(problem_ids)
    bson_problem_ids = []
    problem_ids.each do |id|
      bson_problem_ids << BSON::ObjectId.from_string(id)
    end
    problems = Problem.find(bson_problem_ids).to_a
    ::ProblemDestroy.execute(problems)
  end
end
