class ServicesNotificationJob < SidekiqJob

  def perform(problem_id)
    problem = Problem.find(problem_id)
    problem.app.notification_service.create_notification(problem)
  end
end
