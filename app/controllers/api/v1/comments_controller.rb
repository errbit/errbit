# frozen_string_literal: true

module Api
  module V1
    class CommentsController < ApplicationController
      skip_before_action :verify_authenticity_token
      skip_before_action :authenticate_user!

      respond_to :json, :xml
      FIELDS = ["_id", "err_id", "user_id", "body"]

      def index
        results = benchmark("[api/v1/comments_controller/index] query time") do
          Comment.where(err_id: params[:problem_id]).only(FIELDS).to_a
        end

        respond_to do |format|
          format.any(:html, :json) { render json: results }
          format.xml { render xml: results }
        end
      end

      def create
        comment = Comment.new(comment_params)

        if comment.save
          render status: :created, json: comment
        else
          render(
            body: {errors: comment.errors.full_messages}.to_json,
            status: :unprocessable_entity
          )
        end
      end

      private

      def comment_params
        # merge makes a copy, merge! edits in place
        params.require(:comment).permit(:body).merge!(user_id: current_user.id, err_id: params[:problem_id])
      end
    end
  end
end
