# frozen_string_literal: true

class ResolvedProblemClearer
  ##
  # Clear all problem already resolved
  #
  def execute
    nb_problem_resolved.tap do |nb|
      if nb > 0
        criteria.each do |problem|
          ProblemDestroy.new(problem).execute
        end
        compact_database
      end
    end
  end

  private

  def nb_problem_resolved
    @count ||= criteria.count
  end

  def criteria
    @criteria = Problem.resolved
  end

  def compact_database
    collections = Mongoid.default_client.collections
    collections.map(&:name).map do |collection|
      Mongoid.default_client.command compact: collection
    rescue Mongo::Error::OperationFailure => e
      next if /CMD_NOT_ALLOWED: compact/.match?(e.message)

      raise e
    end
  end
end
