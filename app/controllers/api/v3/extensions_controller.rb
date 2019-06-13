require 'problem_destroy'

class Api::V3::ExtensionsController < ApplicationController
  FEATURE_DISABLED = 'This feature has been disabled'.freeze

  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  respond_to :json

  def clear_outdated_problems
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Headers'] = 'origin, content-type, accept'

    if Errbit::Config.feature_api_problem_clear_outdated
      if Errbit::Config.notice_deprecation_days.present?
        problems = Problem.where(:created_at.lt => Errbit::Config.notice_deprecation_days.to_f.days.ago)
        problem_count = problems.count
      
        if problem_count > 0 
          problems.each do |problem| 
            Rails.logger.info("Destroying problem #{problem.id}")
            ProblemDestroy.new(problem).execute
          end

          message = "Cleared #{problem_count} outdated problem from the database."
          Rails.logger.info(message)

          render(status: 200, text: message)
        else
          render(status: 200, text: "No problems require clearing from the database.")
        end
      else
        render(status: 403, text: "ERRBIT_PROBLEM_DESTROY_AFTER_DAYS not set. Old problems will not be destroyed.")
      end
    else
      render(status: 403, text: FEATURE_DISABLED)
    end
  end

  def clear_outdated_resolved_problems
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Headers'] = 'origin, content-type, accept'

    if Errbit::Config.feature_api_problem_clear_outdated_resolved
      if Errbit::Config.resolved_problem_destroy_after_days.present?
        problems = Problem.resolved.where(:resolved_at.lte => Errbit::Config.resolved_problem_destroy_after_days.to_f.days.ago)
        problem_count = problems.count
      
        if problem_count > 0 
          problems.each do |problem| 
            Rails.logger.info("Destroying problem #{problem.id}")
            ProblemDestroy.new(problem).execute
          end

          message = "Cleared #{problem_count} outdated resolved problem from the database."
          Rails.logger.info(message)

          render(status: 200, text: message)
        else
          render(status: 200, text: "No resolved problems require clearing from the database.")
        end
      else
        render(status: 403, text: "ERRBIT_RESOLVED_PROBLEM_DESTROY_AFTER_DAYS not set. Old resolved problems will not be destroyed.")
      end
    else
      render(status: 403, text: FEATURE_DISABLED)
    end
  end

  def clear_outdated_notices
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Headers'] = 'origin, content-type, accept'

    if Errbit::Config.feature_api_notice_clear_outdated
      if Errbit::Config.notice_destroy_after_days.present?
        notices = Notice.where(:created_at.lt => Errbit::Config.notice_destroy_after_days.to_f.days.ago)

        if notices.count > 0
          deleted_count = notices.delete_all

          message = "Cleared #{deleted_count} outdated notices from the database."
          Rails.logger.info(message)
          render(status: 200, text: message)
        else
          render(status: 200, text: "No notices require clearing from the database.")     
        end
      else
        render(status: 403, text: "ERRBIT_NOTICE_DESTROY_AFTER_DAYS not set. Old notices will not be destroyed.")
      end
    else
      render(status: 403, text: FEATURE_DISABLED)
    end
  end
end
