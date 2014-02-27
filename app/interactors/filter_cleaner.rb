require 'problem_destroy'

class FilteredProblemClearer

  ##
  # Clear all problem already resolved
  #
  def execute(args)
    puts("Errors returned by the Query:")
    nb_problem_matching(args['query'], args['limit'].to_i).tap { |nb|
      if nb > 0
        criteria(args['query'], args['limit'].to_i).each do |problem|
          puts(problem.printable)
          if (args["dry"]) != "true"
            puts("Destroying problem")
            ProblemDestroy.new(problem).execute
          end
        end
        repair_database
      end
    }
  end

  private

  def nb_problem_matching(query, limit)
    matches = criteria(query, limit).count
    if matches > limit
      matches = limit
    end
    @count ||= matches
  end

  def criteria(query, limit)
    @criteria ||= Problem.matching(query).limit(limit)
  end

  def repair_database
    Mongoid.default_session.command :repairDatabase => 1
  end
end
