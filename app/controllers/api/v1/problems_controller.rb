# frozen_string_literal: true

module Api
  module V1
    class ProblemsController < ApplicationController
      respond_to :json, :xml

      def index
        scope = Errbit::Problem.all

        if params.key?(:start_date) && params.key?(:end_date)
          start_date = Time.parse(params[:start_date]).utc
          end_date = Time.parse(params[:end_date]).utc
          scope = scope.where("first_notice_at <= ?", end_date)
            .where("resolved_at IS NULL OR resolved_at >= ?", start_date)
        end

        results = benchmark("[api/v1/problems_controller/index] query time") do
          scope.to_a.map { |problem| serialize_problem(problem) }
        end

        respond_to do |format|
          format.any(:html, :json) { render json: results } # render JSON if no extension specified on path
          format.xml { render xml: results }
        end
      end

      def show
        result = benchmark("[api/v1/problems_controller/show] query time") do
          serialize_problem(Errbit::Problem.find(params.expect(:id)))
        rescue ActiveRecord::RecordNotFound
          head :not_found
          return false
        end

        respond_to do |format|
          format.any(:html, :json) { render json: result } # render JSON if no extension specified on path
          format.xml { render xml: result }
        end
      end

      private

      # Preserve the Mongoid-era API contract (keys `_id` and `app_id` are
      # string-typed). Clients depending on this v1 shape keep working after
      # the SQL port.
      def serialize_problem(problem)
        {
          "_id" => problem.id.to_s,
          "app_id" => problem.errbit_app_id.to_s,
          "app_name" => problem.app_name,
          "environment" => problem.environment,
          "message" => problem.message,
          "where" => problem.where,
          "first_notice_at" => problem.first_notice_at,
          "last_notice_at" => problem.last_notice_at,
          "resolved" => problem.resolved,
          "resolved_at" => problem.resolved_at,
          "notices_count" => problem.notices_count
        }
      end
    end
  end
end
