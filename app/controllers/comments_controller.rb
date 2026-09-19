# frozen_string_literal: true

class CommentsController < ApplicationController
  def create
    @app = App.find(params[:app_id])
    @problem = @app.problems.find(params[:problem_id])
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
    @app = App.find(params[:app_id])
    @problem = @app.problems.find(params[:problem_id])
    @comment = Comment.find(params[:id])

    if @comment.destroy
      flash[:success] = I18n.t("comments.destroy.success")
    else
      flash[:error] = I18n.t("comments.destroy.error")
    end

    redirect_to app_problem_path(@app, @problem)
  end

  private

  def comment_params
    # merge makes a copy, merge! edits in place
    params.require(:comment).permit!.merge!(user_id: current_user.id)
  end
end
