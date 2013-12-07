class ProblemDestroy

  attr_reader :problem

  def initialize(problem)
    @problem = problem
  end

  def execute
    delete_errs
    delete_comments
    problem.delete
  end

  ##
  # Destroy all problem pass in args
  #
  # @params [ Array[Problem] ] problems the list of problem need to be delete
  #   can be a single Problem
  # @return [ Integer ]
  #   the number of problem destroy
  #
  def self.execute(problems)
    Array(problems).each{ |problem|
      ProblemDestroy.new(problem).execute
    }.count
  end

  private

  def errs_id
    @errs_id ||= problem.errs.pluck(:id)
  end

  def comments_id
    @comments_id ||= problem.comments.pluck(:id)
  end

  def delete_errs
    Notice.delete_all(err_id: errs_id)
    Err.delete_all(id: errs_id)
  end

  def delete_comments
    Comment.delete_all(id: comments_id)
  end

end
