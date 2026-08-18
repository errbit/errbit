# frozen_string_literal: true

class CommentsController < ApplicationController
  def create
    problem = Errbit::Problem.find(params.expect(:problem_id))
    comment = problem.comments.build(comment_params)

    if comment.save
      flash[:success] = I18n.t("comments.create.success")
    else
      flash[:error] = I18n.t("comments.create.error")
    end

    redirect_to app_problem_path(problem.app, problem)
  end

  def destroy
    comment = Errbit::Comment.find(params.expect(:id))
    problem = comment.err

    if comment.destroy
      flash[:success] = I18n.t("comments.destroy.success")
    else
      flash[:error] = I18n.t("comments.destroy.error")
    end

    redirect_to app_problem_path(problem.app, problem)
  end

  private

  def comment_params
    params.require(:comment).permit(:body).merge(errbit_user_id: current_user.id)
  end
end
