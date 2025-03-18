# frozen_string_literal: true

class Api::V1::NoticesController < ApplicationController
  respond_to :json, :xml

  def index
    query = {}
    fields = ["created_at", "message", "error_class"]

    if params.key?(:start_date) && params.key?(:end_date)
      start_date = Time.zone.parse(params[:start_date]).utc
      end_date = Time.zone.parse(params[:end_date]).utc
      query = {created_at: {"$lte" => end_date, "$gte" => start_date}}
    end

    results = benchmark("[api/v1/notices_controller] query time") do
      Notice.where(query).only(fields).to_a
    end

    respond_to do |format|
      format.any(:html, :json) { render json: JSON.dump(results) } # render JSON if no extension specified on path
      format.xml { render xml: results }
    end
  end
end
