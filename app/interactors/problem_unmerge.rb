class ProblemUnmerge
  attr_reader :problem

  delegate :errs, :app, to: :problem

  def initialize(problem)
    @problem = problem
  end

  def execute
    Problem.transaction do
      attrs = {error_class: problem.error_class, environment: problem.environment}
      problem_errs = errs.to_a
      problem_errs.shift # one of the Errs will be retained by this problem
      ([problem] + problem_errs.map(&:id).map do |err_id|
        err = Err.find(err_id)
        app.problems.create(attrs).tap do |new_problem|
          err.update_attribute(:problem_id, new_problem.id)
        end
      end).each(&method(:reset_cached_attributes))
    end
  end

  ##
  # Unmerges all problem pass in args
  #
  # @params [ Array[Problem] ] problems the list of problem need to be delete
  #   can be a single Problem
  # @return [ Array[Problem] ]
  #   the problems that have been unmerged
  #
  def self.execute(problems)
    Array(problems).map { |problem| ProblemUnmerge.new(problem).execute }.flatten
  end

private

  def reset_cached_attributes(problem)
    ProblemUpdaterCache.new(problem).update
  end

end
