# frozen_string_literal: true

class UserDestroy
  attr_reader :user

  # @param user [Errbit::User] User to destroy
  def initialize(user)
    @user = user
  end

  def destroy
    App.watched_by(user).each do |app|
      watcher = app.watchers.where(user: user).first

      app.watchers.delete(watcher)
    end

    user.destroy!
  end
end
