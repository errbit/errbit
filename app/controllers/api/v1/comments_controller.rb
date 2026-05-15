# frozen_string_literal: true

module Api
  module V1
    class CommentsController < ApplicationController
      skip_before_action :verify_authenticity_token
      skip_before_action :authenticate_user!

      respond_to :json, :xml

      def index
        results = benchmark("[api/v1/comments_controller/index] query time") do
          Errbit::Comment.where(errbit_problem_id: params[:problem_id])
            .to_a
            .map { |comment| serialize_comment(comment) }
        end

        respond_to do |format|
          format.any(:html, :json) { render json: results }
          format.xml { render xml: results }
        end
      end

      def create
        comment = Errbit::Comment.new(comment_params)

        if comment.save
          render status: :created, json: serialize_comment(comment)
        else
          render(
            body: {errors: comment.errors.full_messages}.to_json,
            status: :unprocessable_content
          )
        end
      end

      private

      def comment_params
        params.require(:comment).permit(:body).merge(
          errbit_user_id: current_user.id,
          errbit_problem_id: params[:problem_id]
        )
      end

      # Preserve the Mongoid-era API contract: keys `_id`, `err_id`, `user_id`.
      def serialize_comment(comment)
        {
          "_id" => comment.id.to_s,
          "err_id" => comment.errbit_problem_id.to_s,
          "user_id" => comment.errbit_user_id.to_s,
          "body" => comment.body
        }
      end
    end
  end
end
