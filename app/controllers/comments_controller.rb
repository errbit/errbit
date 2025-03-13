class CommentsController < ApplicationController
  expose :app
  expose :problem
  expose :comment

  def create
    problem.comments << comment

    if problem.save
      flash[:success] = "Comment saved!"
    else
      flash[:error] = "I'm sorry, your comment was blank! Try again?"
    end
    redirect_to app_problem_path(app, problem)
  end

  def destroy
    if comment.destroy
      flash[:success] = "Comment deleted!"
    else
      flash[:error] = "Sorry, I couldn't delete your comment for some reason. I hope you don't have any sensitive information in there!"
    end
    redirect_to app_problem_path(app, problem)
  end

  private

  def comment_params
    # merge makes a copy, merge! edits in place
    params.require(:comment).permit!.merge!(user_id: current_user.id)
  end
end
