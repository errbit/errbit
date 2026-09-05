# frozen_string_literal: true

class NoticesController < ApplicationController
  def show_by_id
    notice = Notice.find(params.expect(:id))
    problem = notice.problem
    redirect_to app_problem_path(problem.app, problem, notice_id: notice.id)
  end
end
