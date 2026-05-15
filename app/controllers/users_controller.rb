# frozen_string_literal: true

class UsersController < ApplicationController
  def index
    @users = policy_scope(Errbit::User)
      .order(name: :asc)
      .page(params[:page])
      .per(current_user.per_page)
  end

  def show
    @user = Errbit::User.find(params.expect(:id))

    authorize @user
  end

  def new
    @user = Errbit::User.new

    authorize @user
  end

  def edit
    @user = Errbit::User.find(params.expect(:id))

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
    @user = Errbit::User.find(params.expect(:id))

    authorize @user

    if @user.update(permitted_attributes(@user))
      flash[:success] = t(".success", name: @user.name)

      redirect_to user_path(@user)
    else
      render :edit
    end
  end

  def destroy
    @user = Errbit::User.find(params.expect(:id))

    if same_as_current_user?(@user)
      flash[:error] = t(".error")
    else
      authorize @user

      Errbit::UserDestroy.new(@user).destroy

      flash[:success] = t(".success", name: @user.name)
    end

    redirect_to users_path
  end

  private

  # During the Mongo→SQL port, current_user may still be a Mongoid User while
  # the resource is an Errbit::User. They identify the same person when their
  # bson_id links match.
  def same_as_current_user?(user)
    if current_user.is_a?(Errbit::User)
      user.id == current_user.id
    else
      user.bson_id.present? && user.bson_id == current_user.id.to_s
    end
  end
end
