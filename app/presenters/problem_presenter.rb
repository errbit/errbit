class ProblemPresenter
  attr_reader :problems, :problem_ids
  
  def initialize(controller, problems)
    @controller = controller
    @problems = problems
  end
  
  def as_json(options={})
    problem_attrs = pluck(problems,
      :id,
      :app_id,
      :app_name,
      :environment,
      :message,
      "problems.\"where\"",
      :first_notice_at,
      :first_notice_commit,
      :first_notice_environment,
      :last_notice_at,
      :last_notice_commit,
      :last_notice_environment,
      :resolved,
      :resolved_at,
      :notices_count)
    
    @problem_ids = problem_attrs.map(&:first)
    
    problem_attrs.map { |id, app_id, app_name, environment, message, where,
        first_notice_at, first_notice_commit, first_notice_environment,
        last_notice_at, last_notice_commit, last_notice_environment,
        resolved, resolved_at, notices_count|
      err_ids = err_ids_by_problem.fetch(id.to_i, [])
    { id: id.to_i,
      err_ids: err_ids,
      app_id: app_id.to_i,
      app_name: app_name,
      environment: environment,
      first_notice_at: first_notice_at && Time.zone.parse(first_notice_at),
      first_notice_commit: first_notice_commit,
      first_notice_environment: first_notice_environment,
      last_notice_at: last_notice_at && Time.zone.parse(last_notice_at),
      last_notice_commit: last_notice_commit,
      last_notice_environment: last_notice_environment,
      message: message,
      notices_count: notices_count.to_i,
      resolved: resolved == "t",
      resolved_at: resolved_at && Time.zone.parse(resolved_at),
      where: where,
      url: err_ids.any? && controller.app_err_url(app_id: app_id, id: err_ids.first)
    } }
  end
  
  def problem_as_json(problem)
    { id: problem.id,
      err_ids: err_ids_by_problem.fetch(problem.id, {}),
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
    puts "engine: #{MultiJson.engine}"
    MultiJson.dump(as_json)
  end
  
private
  
  def problem_ids
    @problem_ids ||= problems.map(&:id)
  end
  
  def err_ids_by_problem
    @err_ids_by_problem ||= pluck(
        Err.where(problem_id: problem_ids),
        :problem_id, :id)
      .each_with_object({}) { |(problem_id, err_id), map|
        (map[problem_id.to_i] ||= []).push(err_id.to_i) }
  end
  
  attr_reader :controller
  
  def pluck(relation, *args)
    ActiveRecord::Base.connection.select_rows(relation.select(args).to_sql)
  end
  
end
