# frozen_string_literal: true

class CommentsController < ApplicationController
  expose :app
  expose :problem
  expose :comment

  def create
    problem.comments << comment

    if problem.save
      flash[:success] = I18n.t("comments.create.success")
    else
      flash[:error] = I18n.t("comments.create.error")
    end
    redirect_to app_problem_path(app, problem)
  end

  def destroy
    if comment.destroy
      flash[:success] = I18n.t("comments.destroy.success")
    else
      flash[:error] = I18n.t("comments.destroy.error")
    end

    redirect_to app_problem_path(app, problem), status: :see_other
  end

  private

  def comment_params
    # merge makes a copy, merge! edits in place
    params.require(:comment).permit!.merge!(user_id: current_user.id)
  end
end
