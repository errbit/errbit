# frozen_string_literal: true

module Api
  module V1
    class NoticesController < ApplicationController
      respond_to :json, :xml

      def index
        scope = Errbit::Notice.all

        if params.key?(:start_date) && params.key?(:end_date)
          start_date = Time.zone.parse(params[:start_date]).utc
          end_date = Time.zone.parse(params[:end_date]).utc
          scope = scope.where(created_at: start_date..end_date)
        end

        results = benchmark("[api/v1/notices_controller] query time") do
          scope.to_a.map { |notice| serialize_notice(notice) }
        end

        respond_to do |format|
          format.any(:html, :json) { render json: results } # render JSON if no extension specified on path
          format.xml { render xml: results }
        end
      end

      private

      # Preserve the Mongoid-era API contract: key `_id` (string).
      def serialize_notice(notice)
        {
          "_id" => notice.id.to_s,
          "created_at" => notice.created_at,
          "message" => notice.message,
          "error_class" => notice.error_class
        }
      end
    end
  end
end
