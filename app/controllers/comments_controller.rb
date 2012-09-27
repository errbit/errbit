class CommentsController < ApplicationController
  before_filter :find_app
  before_filter :find_problem

  def create
    @comment = Comment.new(params[:comment].merge(:user_id => current_user.id))
    if @comment.valid?
      @problem.comments << @comment
      @problem.save
      flash[:success] = "Comment saved!"
    else
      flash[:error] = "I'm sorry, your comment was blank! Try again?"
    end
    redirect_to app_problem_path(@app, @problem)
  end

  def destroy
    @comment = Comment.find(params[:id])
    if @comment.destroy
      flash[:success] = "Comment deleted!"
    else
      flash[:error] = "Sorry, I couldn't delete your comment for some reason. I hope you don't have any sensitive information in there!"
    end
    redirect_to app_problem_path(@app, @problem)
  end

  protected
    def find_app
      @app = App.find(params[:app_id])

      # Mongoid Bug: could not chain: current_user.apps.find_by_id!
      # apparently finding by 'watchers.email' and 'id' is broken
      raise(Mongoid::Errors::DocumentNotFound.new(App,@app.id)) unless current_user.admin? || current_user.watching?(@app)
    end

    def find_problem
      @problem = @app.problems.find(params[:problem_id])
    end
end

