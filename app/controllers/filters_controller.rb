class FiltersController < ApplicationController
  before_filter :require_admin!
  respond_to :html

  expose(:filter, attributes: :filter_params)
  expose(:filters) { Filter.all }
  expose(:apps) { App.all.sort }

  def create
    if filter.save
      redirect_to filter, success: t('controllers.filters.flash.create.success')
    else
      render :new
    end
  end

  def update
    if filter.update_attributes filter_params
      redirect_to filter, success: t('controllers.filters.flash.update.success')
    else
      render :edit
    end
  end

  def destroy
    filter.destroy
    redirect_to filters_url, success: t('controllers.filters.flash.destroy.success')
  end

  private

  def filter_params
    params.require(:filter).permit(:message, :url, :error_class, :where,
                                   :description, :app_id)
  end
end
