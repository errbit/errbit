class UsersController < ApplicationController
  respond_to :html

  before_filter :require_admin!, :except => [:edit, :update]
  before_filter :require_user_edit_priviledges, :only => [:edit, :update]

  expose(:user) {
    params[:id] ? User.find(params[:id]) : User.new(user_params)
  }
  expose(:users) {
    User.all.page(params[:page]).per(current_user.per_page)
  }

  def index; end
  def new; end
  def show; end

  def create
    if user.save
      flash[:success] = "#{user.name} is now part of the team. Be sure to add them as a project watcher."
      redirect_to user_path(user)
    else
      render :new
    end
  end

  def update
    # Devise Hack
    # if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
    #   params[:user].delete(:password)
    #   params[:user].delete(:password_confirmation)
    # end

    if user.update_attributes(user_params)
      flash[:success] = "#{user.name}'s information was successfully updated"
      redirect_to user_path(user)
    else
      render :edit
    end
  end

  def destroy
    if user == current_user
      flash[:error] = I18n.t('controllers.users.flash.destroy.error')
    else
      UserDestroy.new(user).destroy
      flash[:success] = "That's sad. #{user.name} is no longer part of your team."
    end
    redirect_to users_path
  end

  def unlink_github
    user.update_attributes :github_login => nil, :github_oauth_token => nil
    redirect_to user_path(user)
  end

  protected

    def require_user_edit_priviledges
      can_edit = current_user == user || current_user.admin?
      redirect_to(root_path) and return(false) unless can_edit
    end

  def user_params
    params[:user] ? params.require(:user).permit(*user_permit_params) : {}
  end

  def user_permit_params
    @user_permit_params ||= [:name, :username, :email, :github_login, :per_page, :time_zone, :password, :password_confirmation]
    @user_permit_params << :admin if current_user.admin?
    @user_permit_params
  end

end

