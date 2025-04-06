# frozen_string_literal: true

class UserDestroy
  # @param user [User] User to destroy
  def initialize(user)
    @user = user
  end

  def destroy
    App.watched_by(@user).each do |app|
      watcher = app.watchers.where(user_id: @user.id).first
      app.watchers.delete(watcher)
    end

    @user.destroy
  end
end
