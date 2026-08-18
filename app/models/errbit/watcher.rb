# frozen_string_literal: true

module Errbit
  class Watcher < ApplicationRecord
    belongs_to :app,
      class_name: "Errbit::App",
      foreign_key: :errbit_app_id,
      inverse_of: :watchers

    belongs_to :user,
      class_name: "Errbit::User",
      foreign_key: :errbit_user_id,
      optional: true

    validate :ensure_user_or_email

    before_validation :clear_unused_watcher_type

    attr_accessor :_watcher_type

    def watcher_type
      @_watcher_type ||= email.present? ? "email" : "user"
    end

    def watcher_type=(value)
      @_watcher_type = value
    end

    def label
      user ? user.name : email
    end

    def address
      user&.email || email
    end

    def email_choosen
      email.blank? ? "chosen" : ""
    end

    private

    def ensure_user_or_email
      return if user.present? || email.present?

      errors.add(:base, "You must specify either a user or an email address")
    end

    def clear_unused_watcher_type
      case watcher_type
      when "user"
        self.email = nil
      when "email"
        self.user = nil
        self.errbit_user_id = nil
      end
    end
  end
end
