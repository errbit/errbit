class ProblemPresenter
  
  def initialize(controller, problems)
    @controller = controller
    @problems = problems
  end
  
  attr_reader :problems
  
  def as_json(options={})
    @err_ids_by_problem = pluck(
        Err.where(problem_id: problems.map(&:id)),
        :problem_id, :id)
      .each_with_object({}) { |(problem_id, err_id), map|
        (map[problem_id.to_i] ||= []).push(err_id.to_i) }
    problems.map(&method(:problem_as_json))
  end
  
  def problem_as_json(problem)
    { id: problem.id,
      err_ids: @err_ids_by_problem.fetch(problem.id, {}),
      app_id: problem.app_id,
      app_name: problem.app_name,
      environment: problem.environment,
      first_notice_at: problem.first_notice_at,
      first_notice_commit: problem.first_notice_commit,
      first_notice_environment: problem.first_notice_environment,
      last_notice_at: problem.last_notice_at,
      last_notice_commit: problem.last_notice_commit,
      last_notice_environment: problem.last_notice_environment,
      message: problem.message,
      notices_count: problem.notices_count,
      resolved: problem.resolved?,
      resolved_at: problem.resolved_at,
      where: problem.where,
      url: controller.app_problem_url(problem.app, problem) }
  end
  
  def to_json(options={})
    MultiJson.dump(as_json)
  end
  
private
  
  attr_reader :controller
  
  def pluck(relation, *args)
    ActiveRecord::Base.connection.select_rows(relation.select(args).to_sql)
  end
  
end
