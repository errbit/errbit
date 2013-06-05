class UserDestroy
  def initialize(user)
    @user = user
  end

  def destroy
    @user.destroy
    @user.watchers.each(&:destroy)
  end

end
