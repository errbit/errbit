class ProblemPresenter
  
  def initialize(controller, problems)
    @controller = controller
    @problems = problems
  end
  
  attr_reader :problems
  
  def as_json(options={})
    problems.map do |problem|
      { id: problem.id,
        app_id: problem.app_id,
        app_name: problem.app_name,
        environment: problem.environment,
        first_notice_at: problem.first_notice_at,
        first_notice_commit: problem.first_notice_commit,
        last_notice_at: problem.last_notice_at,
        last_notice_commit: problem.last_notice_commit,
        message: problem.message,
        notices_count: problem.notices_count,
        resolved: problem.resolved?,
        resolved_at: problem.resolved_at,
        where: problem.where,
        url: controller.app_problem_url(problem.app, problem) }
    end
  end
  
  def to_json(options={})
    MultiJson.dump(as_json)
  end
  
private
  
  attr_reader :controller
  
end
