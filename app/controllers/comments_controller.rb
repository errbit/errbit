# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :set_app
  before_action :set_problem
  before_action :set_comment, only: [:destroy]

  def create
    @comment = Comment.new(comment_params)
    @problem.comments << @comment

    if @problem.save
      flash[:success] = I18n.t("comments.create.success")
    else
      flash[:error] = I18n.t("comments.create.error")
    end
    redirect_to app_problem_path(@app, @problem)
  end

  def destroy
    if @comment.destroy
      flash[:success] = I18n.t("comments.destroy.success")
    else
      flash[:error] = I18n.t("comments.destroy.error")
    end

    redirect_to app_problem_path(@app, @problem)
  end

  private

  def set_app
    @app = App.find(params[:app_id])
  end

  def set_problem
    @problem = @app.problems.find(params[:problem_id])
  end

  def set_comment
    @comment = @problem.comments.find(params[:id])
  end

  def comment_params
    # merge makes a copy, merge! edits in place
    params.require(:comment).permit!.merge!(user_id: current_user.id)
  end
end
