class FiltersController < ApplicationController
  before_filter :require_admin!
  respond_to :html

  expose(:filter, :attributes => :filter_params)
  expose(:filters) { Filter.all }
  expose(:apps) { App.all.sort }

  def create
    if filter.save
      flash[:success] = t('controllers.filters.flash.create.success')
      redirect_to filter
    else
      render :new
    end
  end

  def update
    if filter.update_attributes filter_params
      flash[:success] = t('controllers.filters.flash.update.success')
      redirect_to filter
    else
      render :edit
    end
  end

  def destroy
    filter.destroy
    flash[:success] = t('controllers.filters.flash.destroy.success')
    redirect_to filters_url
  end

  private
  def filter_params
    params.require(:filter).permit(:message, :url, :error_class, :where,
                                   :description, :app_id)
  end
end
