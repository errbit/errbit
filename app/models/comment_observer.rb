class CommentObserver < Mongoid::Observer
  observe :comment

  def after_create(comment)
    Mailer.comment_notification(comment).deliver if comment.emailable?
  end

end
