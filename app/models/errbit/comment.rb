# frozen_string_literal: true

module Errbit
  class Comment < ApplicationRecord
    belongs_to :err,
      class_name: "Errbit::Problem",
      foreign_key: :errbit_problem_id,
      inverse_of: :comments,
      counter_cache: :comments_count

    belongs_to :user,
      class_name: "Errbit::User",
      foreign_key: :errbit_user_id,
      inverse_of: :comments

    validates :body, presence: true

    delegate :app, to: :err

    scope :ordered, -> { order(created_at: :asc) }

    after_create :deliver_email, if: :emailable?

    def deliver_email
      Mailer.with(comment: self).comment_notification.deliver_now
    end

    def notification_recipients
      app.notification_recipients - [user.email]
    end

    def emailable?
      app.emailable? && notification_recipients.any?
    end
  end
end
