# frozen_string_literal: true

class CommentsController < ApplicationController
  helper_method :app, :problem, :comment

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

    redirect_to app_problem_path(app, problem)
  end

  private

  def app
    @app ||= App.find(params[:app_id])
  end

  def problem
    @problem ||= app.problems.find(params[:problem_id])
  end

  def comment
    @comment ||= Comment.new(comment_params)
  end

  def comment_params
    # merge makes a copy, merge! edits in place
    params.require(:comment).permit!.merge!(user_id: current_user.id)
  end
end
