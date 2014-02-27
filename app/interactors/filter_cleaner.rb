require 'problem_destroy'

class FilteredProblemClearer

  ##
  # Clear all problem already resolved
  #
  def execute(args)
    nb_problem_matching(args['query'], args['limit']).tap { |nb|
      if nb > 0
        criteria(args['query'], args['limit']).each do |problem|
          print(problem.message)
          if (args["dry"])
            ProblemDestroy.new(problem).execute
          end
        end
        repair_database
      end
    }
  end

  private

  def nb_problem_matching(query, limit)
    @count ||= criteria(query, limit).count
  end

  def criteria(query, limit)
    @criteria ||= Problem.matching(query).limit(limit)
  end

  def repair_database
    Mongoid.default_session.command :repairDatabase => 1
  end
end
