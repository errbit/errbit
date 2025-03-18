# frozen_string_literal: true

require "problem_destroy"

class OutdatedProblemClearer
  ##
  # Clear all problem not present for more than one week.
  #
  def execute
    nb_problem_outdated.tap do |nb|
      if nb > 0
        criteria.each do |problem|
          ProblemDestroy.new(problem).execute
        end
        compact_database
      end
    end
  end

  private

  def nb_problem_outdated
    @count ||= criteria.count
  end

  def criteria
    @criteria ||= Problem.where(:last_notice_at.lt => Errbit::Config.notice_deprecation_days.to_f.days.ago)
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
