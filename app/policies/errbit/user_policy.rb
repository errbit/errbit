# frozen_string_literal: true

module Errbit
  class UserPolicy < ApplicationPolicy
    FIELDS = [
      :name, :username, :email, :password, :github_login, :per_page, :time_zone,
      :password, :password_confirmation
    ].freeze

    # @param user [Errbit::User] The user making the request
    # @param record [Errbit::User] The record being accessed
    def initialize(user, record)
      super
    end

    def index?
      false
    end
  end
end
