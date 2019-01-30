require_dependency 'badges/base'
require_dependency 'badges/last_error'
require_dependency 'badges/recent_errors'

class BadgesController < ApplicationController
  expose(:app)

  skip_before_action :authenticate_user!, only: :show, if: :badges_public?

  def index
    @badges = Badges::Base.descendants
  end

  def show
    badge_class = Badges::Base.find_badge_for_key(params[:badge_type])
    if badge_class
      @badge = badge_class.new(app)
    else
      head :not_found
    end
  end

private

  def badges_public?
    Errbit::Config.badge_public
  end

  helper_method :badges_public?
end
