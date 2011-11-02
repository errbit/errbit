class UsersController < ApplicationController
  respond_to :html

  before_filter :require_admin!, :except => [:edit, :update]
  before_filter :find_user, :only => [:show, :edit, :update, :destroy]
  before_filter :require_user_edit_priviledges, :only => [:edit, :update]

  def index
    @users = User.all.page(params[:page]).per(current_user.per_page)
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    @user = User.new(params[:user])

    # Set protected attributes
    @user.admin = params[:user].try(:[], :admin) if current_user.admin?

    if @user.save
      flash[:success] = "#{@user.name} is now part of the team. Be sure to add them as a project watcher."
      redirect_to user_path(@user)
    else
      render :new
    end
  end

  def update
    # Devise Hack
    if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    # Set protected attributes
    @user.admin = params[:user][:admin] if current_user.admin?

    if @user.update_attributes(params[:user])
      flash[:success] = "#{@user.name}'s information was successfully updated"
      redirect_to user_path(@user)
    else
      render :edit
    end
  end

  def destroy
    @user.destroy

    flash[:success] = "That's sad. #{@user.name} is no longer part of your team."
    redirect_to users_path
  end

  protected

    def find_user
      @user = User.find(params[:id])
    end

    def require_user_edit_priviledges
      can_edit = current_user == @user || current_user.admin?
      redirect_to(root_path) and return(false) unless can_edit
    end

end

