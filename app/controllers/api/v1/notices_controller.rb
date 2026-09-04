# frozen_string_literal: true

module Api
  module V1
    class NoticesController < ApplicationController
      respond_to :json, :xml

      def index
        results = benchmark("[api/v1/notices_controller] query time") do
          notice_results.to_a
        end

        respond_to do |format|
          format.any(:html, :json) { render json: results } # render JSON if no extension specified on path
          format.xml { render xml: results }
        end
      end

      private

      def notice_results
        notices_query(
          date_query,
          ["created_at", "message", "error_class"],
          parse_positive_integer(params[:page], default: 1),
          [parse_positive_integer(params[:per_page], default: 100), 100].min
        )
      end

      def date_query
        return {} unless params.key?(:start_date) && params.key?(:end_date)

        start_date = parse_date(params[:start_date])
        end_date = parse_date(params[:end_date])
        return {} unless start_date && end_date

        {created_at: {"$lte" => end_date, "$gte" => start_date}}
      end

      def notices_query(query, fields, page, per_page)
        Notice.where(query)
          .only(fields)
          .order_by(created_at: :asc, _id: :asc)
          .page(page)
          .per(per_page)
      end

      def parse_positive_integer(value, default:)
        return default unless value.is_a?(String) || value.is_a?(Integer)
        return default unless value.to_s.match?(/\A\d+\z/)

        parsed_value = value.to_i
        parsed_value.positive? ? parsed_value : default
      end

      def parse_date(value)
        return unless value.is_a?(String) && value.present?

        Time.zone.parse(value).presence
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end
