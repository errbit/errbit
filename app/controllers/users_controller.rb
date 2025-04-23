# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :require_admin!, except: [:edit, :update]
  before_action :require_user_edit_privileges, only: [:edit, :update]

  def index
    @users = apply_scope(User).order_by(name: :asc).page(params[:page]).per(current_user.per_page)
  end

  def show
    @user = User.find(params[:id])

    authorize @user
  end

  def new
    @user = User.new

    authorize @user
  end

  def edit
    @user = User.find(params[:id])

    authorize @user
  end

  def create
    if user.save
      flash[:success] = "#{user.name} is now part of the team. Be sure to add them as a project watcher."

      redirect_to user_path(user)
    else
      render :new
    end
  end

  def update
    if user.update(user_params)
      flash[:success] = I18n.t("controllers.users.flash.update.success", name: user.name)

      redirect_to user_path(user)
    else
      render :edit
    end
  end

  def destroy
    if user == current_user
      flash[:error] = I18n.t("controllers.users.flash.destroy.error")
    else
      UserDestroy.new(user).destroy
      flash[:success] = I18n.t("controllers.users.flash.destroy.success", name: user.name)
    end
    redirect_to users_path
  end

  def unlink_github
    user.update(github_login: nil, github_oauth_token: nil)

    redirect_to user_path(user)
  end

  def unlink_google
    user.update(google_uid: nil)

    redirect_to user_path(user)
  end

  private

  def require_user_edit_privileges
    can_edit = current_user == user || current_user.admin?
    redirect_to(root_path) unless can_edit
  end

  def user_params
    @user_params ||= params[:user] ? params.require(:user).permit(*user_permit_params) : {}
  end

  def user_permit_params
    @user_permit_params ||= [:name, :username, :email, :github_login, :per_page, :time_zone]
    @user_permit_params << :admin if current_user.admin? && current_user.id != params[:id]
    @user_permit_params |= [:password, :password_confirmation] if user_password_params.values.all?(&:present?)
    @user_permit_params
  end

  def user_password_params
    @user_password_params ||= params[:user] ? params.require(:user).permit(:password, :password_confirmation) : {}
  end
end
