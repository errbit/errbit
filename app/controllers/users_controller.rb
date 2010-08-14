class UsersController < ApplicationController
  respond_to :html
  
  before_filter :require_admin!
  
  def index
    @users = User.paginate(:page => params[:page])
  end
  
  def show
    @user = User.find(params[:id])
  end
  
  def new
    @user = User.new
  end
  
  def edit
    @user = User.find(params[:id])
  end
  
  def create
    @user = User.new(params[:user])
    
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
    
    @user = User.find(params[:id])
    
    if @user.update_attributes(params[:user])
      flash[:success] = "#{@user.name}'s information was successfully updated"
      redirect_to user_path(@user)
    else
      render :edit
    end
  end
  
  def destroy
    @user = User.find(params[:id])
    @user.destroy
    
    flash[:success[ = "That's sad. #{@user.name} is no longer part of your team."
    redirect_to users_path
  end
  
end
