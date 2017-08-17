require 'problem_destroy'

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
        repair_database
      end
    end
  end

private

  def nb_problem_outdated
    @count ||= criteria.count
  end

  def criteria
    @criteria ||= Problem.where(:last_notice_at.lt => Errbit::Config.errbit_problem_destroy_after_days.to_f.days.ago)
  end

  def repair_database
    Mongoid.default_client.command repairDatabase: 1
  end
end
