# frozen_string_literal: true

class UsersController < ApplicationController
  layout "new_application"

  def index
    @users = policy_scope(User)
      .order_by(name: :asc)
      .page(params[:page])
      .per(current_user.per_page)
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
    @user = User.new(permitted_attributes(User.new))

    authorize @user

    if @user.save
      flash[:success] = t(".success", name: @user.name)

      redirect_to user_path(@user)
    else
      render :new
    end
  end

  def update
    @user = User.find(params[:id])

    authorize @user

    if @user.update(permitted_attributes(@user))
      flash[:success] = t(".success", name: @user.name)

      redirect_to user_path(@user)
    else
      render :edit
    end
  end

  def destroy
    @user = User.find(params[:id])

    if @user == current_user
      flash[:error] = t(".error")
    else
      authorize @user

      UserDestroy.new(@user).destroy

      flash[:success] = t(".success", name: @user.name)
    end

    redirect_to users_path
  end
end
