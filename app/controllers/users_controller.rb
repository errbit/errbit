class UsersController < ApplicationController
  respond_to :html
  
  before_filter :authenticate_admin!
  
  def index
    @users = User.paginate(:page => params[:page])
  end
  
  def show
    @user = User.find(params[:id])
  end
  
  def new
  end
  
  def edit
  end
  
  def create
  end
  
  def update
  end
  
  def destroy
  end
  
end
