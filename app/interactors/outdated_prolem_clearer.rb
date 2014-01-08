require 'problem_destroy'

class OutdatedProblemClearer

  ##
  # Clear all problem not present for more than one week.
  #
  def execute
    nb_problem_outdated.tap { |nb|
      if nb > 0
        criteria.each do |problem|
          ProblemDestroy.new(problem).execute
        end
        repair_database
      end
    }
  end

  private

  def nb_problem_outdated
    @count ||= criteria.count
  end

  def criteria
    @criteria = (Time.new - Problem.last_notice_at) / 3600 / 24 > 7
  end

  def repair_database
    Mongoid.default_session.command :repairDatabase => 1
  end
end
