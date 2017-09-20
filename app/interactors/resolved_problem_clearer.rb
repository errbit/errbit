require 'problem_destroy'

class ResolvedProblemClearer
  ##
  # Clear all problem already resolved
  #
  def execute
    puts "#{nb_problem_resolved} resolved problems to remove"
    nb_problem_resolved.tap do |nb|
      if nb > 0
        criteria.each do |problem|
          print "#{criteria.count.to_s.rjust(4)} remains\r"
          ProblemDestroy.new(problem).execute
        end
        puts "Done...   now repairing database"
        repair_database
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

  def repair_database
    Mongoid.default_client.command repairDatabase: 1
  end
end
