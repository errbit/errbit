# frozen_string_literal: true

class NoticesController < ApplicationController
  # Redirects a notice to its problem page.
  def locate
    problem = Notice.find(params.expect(:id)).problem
    redirect_to app_problem_path(problem.app, problem)
  end

  def show_by_id
    notice = Notice.find(params.expect(:id))
    problem = notice.problem
    redirect_to app_problem_path(problem.app, problem, notice_id: notice.id)
  end
end
