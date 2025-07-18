# frozen_string_literal: true

class UsersController < ApplicationController
  def index
    @users = policy_scope(Errbit::User)
      .order(name: :asc)
      .page(params[:page])
      .per(current_user.per_page)
  end

  def show
    @user = Errbit::User.find(params[:id])

    authorize @user
  end

  def new
    @user = Errbit::User.new

    authorize @user
  end

  def edit
    @user = Errbit::User.find(params[:id])

    authorize @user
  end

  def create
    @user = Errbit::User.new(permitted_attributes(Errbit::User.new))

    authorize @user

    if @user.save
      flash[:success] = t(".success", name: @user.name)

      redirect_to user_path(@user)
    else
      render :new
    end
  end

  def update
    @user = Errbit::User.find(params[:id])

    authorize @user

    if @user.update(permitted_attributes(@user))
      flash[:success] = t(".success", name: @user.name)

      redirect_to user_path(@user)
    else
      render :edit
    end
  end

  def destroy
    @user = Errbit::User.find(params[:id])

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
